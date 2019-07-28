pragma solidity ^0.5.10;

contract Stro {
    enum redemptionState { START, INPROGRESS, DISPUTE, REDEEMED }
    
    struct redemptionChannel{
        address restaurant;
        address payable customer;
        uint256 blockNumber;
        uint256 disputePeriodLength;
        uint256 nonce;
        uint256 redemptionEarned;
        uint256 redemptionAmount;
        redemptionState currentRedemptionState;
    }
    
    modifier uniqueId(uint uid) {
        require(multiChannel[uid].customer == address(0) && multiChannel[uid].restaurant == address(0));
        _;
    }
    
    modifier isSender(uint uid) {
        require(multiChannel[uid].restaurant == msg.sender, "This restaurant is not the initiator of the redemption");
        _;
    }
    
    modifier isChannelParticipant(uint uid) {
        require(multiChannel[uid].customer == msg.sender || multiChannel[uid].restaurant == msg.sender, "Must be channel participant");
        _;
    }
    
    modifier lessThanRedemptionValue(uint uid, uint256 amount) {
        require(amount <= multiChannel[uid].redemptionEarned, "Amount exceeds redemptions earned");
        _;
    }
    
    mapping (uint => redemptionChannel) public multiChannel;
    
    /**
        @dev Enables restaurant to create new redemption channel for a customer
        @param uid unique id for the new channel
        @param _customer address of the customer who will be redeeming stro points
     */
    function newCustomerRedemptionChannel (uint uid, address payable _customer) public uniqueId(uid) {
        multiChannel[uid].restaurant = msg.sender;
        multiChannel[uid].customer = _customer;
        multiChannel[uid].disputePeriodLength = 20;
    }
    
    /**
        @dev Enables restaurant provide stro Points to customer every time they ask for stamping
        @param uid unique id for the channel
     */
    function stroStamping(uint uid) public payable isSender(uid){
        multiChannel[uid].redemptionEarned += msg.value;
        multiChannel[uid].currentRedemptionState = redemptionState.INPROGRESS;
    }
    
    /**
        @dev Enables restaurant/customer to redeem the accumulated points
        @param uid unique id for the channel
        @param _nonce unique number for the redemption
        @param amount the amount to be redeemed
        @param message the signed message
        @param v signature part
        @param r signature part
        @param s signature part
     */
    function stroRedeem(uint uid, uint256 _nonce, uint256 amount, string memory message, uint8 v, bytes32 r, bytes32 s) public lessThanRedemptionValue(uid, amount) isChannelParticipant(uid) {
        require(verifySigner(message, v, r, s) == multiChannel[uid].customer || verifySigner(message, v, r, s) == multiChannel[uid].restaurant, "Invalid signature");
        multiChannel[uid].blockNumber = block.number;
        multiChannel[uid].currentRedemptionState = redemptionState.DISPUTE;
        multiChannel[uid].nonce = _nonce;
        multiChannel[uid].redemptionAmount = amount;
    }
    
    /**
        @dev Enables restaurant/customer to dispute the redemption
        @param uid unique id for the channel
        @param newNonce unique number for the dispute
        @param amount the amount to be redeemed
        @param message the signed message
        @param v signature part
        @param r signature part
        @param s signature part
     */
    function disputeRedemption(uint uid, uint256 newNonce, uint256 amount, string memory message, uint8 v, bytes32 r, bytes32 s) public lessThanRedemptionValue(uid, amount) isChannelParticipant(uid) {
        require(multiChannel[uid].currentRedemptionState == redemptionState.DISPUTE, "In dispute");
        require(multiChannel[uid].blockNumber + multiChannel[uid].disputePeriodLength < block.number);
        require(newNonce > multiChannel[uid].nonce, "updated Nonce");
        require(verifySigner(message, v, r, s) == multiChannel[uid].customer || verifySigner(message, v, r, s) == multiChannel[uid].restaurant, "Invalid signature");
        multiChannel[uid].nonce = newNonce;
        multiChannel[uid].redemptionAmount = amount;
    }
    
    /**
        @dev Enables restaurant/customer to transfer the redeemed amount to the customer
        @param uid unique id for the channel
     */
    function stroPay(uint uid) public isChannelParticipant(uid) {
        require(block.number > multiChannel[uid].blockNumber + multiChannel[uid].disputePeriodLength);
        multiChannel[uid].currentRedemptionState = redemptionState.REDEEMED;
        multiChannel[uid].redemptionEarned -= multiChannel[uid].redemptionAmount;
        uint256 toTransfer = multiChannel[uid].redemptionAmount;
        multiChannel[uid].redemptionAmount = 0;
        multiChannel[uid].redemptionEarned -= toTransfer;
        
        (multiChannel[uid].customer).transfer(toTransfer);
    }
    
    /**
        @dev Verifies the signature
        @param message the signed message
        @param v signature part
        @param r signature part
        @param s signature part
     */
    function verifySigner(string memory message, uint8 v, bytes32 r,
                 bytes32 s) internal pure returns (address signer) {

        // The message header; we will fill in the length next
        string memory header = "\x19Ethereum Signed Message:\n000000";

        uint256 lengthOffset;
        uint256 length;
        assembly {
            // The first word of a string is its length
            length := mload(message)
            // The beginning of the base-10 message length in the prefix
            lengthOffset := add(header, 57)
        }

        // Maximum length we support
        require(length <= 999999);

        // The length of the message's length in base-10
        uint256 lengthLength = 0;

        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;

        // Move one digit of the message length to the right at a time
        while (divisor != 0) {

            // The place value at the divisor
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }

            // Found a non-zero digit or non-leading zero digit
            lengthLength++;

            // Remove this digit from the message length's current value
            length -= digit * divisor;

            // Shift our base-10 divisor over
            divisor /= 10;

            // Convert the digit to its ASCII representation (man ascii)
            digit += 0x30;
            // Move to the next character and write the digit
            lengthOffset++;

            assembly {
                mstore8(lengthOffset, digit)
            }
        }

        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }

        // Truncate the tailing zeros from the header
        assembly {
            mstore(header, lengthLength)
        }

        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(header, message));

        return ecrecover(check, v, r, s);
    }
    
}

