pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    mapping(address => bool) private authorizedCallers;

    uint256 airlinesCount;
    struct Airline {
        address addr;
        string name;
        uint256 balance;
        bool exists;
        bool isAirline;
        bool isFunded;
        uint256 approvalCount;
        mapping(address=>bool) approvals;
    }
    mapping(address => Airline) private airlines;



    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address _firstAirline,
                                    string _firstAirlineName
                                ) 
                                public 
    {
        contractOwner = msg.sender;

        airlines[_firstAirline] = Airline({
            addr: _firstAirline,
            name: _firstAirlineName,
            balance: 0,
            exists: true,
            isAirline: true,
            isFunded: false,
            approvalCount: 0
        });

        airlinesCount = 1;
    }

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
        require(operational, "Contract is currently not operational");
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

    /** 
    * @dev Modifier that requires the caller to be authorized
    */
    modifier onlyAuthorizedCaller(){
        require(authorizedCallers[msg.sender] == true);
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    function authorizeCaller(address contractAddress) requireContractOwner public
    {
        authorizedCallers[contractAddress] = true;
    }

    function deauthorizeCaller(address contractAddress) requireContractOwner public
    {
        authorizedCallers[contractAddress] = false;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                address _address,
                                string _name,
                                bool _approved
                            )
                            external
                            onlyAuthorizedCaller
    {
        
        airlines[_address] = Airline({
            addr: _address,
            name: _name,
            balance: 0,
            exists: true,
            isAirline: _approved,
            isFunded: false,
            approvalCount: 0
        });

        airlinesCount = airlinesCount + 1;
    }

    /** */
    function isAirline
                            (   
                                address _address
                            )
                            public
                            view
                            returns (bool)
    {
        return airlines[_address].isAirline;
    }

    /** */
    function getAirlineData
                            (   
                                address _address
                            )
                            external
                            view
                            onlyAuthorizedCaller
                            returns
                            (
                                address addr,
                                string name,
                                uint256 balance,
                                bool isAirline,
                                bool isFunded,
                                uint256 approvalCount
                            )
    {
        addr = airlines[_address].addr;
        name = airlines[_address].name;
        balance = airlines[_address].balance;
        isAirline = airlines[_address].isAirline;
        isFunded = airlines[_address].isFunded;
        approvalCount = airlines[_address].approvalCount;
    }

    /** */
    function hasApprovedAirline
                            (   
                                address _address,
                                address _airlineAddress
                            )
                            external
                            view
                            onlyAuthorizedCaller
                            returns (bool)
    {
        return airlines[_airlineAddress].approvals[_address];
    }

     /** */
    function getAirlinesCount
                            (   
                            )
                            external
                            view
                            onlyAuthorizedCaller
                            returns (uint256)
    {
        return airlinesCount;
    }

    /** */
    function isFundedAirline
                            (   
                                address _address
                            )
                            external
                            view
                            returns (bool)
    {
        return airlines[_address].isFunded;
    }

    /** */
    function addFunds
                            (   
                                address _address
                            )
                            external
                            payable
                            onlyAuthorizedCaller
    {
        airlines[_address].balance = airlines[_address].balance.add(msg.value);

        if(airlines[_address].balance >= 10 ether){
            airlines[_address].isFunded = true;
        }
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

