import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';

(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {
        
        // console.log('NUMBER OF ACCOUNT ' + this.web3.eth.accounts.length);
        // console.log(this.web3.personal.newAccount());
        // console.log(this.web3.eth.accounts.length);
        let max_insurancePrice;
        // let isInsured;
        contract.maxInsurancePrice().then(function(price) {
            max_insurancePrice = price;
        });

        function findKeyByValue(obj, value) {
            for (let key in obj) {
              if (obj[key] === value) {
                return key;
              }
            }
            return null; // Return null if the value is not found
          }

        DOM.elid("ConnectedAccount").innerHTML = 'Not connected';
        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
  
        let custWant_FlightInsured = [];
        var arrayFlight_Insured = {};
        window.ethereum.on('accountsChanged', function (accounts) {
            // arrayFlight_WantInsured.push(accounts[0]);
            custWant_FlightInsured = accounts[0];
            // console.log('aaaddreeesfsdbcsjb is ' + custWant_FlightInsured)
            DOM.elid("ConnectedAccount").innerHTML = custWant_FlightInsured;
        })

        // User-submitted transaction - buy insurance
        DOM.elid('buy-insurance').addEventListener('click', () => {
            let insurePrice = DOM.elid('amount-Insurance').value;
            const selectElement = DOM.elid('flight-numberInsurance');
            let flightIns = selectElement.value;
            const selectedOption = selectElement.options[selectElement.selectedIndex];
            const optgroupElement = selectedOption.parentElement;
            const companyId = optgroupElement.getAttribute('id')
            console.log('Company name is : ' + companyId);
            if(flightIns === ''){
                alert('Please select a flight.');
            }else if(insurePrice == 0){
                alert('Value must be greater than 0.');
            }else{
                let addressAirline = findKeyByValue(contract.airlinesNames, companyId);
                // console.log('airline address is : ' + addressAirline);
                // displayFlightsInsured('Flight Insurance ', 'Insurance', [ { label: 'Flight insured', value: flightIns + ' - for ' + insurePrice + ' ether'} ]);
                if(!arrayFlight_Insured.hasOwnProperty(custWant_FlightInsured)){
                    arrayFlight_Insured[custWant_FlightInsured] = {};
                }
                arrayFlight_Insured[custWant_FlightInsured][flightIns] = insurePrice;
                const keys = Object.keys(arrayFlight_Insured);
                // contract.custInsuredOrNot(flightIns, custWant_FlightInsured).then(function(yesOrNo) {
                //     isInsured = yesOrNo;
                // });
                try{
                    contract.insureFlight(addressAirline, flightIns, custWant_FlightInsured, insurePrice, (error, result) => {
                        // display('Flight ', 'Insurance', [ { label: 'Flight insured', error: error, value: result.flightIns + ' ' + result.timestamp} ]);
                        display('Flight ', 'Insurance', [ { label: 'Flight insured', error: error, value: result + ' this was added ' + result} ]);
                    });
                    if(insurePrice > max_insurancePrice){
                        alert('Price input cannot be higher than ' + max_insurancePrice,toString() + ' ether');
                    // }else if(isInsured){
                    //     alert('You already purchased insurance on the flight.');
                    //     console.log('is already insured ? : ' + isInsured);
                    }else{
                        updateTable([custWant_FlightInsured.toString(),flightIns,insurePrice]);
                    }
                }catch{
                    // a = 2;
                    // alert('You already purchased insurance on the flight.');
                    // console.log('is already insured ? : ' + isInsured);
                }
                // contract.isAuth();
                
                // let a = contract.custInsuredOrNot(flightIns, custWant_FlightInsured);
                // console.log('is insured : '+ a)

            }
            // Write transaction
            
        })

        function updateTable(inputTable) { // addressCustomer,flightName,insurancePrice
            // creates a <table> element and a <tbody> element
            // const tbl = DOM.elid("showCustomer");
            const tblBody = DOM.elid("body");
            // creating all cells
            var lengthBdy = document.getElementById("body").rows.length;
            // for (let i = lengthBdy; i < 2; i++) {
              // creates a table row
              const row = document.createElement("tr");
              for (let j = 0; j < 3; j++) {
                // Create a <td> element and a text node, make the text node the contents of the <td>, and put the <td> at the end of the table row
                const cell = document.createElement("td");
                // const cellText = document.createTextNode(`cell in row ${i}, column ${j}`);
                const cellText = document.createTextNode(inputTable[j]);
                cell.appendChild(cellText);
                row.appendChild(cell);
              }
              // add the row to the end of the table body
              tblBody.appendChild(row);
            // }
          }

        // User-submitted transaction - check status
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })

        DOM.elid('pay-customer').addEventListener('click', () => {
            // Write transaction
            contract.pay(custWant_FlightInsured, (error, result) => {
                display('Credit customer', 'Reimburse', [ { label: 'Reimburse for delayed flight', error: error, value: result.success + ' ' + result.fundPayout.toString()} ]);
            });
        })

        DOM.elid('creditValue').addEventListener('click', () => {
            // Write transaction
            contract.creditAmount(custWant_FlightInsured, (error, result) => {
                display('Credit amount', 'Value available', [ { label: 'Credit amount', error: error, value: result.toString()} ]);
            });
        })
    });
    
})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);
}

function displayFlightsInsured(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);
}