// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./BsfComptroller.sol";

contract BsfContract is Ownable {

    string internal _bsf_comptroller = "bsf.comptroller";
    string internal _bsf_token = "bsf.token";

    string internal _bsf_airline = "bsf.airline";
    string internal _bsf_airline_nft = "bsf.airline.nft";
    string internal _bsf_airline_vote = "bsf.airline.vote";

    string internal _bsf_insurance = "bsf.insurance";
    string internal _bsf_insurance_nft = "bsf.insurance.nft";

    /**
    * @dev Operational status of the contract.
    */
    bool internal _operational;

    IBsfComptroller internal _comptroller;
    //IBSF20 internal _token;

    constructor(address comptroller_) {
        _operational = true;
        _comptroller = comptroller_;
        //_token = _comptroller.getContract(_bsf_token);
    }

    modifier authorized(string key) {
        require(_comptroller.access(key, msg.sender), "BSF Contract access required.");
        _;
    }

    /**
    * @dev Modifier that requires the "_operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireOperational() 
    {
        require(_operational, "Contract is not currently operational.");  
        _;
    }

    modifier requireValidString(string memory value){
        bytes memory temp = bytes(value);
        require(temp.length > 0, "'value' must be a valid string.");
        _;
    }

    modifier requireValidAddress(address account){
        require(account != address(0), "'account' cannot be equal to burn address.");
        _;
    }

    function changeComptroller(address new_) external onlyOwner returns(bool success) {
        _comptroller = IBsfComptroller(new_);
        success = true;
    }

    function operational() 
                            external 
                            pure 
                            returns(bool) 
    {
        return _operational;  // Modify to call data contract's status
    }

    function changeOperational(bool status) external onlyOwner returns(bool success){
        _operational = status;
        return true;
    }
}