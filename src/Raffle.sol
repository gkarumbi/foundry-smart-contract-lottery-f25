// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
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
// internal & private view & pure functions
// external & public view & pure functions

// End //

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title A sample Raffle contract
 * @author George Karumbi
 * @notice This contract is from creatinf a simple raffle
 * @dev Implement Chainlink VRF2.5
 */

contract Raffle{

    /** Errors **/
    error Raffle__SendMoreToEnterRaffle();

    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee){
        i_entranceFee = entranceFee;

    }

    function enterRaffle() public payable {
        //Since we are going to be paying an entrace fee, we make our function payable
        if(msg.value < i_entranceFee){
              revert Raffle__SendMoreToEnterRaffle();
        }
    }

    function pickWinner() public {}

    /** Getter Functions **/

    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }

}

