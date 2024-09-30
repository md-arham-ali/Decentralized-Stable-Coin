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

contract DSCEngine {
    ////////////////////
    ////// Errors //////
    ////////////////////
    error DSCEngine_tokenaddressandpricefeedaddressdoesnotMatch();


    ////////////////////////
    // State variables ////
    ////////////////////////

    DSC private immutable i_dsc;

    address[] private s_collateraltokens;

    // to decide the types of collaterl tokens accepted, store its address, its price feed address, also its price feed address on a particular test chain


    // //modifiers//
    // mapping (address chain => mapping (address token => address pricefed)) private chain_pricefeed;// probable mapping
    mapping (address token => address pricefeed) private s_pricefeed;// stores its price feed address on a particular chain linked to the particular token address



    ////////////////////////
    /////// Events /////////
    ////////////////////////

    ////////////////////////
    ///// Modifiers ////////
    ////////////////////////

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
    function mintDSC() external {}

    function burnDSC() external {}

    function deposit_collateral() external {}

    function deposit_collateral_and_mintDSC() external {}

    function redeem_collateral_forDSC() external {}

    function redeem_collateral() external {}

    function liquidate() external {}


    ////////////////////////
    // Private Functions ///
    ////////////////////////

    //redeem collateral
    //burnDSC
    //get account information
    //health factor
    //get health factor
    //get usd value
    //calculate health factor
    //revert if health factor is broken




    /////////////////////////////////////////////
    /////////////////////////////////////////////
    // External & Public View & Pure Functions///
    /////////////////////////////////////////////
    ////////////////////////////////////////////
    
    //calculate health factor
    //get account informatio9n
    //get usd value
    //get collateral value of the user
    //get collateral balance of the user
    //get token amount in usd


    /*to be implemented after determination of its use
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
