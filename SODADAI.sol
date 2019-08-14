
pragma solidity 0.5.10;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "https://github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "./SODADAODAI.sol";


contract SODADAI is usingOraclize, SODADAODAI {
    using SafeMath for uint;
    using Util for string;
    
    event LoanAproval(
        address account,
        uint depositAmount,
        uint rate,
        uint period,
        uint loanAmount,
        uint startPrice);
    event Liquiation(address account);
    
    
    mapping (bytes32 => address) loanQueries;
    mapping (bytes32 => address) liqudationQueries;
    
    mapping (address => Loan) loans;
    string constant private query = "json(https://api.hitbtc.com/api/2/public/ticker/BTCDAI).last";

    uint private rate = 1e6; // 1%
    function setRate(uint value) public onlyOwner { rate = value; }
    function getRate() public view returns (uint)   { return rate;  }
    
    uint private MAX_DEPOSIT_AMOUNT = 1e7;
    function setMaxDepositAmount(uint value) public onlyOwner { MAX_DEPOSIT_AMOUNT = value; }
    function getMaxDepositAmount() public view returns (uint)   { return MAX_DEPOSIT_AMOUNT;  }
    
    
    modifier oraclized(){
        uint o_price = oraclize_getPrice("URL");
        require(o_price <= msg.value);
        if(o_price != msg.value)
            msg.sender.transfer(msg.value - o_price);
        _;
    }
    
    IERC20 SODABTC = IERC20(address(0x00a666cF11E50C4ed944b8EcC30153E1E0eee7Dc31));
    
    
    
    function getLoan(uint depositAmount, uint32 period) public payable oraclized returns(bytes32 id) {
        require(SODABTC.balanceOf(msg.sender) >= depositAmount, "insufficient funds");
        require(SODABTC.allowance(msg.sender, address(this)) >= depositAmount, "insufficient funds");
        require(30 <= period && period <= 90, "wrong loan period");
        require(1000000 <= depositAmount && depositAmount <= MAX_DEPOSIT_AMOUNT, "wrong loan amount");
        require(loans[msg.sender].state != LoanState.Active , "there are active loan");
        
        id = oraclize_query("URL", query);
        loanQueries[id] = msg.sender;
        
        loans[msg.sender] = Loan(
            LoanState.OraclizePriceWaiting,
            depositAmount,
            period,
            rate,
            now,
            0,
            0
        );
    }
    
    function __callback(bytes32 myid, string memory result) public {
        require(msg.sender == oraclize_cbAddress(), "wrong msg.sender");
        uint price = result.parseUsdPrice();
        
        if (loanQueries[myid] != address(0)){
            _getLoan(loanQueries[myid], price);
            delete loanQueries[myid];
        } else if (liqudationQueries[myid]!= address(0)){
            _liquidateByPrice(loanQueries[myid], price);
            delete liqudationQueries[myid];
        } else revert('unexpected query');
        
    }
    
    function _getLoan(address account, uint price) private {
        Loan storage loan = loans[account];
        require(loan.state != LoanState.Active, "there are active loan");
        
        uint value = loan.depositAmount.mul(price).mul(10**9).div(14);
        
        uint l_rate = loan.depositAmount
                .mul(loan.rate).div(1e6) // rate in percents
                .mul(loan.period).div(30) // rate * period
                .div(140); // %
                
        loan.debt = value;
        loan.startPrice = price;
            
        SODABTC.transferFrom(account, address(this), loan.depositAmount.sub(l_rate));
        SODABTC.transferFrom(account, owner(), l_rate);
        pool.send(account, value);
        
        
        emit LoanAproval(
            account,
            loan.depositAmount,
            loan.rate,
            loan.period,
            value,
            price);
            
        loan.depositAmount -= l_rate;
        loan.state = LoanState.Active;
        
    }
    
    function _liquidateByPrice(address account, uint price) private {
        Loan storage d = loans[account];
        require(d.startPrice.mul(11) > price.mul(14), "loan secured by more than 110%" );
        _liquidate(account);
    }
    
    function repay(uint amount) public {
        Loan storage d = loans[msg.sender];
        if(d.debt > amount){
            DAI.transferFrom(msg.sender, address(pool), amount);
            d.debt -= amount;
        } else {
            DAI.transferFrom(msg.sender, address(pool), d.debt);
            SODABTC.transfer(msg.sender, d.depositAmount);
            delete loans[msg.sender];
        }
    }
    
    function _liquidate(address account) private {
        Loan storage d = loans[account];
        SODABTC.transfer(owner(), d.depositAmount);
        delete loans[account];
        emit Liquiation(account);
    }
    
    function _liquidateByPrice(address account) private oraclized {
        bytes32 id = oraclize_query("URL", query);
        liqudationQueries[id] = account;
    }
    
    function liquidate(address account) public payable {
        Loan storage d = loans[account];
        require(d.state == LoanState.Active, "there is no such loan");
        if(d.startTimeStamp + d.period * 1 days < now)
            _liquidate(account);
        else
            _liquidateByPrice(account);
    }
    
    
    
    enum LoanState {Close, OraclizePriceWaiting, Active}
    struct Loan {
        LoanState state;
        uint depositAmount;
        uint32 period;
        uint rate;
        uint startTimeStamp;
        uint startPrice;
        uint debt;
    }
    function LoanStateOf(address account) public view returns(LoanState){
        return loans[account].state;
    }
    function LoanRateOf(address account) public view returns(uint){
        return loans[account].rate;
    }
    function LoanPeriodOf(address account) public view returns(uint){
        return loans[account].period;
    }
    function LoanDepositOf(address account) public view returns(uint){
        return loans[account].depositAmount;
    }
    function LoanStartPriceOf(address account) public view returns(uint){
        return loans[account].startPrice;
    }
    function LoanStartTimestampOf(address account) public view returns(uint){
        return loans[account].startTimeStamp;
    }
    function LoanDebtOf(address account) public view returns(uint){
        return loans[account].debt;
    }
}



library Util {
    function parseUsdPrice(string memory s) pure public returns (uint result) {
        bytes memory b = bytes(s);
        result = 0;
        uint dotted = 2;
        uint stop = b.length;
        for (uint i = 0; i < stop; i++) {
            if(b[i] == ".") {
                if(b.length - i > 3){
                    stop = i + 3;
                    dotted = 0;
                } else
                    dotted -= b.length - i-1;
            }
            else {
                uint c = uint(uint8(b[i]));
                if (c >= 48 && c <= 57) {
                    result = result * 10 + (c - 48);
                }
            }
        }
        result *= 10 **dotted;
    }
}





