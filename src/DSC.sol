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

pragma solidity 0.8.19;

//lib/openzepplin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol

import { ERC20Burnable, ERC20} from "@openzepplin/contracts/token/ERC20/extensions/ERC20Burnable.sol";// importing standard stable coin contract functions
import { Ownable } from "@openzepplin/contracts/access/Ownable.sol";//look up ownable contract at the address for more information


contract DSC is ERC20Burnable, Ownable {
    //errors
    error DSC_addressshouldnotbezero();
    error DSC_amountmustbenonzero();
    error DSC_burnamountexceedsbalance();
    
    
    constructor() ERC20("Arham_Stablecoin_Pegged", "ARS"){}
    //burn function
    //mint function
    //rest of the logic is to be implemented in DSCengine.sol

    function mint(address _to, uint256 amt) public onlyOwner returns (bool) {// why use public instead of external?
        if ( _to == address(0)){
            revert DSC_addressshouldnotbezero();
        }

        if(amt == 0){
            revert DSC_amountmustbenonzero();
        }

        _mint(_to,amt);
        return true;

    }

    function burn(uint256 amt) public view override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if(amt <= 0){
            revert DSC_amountmustbenonzero();
        }
        if(amt>balance){
            revert DSC_burnamountexceedsbalance();
        }


        
    }
    //self explainable standard logic of a token burn and mint function
}