pragma solidity ^0.4.24;

abstract contract SuretyContract {

    string private _bsf_contract = "bsf.contract";

    /**
    * @dev Defines an insurance contract.
    */
    struct Insurance {
        /**
        * @dev Insured account address.
        */
        address account;
        /**
        * @dev Surety fund.
        */
        bytes32 fund;
        /**
        * @dev airline.
        */
        bytes32 airline;
        /**
        * @dev Insured value.
        */
        uint256 value;
    }

    /**
    * @dev Insurance Contracts accessor.
    */
    mapping(bytes32 => Insurance) _contracts;
    /**
    * @dev Contract count for address.
    */
    mapping(address => uint256) _contractCount;

    function getNextContractId() returns(bytes32 id){
        uint256 count = _contractCount[msg.sender];
        id = keccak256(abi.encodePacked(_bsf_contract,count.add(1),msg.sender));
    }
}
