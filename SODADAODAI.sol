pragma solidity 0.5.10;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "https://github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "https://github.com/vittominacori/solidity-linked-list/blob/master/contracts/StructuredLinkedList.sol";



contract SODADAODAI is Ownable, ERC20, ERC20Detailed("SODA DAO (DAI)","SODADAI",18){
    event Test(address test);
    using StructuredLinkedList for StructuredLinkedList.List;
    StructuredLinkedList.List holders;
    uint windowCloseTime = now + 1 days;
    
    uint private MIN_LEND = 100 * 10**18;
    function getMinLend() public view returns (uint) { return MIN_LEND;  }
    function setMinLend(uint value) public onlyOwner { MIN_LEND = value; }
    
    modifier withClosedWindow() {
        require(now >= windowCloseTime, "window must be closed");
        _;
    }
    
    modifier withOpenedWindow() {
        require(now < windowCloseTime || now > windowCloseTime + 60 days, "window must be opened");
        _;
    }
    
    IERC20 DAI  = IERC20(address(0x0089d24a6b4ccb1b6faa2625fe562bdd9a23260359));
    Pool internal pool   = new Pool(address(DAI));
    function getPool() view public returns(address) {return address(pool);}
    function getPoolBalance() view public returns (uint) {return DAI.balanceOf(address(pool));}
    
    function _transfer(address,address,uint256) internal {
        revert("token is not transferable");
    }
    
    function lend(uint amount) public withOpenedWindow {
        require(amount >= MIN_LEND, "too small amount");
        if(!holders.nodeExists(uint(msg.sender)))
            holders.push(uint(msg.sender), true);
        DAI.transferFrom(msg.sender, address(pool) ,amount);
        _mint(msg.sender, amount);                  // 70%
        _mint(address(this), amount.mul(3).div(7)); // 30%   
    }
    
    function withdraw(uint amount) public withOpenedWindow {
        _burn(msg.sender, amount);                  // 70%
        _burn(address(this), amount.mul(3).div(7)); // 30%
        pool.send(msg.sender, amount);    
        if(balanceOf(msg.sender) == 0)
            holders.remove(uint(msg.sender));
    }
    
    function distribute(uint windowSize) public onlyOwner withClosedWindow {
        windowCloseTime = now + windowSize * 1 hours;
        uint amount = DAI.balanceOf(address(this));
        require(amount > 0, "there are no funds for distribution");
        uint total = totalSupply();
        uint sum = 0;
        (bool exist, uint current) = holders.getNextNode(0);
        while(current != 0){
            uint b = balanceOf(address(current));
            uint part = amount.mul(b).div(total);
            sum += part;
            DAI.transfer(address(current), part);
            
            (exist, current) = holders.getNextNode(current);
        }
        DAI.transfer(owner(), amount.sub(sum));
    }
}




contract Pool is Ownable {
    
    IERC20 token;
    
    constructor(address tokenAddress) public {
        token = IERC20(tokenAddress);
    }
    
    function send(address to, uint value) public onlyOwner  {
        token.transfer(to, value);
    }
}
