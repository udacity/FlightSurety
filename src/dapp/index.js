
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('register-airline').addEventListener('click', async() => {
            let airline = DOM.elid('registered-airline').value;
            let name = DOM.elid('registered-name').value;

            //register airline
            contract.registerAirline(airline, name, (error, result) => {
                display('Airlines', 'register airlines', [{label: 'airline registered', error: error, value:result.airlineAddress + ' : ' +  result.name}]);
            });

        })
    
        DOM.elid('fund-airline').addEventListener('click', async() => {
            let airline = DOM.elid('chosen-airline-to-fund').value;
            let fund = DOM.elid('fund').value;

            //register airline
            contract.fund(airline, fund, (error, result) => {
                display('Airlines', 'fund airlines', [{label: 'fund airlines', error: error, value:result.airlineAddress + ' : ' +  result.fund + ' : ' +  result.sum.toString()}]);
            });

        })

        DOM.elid('register-flight').addEventListener('click', async() => {
            let flight = DOM.elid('flight-number').value;
            let airline = DOM.elid('airline-address').value;

            //register airline
            contract.registerFlight(airline, flight, (error, result) => {
                display('Flights', 'register flight', [{label: 'register flight', error: error, value:result.airlineAddress + ' : ' +  result.flight}]);
            });

        })

        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
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







