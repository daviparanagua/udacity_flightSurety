pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    event AirlineAdded(address airline, address approver);
    event AirlineVotedForAdding(address airline, address approver);
    event LogMe(string text, uint256 number, address sender);

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    FlightSuretyData flightSuretyData;

    address private contractOwner;          // Account used to deploy contract

    // Airlines

    uint8 maxAirlinesBeforeMultisig;

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    // Flights

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

 
    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
         // Modify to call data contract's status
        require(true, "Contract is currently not operational");  
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier onlyAirlines()
    {
        require(isAirline(msg.sender), "Caller is not a funded airline");
        _;
    }

    modifier onlyFundedAirlines()
    {
        require(isFundedAirline(msg.sender), "Caller is not a funded airline");
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address dataContractAddress
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContractAddress);
        maxAirlinesBeforeMultisig = 4;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() 
                            public 
                            pure 
                            returns(bool) 
    {
        return true;  // Modify to call data contract's status
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline
                            (   
                                address _address,
                                string name
                            )
                            external
                            onlyFundedAirlines
                            returns(bool success, uint256 votes)
    {    
        uint256 airlinesCount = flightSuretyData.getAirlinesCount();

        if(flightSuretyData.getAirlinesCount() < maxAirlinesBeforeMultisig) { // Simple registration
            flightSuretyData.registerAirline(_address, name, true);
            emit AirlineAdded(_address, msg.sender);
            return (true, 0); 
        } else { // Multisig

            bool exists;
            bool isAirline;
            bool isFunded;
            uint256 approvalCount;

            (
                ,,
                exists,
                isAirline,
                isFunded,
                approvalCount
            ) = flightSuretyData.getAirlineData(_address);

            if(!exists){
                flightSuretyData.registerAirline(_address, name, false);
            }

            emit LogMe('approvalCount+1', approvalCount + 1, msg.sender);
            emit LogMe('airlinesCount/2', airlinesCount/2, msg.sender);

            if(approvalCount + 1 < airlinesCount/2) { // Only a vote
                flightSuretyData.addApproval(_address, msg.sender);
                emit AirlineVotedForAdding(_address, msg.sender);
            } else { // Final vote: approved
                flightSuretyData.confirmApproval(_address, msg.sender);
                emit AirlineAdded(_address, msg.sender);
            }

            
        }
    }
    
    function isAirline
                            (   
                                address _address
                            )
                            public
                            view
                            returns(bool)
    {
        return flightSuretyData.isAirline(_address);
    }

    function isFundedAirline
                            (   
                                address _address
                            )
                            public
                            view
                            returns(bool)
    {
        if(!isAirline(_address)){return false;}
        return flightSuretyData.isFundedAirline(_address);
    }

    function addFunds
                            (
                            )
                            public
                            payable
                            onlyAirlines
    {
        flightSuretyData.addFunds.value(msg.value)(msg.sender);
    }

    // FLIGHTS

   /**
    * @dev Buy insurance
    *
    */  
    function buyInsurance
                                (
                                    uint256 flightID
                                )
                                external
                                payable
    {
        require(msg.value <= 1 ether, "Max insurance is 1 ether");
        require(msg.value > 0 wei, "Must pay for insurance");
        require(tx.origin == msg.sender, "Only external accounts can buy insurance");
        require(flightID > 0, "Must specify flight ID");
        require(flightSuretyData.getInsuranceValue(msg.sender, flightID) == 0, "Already bought insurance for this flight");
        
        flightSuretyData.buy.value(msg.value)(msg.sender, flightID);
    }

    /**
    * @dev Buy insurance
    *
    */  
    function getInsurance
                                (
                                    uint256 flightID
                                )
                                external
                                view
                                returns(uint256)
    {
        return flightSuretyData.getInsuranceValue(msg.sender, flightID);
    }
    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                pure
    {
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string flight,
                            uint256 timestamp                            
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    } 


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}   

contract FlightSuretyData {
    function registerAirline
                            (   
                                address _address,
                                string _name,
                                bool _approved
                            )
                            external;

    function isAirline
                            (   
                                address _address
                            )
                            public
                            view
                            returns (bool);

    function isFundedAirline
                            (   
                                address _address
                            )
                            public
                            view
                            returns (bool);

    function addFunds
                            (   
                                address _address
                            )
                            public
                            payable;

    function getAirlinesCount
                            (   
                            )
                            public
                            view
                            returns (uint256);

    function getAirlineData
                            (   
                                address _address
                            )
                            external
                            view
                            returns
                            (
                                address addr,
                                string name,
                                uint256 balance,
                                bool exists,
                                bool isAirline,
                                bool isFunded,
                                uint256 approvalCount
                            );
    
     function hasApprovedAirline
                            (   
                                address _address,
                                address _airlineAddress
                            )
                            external
                            view
                            returns (bool);
    
    function addApproval
                            (   
                                address _address,
                                address _approver
                            )
                            external;
    
    function confirmApproval
                            (   
                                address _address,
                                address _approver
                            )
                            external;
    
    function getInsuranceValue
                            (          
                                address _address,
                                uint256 flightID                
                            )
                            external
                            view
                            returns (uint256);

    function buy
                            (          
                                address _address,
                                uint256 flightID                
                            )
                            external
                            payable;
}