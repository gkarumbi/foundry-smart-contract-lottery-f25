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

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";


/**
 * @title A sample Raffle contract
 * @author George Karumbi
 * @notice This contract is from creatinf a simple raffle
 * @dev Implement Chainlink VRF2.5
 */

contract Raffle is VRFConsumerBaseV2Plus{

    /** Errors **/
    error Raffle__SendMoreToEnterRaffle();

    uint256 private immutable i_entranceFee;
    //@dev The duration of the lottery in seconds
    uint256 private immutable i_interval;
    //@dev we create a variable s_lastTimeStamp to track the last recorded time stamp
    uint256 private s_lastTimeStamp;


    //We are going to use an array to keep track of our players and we are going to make it payable

    address payable[] private s_players;

    /* Events */

    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee, uint256 interval){
        i_entranceFee = entranceFee;
        i_interval = interval;
        //@dev We start counting time once the contract has been deployed
        //thus the s_lastTimeStamp will be set to the timestamp of the block in which the contract was deployed
        s_lastTimeStamp = block.timestamp;

    }

    function enterRaffle() external payable {
        //Since we are going to be paying an entrace fee, we make our function payable
        if(msg.value < i_entranceFee){
              revert Raffle__SendMoreToEnterRaffle();
        }
        /**
         When a player wants to enter the raffle they are going to send an entrance fee,
         the amount is set in the constructor during contract deployment,
         in the enterRaffle() function its going to be verified that the amount sent is more than
         the required amount and if so the player is going to be added to the s_players array
         which is a state variable array that tracks the players.
         We are also going to typecast the msg.sender object to convert it 
         from a normal address object to a payable address object that can recieve payments
         in terms of winnings
         **/
        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }

    function pickWinner() external {
        //@dev check to see if enough time has passed
        //@dev we create a variable s_lastTimeStamp to track the last recorded time stamp

       if(block.timestamp - s_lastTimeStamp > i_interval){
          revert();
       }
       requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    /** Getter Functions **/

    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }

}

