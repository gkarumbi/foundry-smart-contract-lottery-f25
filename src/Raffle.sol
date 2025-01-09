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
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author George Karumbi
 * @notice This contract is from creatinf a simple raffle
 * @dev Implement Chainlink VRF2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors *
     */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();

    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    uint256 private immutable i_entranceFee;
    //@dev The duration of the lottery in seconds
    uint256 private immutable i_interval;
    //@dev we create a variable s_lastTimeStamp to track the last recorded time stamp
    uint256 private s_lastTimeStamp;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    /*     why didnt we define the above in the constructor?
        because it can be changed dynamically during compile time
    */
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    //We are going to use an array to keep track of our players and we are going to make it payable

    address payable[] private s_players;

    address private s_recentWinner;

    RaffleState private s_raffleState;

    /* Events */

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        //@dev We start counting time once the contract has been deployed
        //thus the s_lastTimeStamp will be set to the timestamp of the block in which the contract was deployed
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        //Since we are going to be paying an entrace fee, we make our function payable
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        /**
         * When a player wants to enter the raffle they are going to send an entrance fee,
         *      the amount is set in the constructor during contract deployment,
         *      in the enterRaffle() function its going to be verified that the amount sent is more than
         *      the required amount and if so the player is going to be added to the s_players array
         *      which is a state variable array that tracks the players.
         *      We are also going to typecast the msg.sender object to convert it
         *      from a normal address object to a payable address object that can recieve payments
         *      in terms of winnings
         *
         */
        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }

    function pickWinner() external {
        //@dev check to see if enough time has passed
        //@dev we create a variable s_lastTimeStamp to track the last recorded time stamp

        if (block.timestamp - s_lastTimeStamp > i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(uint256 requestedId, uint256[] calldata randomWords) internal override {
        /* So how do  we pick our winner?
        we pick our winner by 1st taking a randomly generated number which is going to be 
        only one number in our case, we are going to pull it from our randomWords[] array 
        where it is stored in index zero, then we are going to divide, rather modulo, it by the length of our players array
        and the result or winner  will be the index of the winner in the s_players. The index is determined by the modulo result */
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        /* To ensure that true randomness we need to reset the array to ensure that
        the players do not maintain the same position, essensially the to ensure the
        same player is not picked even if the same index is picked at random */
        s_players = new address payable[](0);
        /* reset last time interval back to last time stamp */
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if(!success){
            revert Raffle__TransferFailed();
        }

        emit WinnerPicked(s_recentWinner);

    }

    /**
     * Getter Functions *
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
