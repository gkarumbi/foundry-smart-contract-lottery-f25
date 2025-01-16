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
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

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
    event RequestedRaffleWinner(uint256 indexed requestId);

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
    //When should the winner be picked

    /**
     * @dev This is the function that the Chainlink nodes will call to see
     * if the lotterry is ready to have a winner picked
     * The following should be true in order for upKeepNeeded to be true:
     * 1. The time interval has passed between raffles
     * 2. The lottery is open
     * 3. The contract has ETH
     * 4. Implicitly, your subscription has LINK
     * @param - ignored
     * @return upkeepNeeded  - true if it is time to restart the lottery
     * @return - ignored
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        /*  if((block.timestamp - s_lastTimeStamp) < i_interval){
            revert();
        } */
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }
    //. Be automaticall called and refactored from pickWinner() to performUpkeep()

    function performUpkeep(bytes calldata /* performData */ ) external {
        //@dev check to see if enough time has passed
        //@dev we create a variable s_lastTimeStamp to track the last recorded time stamp

        /* if (block.timestamp - s_lastTimeStamp > i_interval) {
            revert();
        } */
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
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

        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256, /*requestedId*/ uint256[] calldata randomWords) internal override {
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
        emit WinnerPicked(s_recentWinner);
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Functions *
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getLastTimeStamp() external view returns(uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns(address){
        return s_recentWinner;
    }
}
