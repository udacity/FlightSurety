// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../BsfComptroller.sol";
import "./AirlineData.sol";
import "../insurance/InsuranceData.sol";
import "./FlightData.sol";
import "../PayoutData.sol";

contract SuretyData is Ownable, 
                             AirlineData, 
                             InsuranceData, 
                             FlightData,
                             PayoutData {
    using SafeMath for uint256;

    string private _bsf_surety = "bsf.surety";

    /**
    * @dev Operational status of the contract.
    */
    bool private _operational = true;

    IBsfComptroller _comptroller;

    /**
    * @dev The fee types supported by the platform.
    */
    enum FeeType {
        Airline,
        Fund,
        Insurance
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Constructor
    * @dev The deploying account becomes contractOwner
    */
    constructor (
                    address comptroller
                ) 
                public
    {
        _transferOwnership(msg.sender);
        _registerAirline(contractOwner, "Frontier Airlines");
        _registerFund(contractOwner,"General Fund");
        _comptroller = IBsfComptroller(comptroller);
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
    modifier requireOperational() {
        require(_operational, "Contract is currently not operational");
        _; 
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    function _calculateFee(FeeType _fee, uint256 value) internal returns(uint256 f) {
        if(fee == FeeType.Airline) {
            f = _getAirlineFee();
        }
        if(fee == FeeType.Fund) {
            f = _getFundFee(value);
        }
        if(fee == FeeType.Insurance) {
            f = _getContractFee(value);
        }
    }

    /**
    * @dev Calculates the fee for specified fee type.
    */
    function calculateFee(FeeType fee_, uint256 value) external view returns(uint256 fee) {
        require(fee_ == FeeType.Airline || fee_ == FeeType.Fund || fee_ == FeeType.Insurance, "'fee' is an unsupported type.");
        fee = _calculateFee(fee_, value);
    }
    /**
    * @dev Get operating status of contract
    * @return A bool that is the current operating status
    */      
    function operational() external view returns(bool) {
        return _operational;
    }

    /**
     * @dev Set operating status of contract
     */
    function setOperational(bool mode) external onlyOwner {
        _operational = mode;
    }

    /**
    * @dev Gets the current fee for specified fee type.
    * @param feeType {FeeType} The fee type to calculate.
    * @return {uint256} The current fee for specified type.
    */
    function fee(FeeType feeType) external view returns(uint256){
        if(FeeType.Fund == feeType){
            return _getFundFee();
        }
        if(FeeType.Airline == feeType){
            return _getAirlineFee();
        }
        if(FeeType.Insurance == feeType){
            return _getContractFee();
        }
    }
    /**
    * @dev Sets the fee for a specified fee type.
    */
    function setFee(FeeType feeType, uint256 amount) external onlyOwner {
        require(amount >= 0, "Fee cannot be negative.");
        if(FeeType.Fund == feeType) {
            _setFeeFund(amount);
        }
        if(FeeType.Airline == feeType) {
            _setFeeAirline(amount);
        }
        if(FeeType.Insurance == feeType) {
            _setContractFee(amount);
        }
    }
}

