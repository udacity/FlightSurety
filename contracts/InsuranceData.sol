// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract InsuranceData {
    using SafeMath for uint256;

    string private _bsf_insurance = "bsf.insurance";

    /**
    * @dev Current insurance rate.
    */
    uint256 private _feeInsurance = 0.01;

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
    mapping(address => uint256) _insuranceCount;

   /**
    * @dev Buy insurance for a flight
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {}

    function _credit(bytes32 _contract, uint256 value) private {
        Insurance bond = _contracts[_contract];
        //require(bond.payable, "Insurance contract must be in a 'payable' state.");
        //_payouts[bond.account]
        //payouts[insured] = payout;
    }

    /**
    * @dev Credit insured contracts.
    */
    function credit(address fund, address insured, uint256 value) external pure requireOperational {
        require((fund != address(0) && insured != address(0)), "Accounts must be valid address.");
        require(_funds[fund].name.length > 0, "The target fund does not exist.");
        require(_contracts[insured].passenger == insured, "Insure was not an insured passenger.");

    }

    function withdraw(address insured) external requireOperational returns(uint256){
        require(msg.sender == insured, "Only insured party may withdraw an authorized payout.");
        uint256 value = 0;
        return value;
    }

    /**
     * @dev Get contract id.
     */
    function getNextInsuranceId(address owner) external view returns(bytes32 id) {
        require(owner != address(0), "'owner' must not be burn address.");
        uint256 count = _insuranceCount[owner].add(1);
        id = _getContractId(owner, count);
    }

    function _registerInsurance() private returns(bool) {

    }

    /**
     * @dev Registers an insurance contract.
     */
    function registerInsurance(address owner, 
                              bytes32 fund,
                              bytes32 flight,
                              uint8 typeId,
                              uint256 value)
                              external
         returns(bool ret){

    }
}
