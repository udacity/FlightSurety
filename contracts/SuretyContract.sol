pragma solidity ^0.4.24;

abstract contract FlightSuretyContract {

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
        bytes32 flight;
        /**
        * @dev Insured value.
        */
        uint256 value;
    }

    enum InsuranceType {
        Accident,
        Cancellation,
        Delay,
        Luggage
    }

    /**
    * @dev Insurance Contracts accessor.
    */
    mapping(bytes32 => Insurance) _contracts;
    /**
    * @dev Contract count for address.
    */
    mapping(address => uint256) _contractCount;

    function _getContractId(address owner, uint256 count) private returns (bytes32 id) {
        id = keccak256(abi.encodePacked(_bsf_contract, owner, count));
    }
    /**
     * @dev Gets the contracts for a specified address.
     */
    function getContractIds(address owner) external view returns (bytes32[] ids){
        uint256 count = _contractCount[owner];
        ids = bytes32[count];
        for(uint256 i = 0; i <= count; i += 1){
            ids[i] = _getContractId(owner, count);
        }
    }

    /**
     * @dev Get contract id.
     */
    function getNextContractId(address owner, uint256 count) external view returns(bytes32 id) {
        uint256 count = _contractCount[owner].add(1);
        id = _getContractId(owner, count);
        _contractCount[owner] = count;
    }

    function _registerContract() private returns(bool) {

    }

    /**
     * @dev Registers a contract.
     */
    function registerContract(address owner, 
                              bytes32 fund,
                              bytes32 flight,
                              uint8 typeId,
                              uint256 value)
                              external
         returns(bool ret){

    }
}
