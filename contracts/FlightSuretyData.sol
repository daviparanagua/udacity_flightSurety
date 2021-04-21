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

    
    // Insurances

    mapping (address => mapping (string => uint256)) insurances;
    mapping (string => address[]) insurancesPerFlight;
    mapping (address => uint256) balances;

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

        if(_approved){
            airlinesCount = airlinesCount + 1;
        }
    }

    function addApproval
                            (   
                                address _address,
                                address _approver
                            )
                            external
                            onlyAuthorizedCaller
    {
        require(!airlines[_address].isAirline, "Request already approved");
        require(!airlines[_address].approvals[_approver], "Already approved by this approver");

        airlines[_address].approvalCount += 1;
        airlines[_address].approvals[_approver] = true;
    }


     function confirmApproval
                            (   
                                address _address,
                                address _approver
                            )
                            external
                            onlyAuthorizedCaller
    {
        require(!airlines[_address].isAirline, "Request already approved");
        require(!airlines[_address].approvals[_approver], "Already approved by this approver");

        airlines[_address].approvals[_approver] = true;
        airlines[_address].isAirline = true;
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
                                address _address,
                                string _flightID,
                                address airline        
                            )
                            external
                            payable
                            onlyAuthorizedCaller
    {
        address insuree = _address;
        string memory flightID = _flightID;
        uint256 insuranceValue = msg.value;

        insurancesPerFlight[flightID].push(insuree);
        insurances[insuree][flightID] = insurances[insuree][flightID].add(insuranceValue);
        airlines[airline].balance.add(msg.value);
    }

    /**
    * @dev Get Insurance value for flight
    *
    */   
    function getInsuranceValue
                            (          
                                address _address,
                                string flightID           
                            )
                            external
                            view
                            returns (uint256)
    {
        return insurances[_address][flightID];
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    address _airline,
                                    string _flightID
                                )
                                external
                                onlyAuthorizedCaller
    {
        address _insuree;
        uint256 amount;

        for(uint i=0; i < insurancesPerFlight[_flightID].length; i++){
            _insuree = insurancesPerFlight[_flightID][i];
            amount = insurances[_insuree][_flightID].mul(3).div(2);

            insurances[_insuree][_flightID] = 0;
            balances[_insuree] = balances[_insuree].add(amount);

            airlines[_airline].balance = airlines[_airline].balance.sub(amount);
        }
        
        delete insurancesPerFlight[_flightID];
    }

    /**
    * @dev Get Balance
    *
    */   
    function getBalance
                            (          
                                address _address         
                            )
                            external
                            view
                            returns (uint256)
    {
        return balances[_address];
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address insuree
                            )
                            external
    {
        uint256 amount = balances[insuree];
        require(amount > 0, "No balance to withdraw");
        balances[insuree] = 0;

        insuree.transfer(amount);
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
        revert(); // Can only add funds by app contract
    }


}

