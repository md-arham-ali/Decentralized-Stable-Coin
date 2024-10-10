// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

/////////////NOTE TO ME
///make the price extraction function in a different contract 
// the health factor calculation in a different contract as well

pragma solidity 0.8.19;

import { DSC } from "./DSC.sol";
import { IERC20 } from "@openzepplin/contracts/token/ERC20/IERC20.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DSCEngine {
    ////////////////////
    ////// Errors //////
    ////////////////////
    error DSCEngine_tokenaddressandpricefeedaddressdoesnotMatch();
    error DSCEngine_Healthfactorbroken(uint256 brokenhealthfactor);
    error DSCEngine_Needsmorethanzero();
    error DSCEngine_Tokennotallowed();
    error DSCEngine_CollateralNotDeposited();
    error DSCEngine_mintFailed();
    error DSCEngine_burnNotSuccess();
    error DSCEngine_redeemNotSuccess();
    error DSCEngine_liquidatefailed();


    ////////////////////////
    // State variables ////
    ////////////////////////

    uint256 private constant ADDITIONAL_PRICEFEED_PRESICION = 1e10;
    uint256 private constant PRESICION_CORRECTION = 1e18;
    uint256 private constant LIQUIDATATION_PRESICION = 50;
    uint256 private constant PRESICSION_CORRECTION_LIQ = 100;
    uint256 private constant MIN_HEALTH_FACTOR=1e18;
    uint256 private constant LIQUIDATATION_BONUS = 10;
    uint256 private constant LIQUIDATION_FINE = 5;

    DSC private immutable i_dsc;

    

    address[] private s_collateraltokens;

    // to decide the types of collaterl tokens accepted, store its address, its price feed address, also its price feed address on a particular test chain

    // //modifiers//
    // mapping (address chain => mapping (address token => address pricefed)) private chain_pricefeed;// probable mapping
    mapping (address token => address pricefeed) private s_pricefeed;// stores its price feed address on a particular chain linked to the particular token address
    mapping (address sender => uint256 dscminted) private s_DSCminted;// stores the amount of DSC minted per user
    mapping (address user => mapping ( address tokenaddress => uint256 collateralamount) ) private s_collateralDeposited;



    ////////////////////////
    /////// Events /////////
    ////////////////////////

    event Collateral_deposited(address indexed user, address indexed tokenaddress, uint256 indexed amount);
    event DSC_Burned(address indexed user, uint256 indexed amount);
    event Collateral_Redeemed(address indexed user, address indexed toknaddress,
            uint256 amount, address indexed redeemedby );

    ////////////////////////
    ///// Modifiers ////////
    ////////////////////////

    modifier moreThanZero(uint256 amount) {
        if(amount == 0){
            revert DSCEngine_Needsmorethanzero();
        }
        _;
    }

    modifier isAllowedToken ( address tokenaddress ) {
        if (s_pricefeed[tokenaddress] == address(0)){
            revert DSCEngine_Tokennotallowed();
        }
        _;
    }



    //first listing all the external  functions needed

    // for each function list 1. its parameters 2. what the function returns in text explanation 3. intermediary values needed 4. intermediary function needed    

    // takens in the list of price feeds it has- to be used to determine if the collateral to be deposited is the collateral accepted 
    // takes the token addressses present initially which is the accepted collateral type address
    // takes the address of orignal stable coin contract and stores it into a variable to be used and called as and when neded
    constructor(address[] memory token_address, address[] memory pricefeed_address, address DSC_address) {
        // check for mismatch in input data of token address with their price feed address
        // we dont have any source of the token is matched to its right price feed address, we hace to trust the data source 
        // store the token address and its price feed address in contract storage variable 

        if (token_address.length != pricefeed_address.length){
            revert DSCEngine_tokenaddressandpricefeedaddressdoesnotMatch();
        }
        for (uint256 i=0; i<token_address.length;i++){
            s_collateraltokens.push(token_address[i]);
            s_pricefeed[token_address[i]]=pricefeed_address[i];


        }

        

        i_dsc= DSC(DSC_address);    
        //this is 
    }

    ////////////////////////
    // External Functions //
    ////////////////////////

    //deposit collateral and mint DSC
    //redeem collateral for DSC
    //redeem collateral
    //burn DSC
    //liquidate
    //mint DSC
    //deposit collateral

    /*
    */
    function deposit_collateral_and_mintDSC(address tokenCollateralAddress, uint256 deposit_amount, uint256 minted_amount) external {
        _depositCollateral(tokenCollateralAddress, deposit_amount);
        _mintDSC(msg.sender, minted_amount);
    }

    /*
    */
    function deposit_collateral(address tokenCollateralAddress, uint256 amount) external {
        _depositCollateral(tokenCollateralAddress, amount);
    }

    /*
    */
   function mintDSC(uint256 amount) external {
    _mintDSC(msg.sender, amount);
   }



    /*
    this function is to be called if the address itself wants to burn its dsc and redeem collateral
    */
    function redeem_collateral_forDSC(address tokenCollateralAddress, uint256 amount) external {
        _burnDSC(amount, msg.sender, msg.sender);
        _redeemcollateral(tokenCollateralAddress, amount, msg.sender, msg.sender);
        revertIfHealthFactorIsBroken(msg.sender);
    }

    /* wants to redeem its own collateral
    */
    function redeem_collateral(address tokenCollateralAddress, uint256 amount) external {
        _redeemcollateral(tokenCollateralAddress, amount, msg.sender, msg.sender);
        revertIfHealthFactorIsBroken(msg.sender);
    }
    
    /*
    */
   function get_account_information(address user ) external view returns (uint256 dscminted, uint256 tootal_collateral_value_in_usd) {
    return _getInformation(user);
   }

    /*
    @prams- 
    */
    function liquidate( address collateralused, uint256 debttocover, address onbehalfof) external isAllowedToken(collateralused) {
        uint256 prevhealthfactor = _healthfactor(onbehalfof);

        if(prevhealthfactor > MIN_HEALTH_FACTOR){
            revert DSCEngine_liquidatefailed();
        } 

        uint256 tokenamountdebttocover = _getcollateralvaluefromusd(collateralused, debttocover);
        // giving $10 bonus as well
        // 

        uint256 DSCminted = s_DSCminted[onbehalfof];
        uint256 mindebttocover = _minDSCtocorrectposition(debttocover,DSCminted);
        
        if(mindebttocover < tokenamountdebttocover){
            revert DSCEngine_liquidatefailed();
        }

        uint256 bonuscollateral = (tokenamountdebttocover * LIQUIDATATION_BONUS)/PRESICSION_CORRECTION_LIQ; 
        uint256 liquidationfine = (tokenamountdebttocover * LIQUIDATION_FINE)/PRESICSION_CORRECTION_LIQ;
        // we are imposing a fine for not able to maintain your debt position which is 15%
        // it will be detucted from the user who minted DSC 
        // but there is an error here give it a thought later
        // what if all the debt position is removed
        // and then what if the user forgets its DSC, we will not be able to use the extra collateral
         
        _redeemcollateral(collateralused, tokenamountdebttocover + bonuscollateral, onbehalfof, msg.sender);
        s_collateralDeposited[onbehalfof][collateralused] -=  liquidationfine;
        _burnDSC(debttocover,onbehalfof,msg.sender);

        uint256 endinghealthfactor = _healthfactor(onbehalfof);  

        if(endinghealthfactor < prevhealthfactor){
            revert DSCEngine_liquidatefailed();
        }
        revertIfHealthFactorIsBroken(onbehalfof);


    }

    ////////////////////////
    // Public Functions ////
    ////////////////////////

    

    /*
    @prams- getting the token addres whose value in currency is to be obtained
    @prams- the amount of that token that has been deposited 
    this calls the aggregatorV3 interface which is used to get the latest pricefeed data
    the Aggregator contracts various functions like
    1. decimal
    2. version
    3. getRoundData
    4. latestRoundData

    the round data and latest round data returns 5 cariables
    1. roundId 
    2. answer 
    3.startedAt
    4. updatedAt
    5. answered in Round
    and we require the answer only

    */
   function getcollateralvalueinusd(address token, uint256 amount) public view returns (uint256) {
    AggregatorV3Interface pricefeed = AggregatorV3Interface(s_pricefeed[token]);//it is the variable contract that will get us the price feed
    (,int256 price,,,) = pricefeed.latestRoundData();
    // but there issue whith placing of decimals in the answer so we wil have to first rectify that
    // the returned value will be pricevalueincurrency *1e8
    // and the amount precision is 1e18. also we need the price in precision of 1e18 as well
    return ((uint256(price) * ADDITIONAL_PRICEFEED_PRESICION) * amount)/PRESICION_CORRECTION;
   }

    /*
    */
    function burnDSC(uint256 amount, address on_behalf_of) public {
        _burnDSC(amount, on_behalf_of, msg.sender);
        revertIfHealthFactorIsBroken(on_behalf_of);
    }
    ////////////////////////
    // Private Functions ///
    ////////////////////////

    //redeem collateral
    //burnDSC
    
    //health factor
    //get health factor
    //calculate health factor
    //revert if health factor is broken

    function _getcollateralvaluefromusd (address token, uint256 amount) public view returns (uint256) {
    AggregatorV3Interface pricefeed = AggregatorV3Interface(s_pricefeed[token]);//it is the variable contract that will get us the price feed
    (,int256 price,,,) = pricefeed.latestRoundData();

    return ((amount * PRESICION_CORRECTION)/(uint256(price) * ADDITIONAL_PRICEFEED_PRESICION));
    }

    /*
    @prams amout- the amount to beminted

    */
    function _mintDSC(address user, uint256 amt_to_be_minted) public {
        s_DSCminted[user] +=amt_to_be_minted;
        revertIfHealthFactorIsBroken(user);
        bool success = i_dsc.mint(user, amt_to_be_minted);
        if(!success){
            revert DSCEngine_mintFailed();

        }
    }


    /*
    @prams - takes address of collateral token to be deposited
    @prams- amount of that token to be deposited
    calls the transferfrom function of the provided collateral contract which asks it to transfer the amount of
    collateral to this contract and gives the success of transfer
  
    */
    function _depositCollateral(
    address tokenCollateralAddress,
    uint256 amountCollateral)
    private
    moreThanZero(amountCollateral)
    isAllowedToken(tokenCollateralAddress){
    s_collateralDeposited[msg.sender][tokenCollateralAddress]+=amountCollateral;
    emit Collateral_deposited(msg.sender, tokenCollateralAddress, amountCollateral);
    //event to log the data to blockchain for future query search
    bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
    if(!success){
        revert DSCEngine_CollateralNotDeposited();
    }

    }

    /*
    @prams- the amount of dsc to be burned
    @prams- the address on behalf of which dsc is burned, meaning that this address against whom
    the dsc was minted is getting burned
    @prams - who is paying dsc for burning, either the orignal address who minted or someoneels

    calls the transfer function for taking in the dsc- takes the dsc to this address
    calls the burn function on orignal contract
    */
    function _redeemcollateral(address tokenCollateralAddress,
    uint256 amount,
    address on_behalf_of, address dscfrom)
    private
    isAllowedToken(tokenCollateralAddress)
    moreThanZero(amount) {
            
     s_collateralDeposited[on_behalf_of][tokenCollateralAddress] -= amount;
     emit Collateral_Redeemed(on_behalf_of, tokenCollateralAddress, amount, dscfrom);
     bool success = IERC20(tokenCollateralAddress).transfer(dscfrom, amount);
     //we dont use transfer from function here because the transfer function contains the function that takes deposit from the callaer(this contract) and deposits it to the to address
     if(!success){
        revert DSCEngine_redeemNotSuccess();
     }


    //  revertIfHealthFactorIsBroken(on_behalf_of); 

    }

    /*
    @prams- the amount of dsc to be burned
    @prams- the address on behalf of which dsc is burned, meaning that this address against whom
    the dsc was minted is getting burned
    @prams - who is paying dsc for burning, either the orignal address who minted or someoneels

    calls the transfer function for taking in the dsc- takes the dsc to this address
    calls the burn function on orignal contract
    */
    function _burnDSC(uint256 amount,
    address on_behalf_of, address dscfrom) 
    private  
    moreThanZero(amount) {
    
     s_DSCminted[on_behalf_of] -= amount;
     emit DSC_Burned(on_behalf_of, amount);
     bool success = i_dsc.transferFrom(dscfrom, address(this), amount);
     if(!success){
        revert DSCEngine_burnNotSuccess();
     }

     i_dsc.burn(amount);

    //  revertIfHealthFactorIsBroken(on_behalf_of); 

    }

    /*
    @prams user address to check the health factor
    calls the get information function using the address of the user
    calls the check health factor function using the amount of collateral and dsc minted 
    the function returns the health factor  
    */
    function _healthfactor( address user) private view returns (uint256) {
        (uint256 dscminted, uint256 collateralvalue) = _getInformation( user);
        return _calculatehealthfactor( dscminted, collateralvalue);
        

    }

    /*
    @prams- takes the adress 
    loops through mappings to find dsc minted and collateral value in usd 
    calls the calculate vollateral value in usd function

    */
   function _getInformation( address user) private view returns (uint256 dscminted, uint256 toatalcollateralvalueinusd) {
    dscminted = s_DSCminted[user];
    toatalcollateralvalueinusd = _getaccountcollateralvalue(user);
    // does not need return function, can be added for maintaining clean code


   }
   
   /*
   @prams user address 
   loops through accepted collateral tokens, finds the amount of particular token
    held be a particular use using the doublemapping s_collateral token deposited
    calls the get token value in usd function using the token address and the amount held 
   */
   function _getaccountcollateralvalue(address user) private view returns (uint256){
    address token;uint256 amount=0; uint256 totalcollateralvalue=0;
    for (uint256 i=0; i<s_collateraltokens.length;i++){
        token = s_collateraltokens[i];
        amount = s_collateralDeposited[user][token];
        if(amount != 0){ totalcollateralvalue += getcollateralvalueinusd(token,amount);
        }
    }
    return totalcollateralvalue;
   }

   

   

   /*
   */
  function _calculatehealthfactor(uint256 dscminted, uint256 collateralvalue) private pure returns (uint256){
    // dscminted/ collateralvalueinusd
    // but we need 200% collateralised o 150% 
    // setting presicison at 200%
    // solidity does not work with decimals 
    uint256 thresholdvalue = (collateralvalue * LIQUIDATATION_PRESICION)/PRESICSION_CORRECTION_LIQ;
    return (thresholdvalue * PRESICION_CORRECTION)/dscminted;




  }
    /* 
    */
   function _minDSCtocorrectposition( uint256 collateralvalue, uint256 DSC_minted) internal pure returns (uint256){
    uint256 y = DSC_minted -(collateralvalue * LIQUIDATATION_PRESICION)/PRESICSION_CORRECTION_LIQ;
    return y;

   }

    
    /*
    @prams user address to check and revert of health factor is broken
    utilises a function which gives health factor of the use
    comapres the returned health factor with a connstant minimum health factor stetup by the developer of contract

    */
    function revertIfHealthFactorIsBroken(address user) internal view {
        uint256 healthfactor = _healthfactor(user);
        if(healthfactor < MIN_HEALTH_FACTOR){
            revert DSCEngine_Healthfactorbroken(healthfactor);
        }

    }




    /////////////////////////////////////////////
    /////////////////////////////////////////////
    // External & Public View & Pure Functions///
    /////////////////////////////////////////////
    ////////////////////////////////////////////
    
    //calculate health factor
    //get usd value
    //get collateral value of the user
    //get collateral balance of the user
    //get token amount in usd


    // to be implemented after determination of its use
    /*
    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getAdditionalFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getLiquidationPrecision() external pure returns (uint256) {
        return LIQUIDATION_PRECISION;
    }

    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return s_collateralTokens;
    }

    function getDsc() external view returns (address) {
        return address(i_dsc);
    }

    function getCollateralTokenPriceFeed(address token) external view returns (address) {
        return s_priceFeeds[token];
    }

    function getHealthFactor(address user) external view returns (uint256) {
        return _healthFactor(user);
    }
    *
    */



}
