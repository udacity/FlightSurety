pragma solidity ^0.4.24;

abstract contract SuretyFund {

    string private _bsf_fund = "bsf.fund";

    /**
    * @dev Current rate for registering and adding liquidity to a fund.
    */
    uint256 private _feeFund = 0.01;
    /**
    * @dev Current contribution rate.
    */
    uint256 private _rateContribution = 1.0;

    /**
    * @dev Defines a surety fund.
    */
    struct SuretyFund {
        address owner;
        string name;
        uint256 ratePayout;
        uint256 rateContribution;
        bool isPublic;
    }
    /**
    * @dev Defines a surety fund contribution.
    */
    struct SuretyFundContribution {
        address contributor;
        uint256 rate;
        uint256 amount;
        uint256 timestamp;
        uint256 mature;
    }

    /**
    * @dev Insurance Funds accessor.
    */
    mapping(bytes32 => SuretyFund) _funds;
    mapping(address => uint256) _fundCount;

    /**
    * @dev Surety fund contributions
    */
    mapping(bytes32 => SuretyFundContribution) _contributions;
    mapping(address => uint256) _contributionCount;

    /**
    * @dev Event for surety fund registration.
    */
    event FundRegistered(bytes32 id, string name, address indexed account);

    /**
    * @dev Event for surety fund contribution.
    */
    event FundContribution(bytes32 id, uint256 amount, address indexed account);

    /**
    * @dev Event for surety fund contribution withdrawal
    */
    event FundContributionWithdrawal(bytes32 id, uint256 amount, address indexed account);

    function getNextFundId() external returns(bytes32 id){
        uint256 count = _fundCount[msg.sender];
        id = keccak256(abi.encodePacked(_bsf_fund, count.add(1), msg.sender));
    }
}