contract Factory {
    uint public currentStroId;
    
    mapping(uint => Stro) stro;
    
    function deployStro() public  {
        currentStroId++;
        Stro c = new Stro();
        stro[currentStroId] = c;
    }
    
    function getStrobyId(uint _id) public view returns (Stro) {
        return stro[_id];
    }
}

contract Dashboard {
    Factory database;
    
    constructor(address _database) public {
        database = Factory(_database);
    }
    
    function newStro() public {
        database.deployStro();
    }
    
    function newCustomerRedemptionChannelId(uint _id, uint channelId, address payable _customer) public payable{
        Stro c = Stro(database.getStrobyId(_id));
        c.newCustomerRedemptionChannel(channelId, _customer);
    }
    
    function stroStamping(uint _id, uint channelId) public payable {
        Stro c = Stro(database.getStrobyId(_id));
        c.stroStamping.value(msg.value)(channelId);
    }
    
    function stroRedeem(uint _id, uint channelId, uint256 _nonce, uint256 amount, string memory message, uint8 v, bytes32 r, bytes32 s) public {
        Stro c = Stro(database.getStrobyId(_id));
        c.stroRedeem(channelId, _nonce, amount, message, v, r, s);
    }
    
    function disputeRedemption(uint _id, uint channelId, uint256 newNonce, uint256 amount, string memory message, uint8 v, bytes32 r, bytes32 s) public {
        Stro c = Stro(database.getStrobyId(_id));
        c.disputeRedemption(channelId, newNonce, amount, message, v, r, s);
    }
    
    function stroPay(uint _id, uint channelId) public payable {
        Stro c = Stro(database.getStrobyId(_id));
        c.stroPay(channelId);
    }
    
    function multiChannel(uint _id, uint channelId) public view {
        Stro c = Stro(database.getStrobyId(_id));
        c.multiChannel(channelId);
    }
}