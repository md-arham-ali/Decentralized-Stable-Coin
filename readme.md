1. setup forge 
2. make stablecoin contract
3. make DSC engine
4. installing openzeplin for development


5. functions its parameters and its uses
    1. mint dsc(public)- takes address and amount
        1. checks if the the user adress has enough collateral- which means checking health factor of the user address
        2. throws errors and reverts if the condition is not satisfied
        3. mints the DSC by calling mint function on DSC contract variable
        4. stores how much DSc has been minted by a particular address
    2. get health factor(private)- takes address of the user and returns uint256, the health factor value
        1. gets information of the user- its collateral, and check health factor
        2. calls check health factor function using total collateral value in usd and total dsc minted 
    3. get information(private internal view)- takes user address
        1. returns the total DSC minted and 
        2. Collateral value in usd
        3. utilizes state variables - mapping to get total DSC minted based on the key( the user address)mapping to 
        4. a function to get usd value of the collateral(input user address)
    4. check health factor( private internal view)- takes the DSC minted and collateral value in usd
        1. check if the DSC minted and collateral value is non zero, and reverts if collateral value is zero and max Uint256 if DSC minted is zero
        2. returns a uint256 value of the health factor
    5. get usd value of the collateral(public )- takes token address and the amount of token
        1. utilizes the mapping of picefeed from the token address to feed it into aggregator v3 interface variable
        2. calls check latest round data on the aggregator v3 interface function variable  to get the price of token in usd
        3. this price is presise so refine it to return the usd value of token
    6. revert if the health factor is broken(private)
        1. check if the health factor is below a certain threshold and returns error if it is true
    7. deposit collateral(Private and external both)- takes the token address, the amount of collateral to be deposited and the sender address 
        1. checks if the collateral to be deposired is in the accepted collateral list
        2. changes its state to store the collateral deposited amount to the particular collateral address mapped to particular adress(msg.sender)
    8. redeem collateral-token collateral address, amount of collateral to be redeemed
        1. calls the burn function 
        2. calls the redeem function
        3. check if the health factor is broken after the transfer- reverts the whole transaction- no dsc burned and no collateral redeemed
    9. burn function - takes 3 parameters, the amount of DSC to be burned, the dsc to be burned on behalf of
       and address dsc to be burned from 
        1. ammends the contract varialbe by subtracting the dsc amount to be burned
        2. transfers the amount- for now we are taking the dsc back to the contract
        3. calls the burn function on the orignal DSC contract
        4. checks the health factor after the burn, if not good the whole transaction is reversed
        5. an event function can also be called
    10. redeem function- takes the collateraladdress to be redeemed, the amount to be redeemed
        the from or on behalf of address and to be deposited address
        1. ammends the contract variable by subtracting the collateral amount to be transfered
        2. transfers the amount 
        3. checks the health factor after the amount is transfered and reverts the transactionn if not true
        4. an event function is called 

6. modifiers
    1. is allowed token
    2. is nonzero
7. mappings
    1. total DSC minted with address as key
    2. price feed with token address as key
    3. collateral deposited with key as ( token address with key as user address)
8.

