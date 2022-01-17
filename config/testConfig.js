
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function(accounts) {
    
    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
        "0x1787A42757418cB0492669979cB04AaAD00d19F6",
        "0x8Dcf8ccEf6EdEefB014be6A9Cfb135DFC93F12cC",
        "0x9Ce46945157Fe622Ca5b3716D4ea9369e3ffb029",
        "0xC6f9131B40C0cfdfc68E8971507412C01d9E4506",
        "0xA77B820fdF3Eda29584732860333031CAdc0E6D0",
        "0x2AFbF62B10BeD3b95ba681f3A34977B61Ba18de5",
        "0xBD4C3E08b45d24488fB79d1e51485C413c7aBe5f",
        "0x73F05C2b0dE3c8549fb73e7E39109075Dd873a72",
        "0xF083a99194A9a320706F05B98BE2AB0198Cbb120",
        "0x318247531573f051895Bbf873A138d333f780fa6"
    ];


    let owner = accounts[0];
    let firstAirline = accounts[1];

    let flightSuretyData = await FlightSuretyData.new();
    let flightSuretyApp = await FlightSuretyApp.new();

    
    return {
        owner: owner,
        firstAirline: firstAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};