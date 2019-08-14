SODADAI (transferable ERC-20 token):

This smart contract mints and automatically distributes SODADAI between lenders who have provided DAI ◈ to the credit pool smart contract in order to earn interest on SODA. Also it automatically burns SODADAI after the lender withdraws their DAI ◈ from the credit pool smart contract.

Being a lender on SODA is similar to purchasing shares in a company, and your assets (SODADAO  tokens)  earn  you  weekly  interest depending  on  your  share  of  the  total  assets. SODA uses the pool model for aggregating cryptoassets in one place. There is no need to wait for matchmaking to happen between borrower and lender (P2P). This text focuses on the lending and gives guidance from the lender’s perspective.

Lending Procedure:

In order to earn interest the lender provides their cryptoassets to the credit pool smart contract. Compatible cryptoassets for lending on SODA can be found on the website https://www.soda.network or  in  the  source  code  of  the  lending  pool  smart  contract  on  GitHub:  https://github.com/sodacrypto. Еarly  SODA  versions will support DAI and USDC. 

Lent liquidity is locked up for 60 days.

Anyone  is  able  to  provide  their  funds  to  the  credit  pool  smart  contract  and  start  receiving a share of the DAO's interest. When the lender provides their cryptoassets to the credit pool smart contract, they receive SODADAO tokens that are used for: 1) Setting the lender’s share in the DAO's interest; 2) Distributing the DAO's interest on-chain between lenders.

Thus, SODADAO tokens set the lender’s stake in the credit pool and their equivalent interest share. For example, if the lender has provided 10,000 DAI to the credit pool smart  contract  and  the  total  amount  of  DAI  in  the  credit  pool is  100,000 DAI;  10%  new  SODADAO  tokens  will  be  minted  and  sent  to  the  lender  and  they  will start to receive 10% of the DAO’s interest.

70%  of the DAO’s  interest  is  distributed  between  lenders  respective  to  the capital they have provided. 30% of the DAO’s interest goes into the development fund via the SODA  Foundation. The  interest  is  distributed on  a  weekly basis through smart contracts with public on-chain proofs of transactions for lenders.

To  convert  SODADAO  tokens  back  to  the lender’s  cryptoassets,  the  lender  sends  SODADAO tokens to the credit pool smart contract. Following that, they receive the lent cryptoassets to the same Ethereum-address they used to deposit them. Since the lent liquidity is locked up for 60 days, the conversion can be conducted on the 61st day after receiving SODADAO tokens. Until that, the conversion function is blocked.
