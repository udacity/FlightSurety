
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    const wait = (ms) => {
        return new Promise(resolve => setTimeout(resolve,ms));
    }
    let result = null;
    let airlines = [];
    let flight = null;
    let departure = null;

    let status_codes = {
        0: "UNKNOWN",
        10: "ON TIME",
        20: "LATE AIRLINE",
        30: "LATE WEATHER",
        40: "LATE TECHNICAL",
        50: "LATE OTHER"
    };

    let contract = new Contract("localhost", () => {

        // Read transaction
        contract.isOperational((error, result) => {
            displayOperationalStatus([{
                    label: 'Operational Status',
                    error: error,
                    value: result
                }]);
        });

        // Fetch Status
        let ddl = document.getElementById("flight-number");
        ddl.length = 0;
        fetch("http://localhost:3000/flights")
            .then(function(data){
                if(data.status !== 200) {
                    console.warn(`[REQ-STATUS]: ${data.status}`);
                    return;
                }

                data.json()
                    .then(
                        function(content) {
                            let opt;
                            content = content.result;
                            for(let i = 0; i < content.length; i+=1){
                                opt = document.createElement("option");
                                opt.text = content[i].name;
                                opt.value = content[i].name;
                                ddl.add(opt);
                            }
                        })
                    .catch(
                        function(error){
                            console.error(`[REQ-DATA]: ${error}`);
                        });
            })
            .catch(function(error){
                console.error(`[REQ-FETCH]: ${error}`);
        });

        // User-submitted transaction
        DOM.elid("submit-oracle").addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [
                    {
                        label: 'Fetch Flight Status',
                        error: error,
                        value: result.flight + ' ' + result.timestamp
                    }
                ]);
            });
        });

        // Oracles Response
        DOM.elid("oracle-response").addEventListener('click', () => {
            wait(300).then(() => {
                let line = airlines;
                let name = flight;
                let stamp = departure;
                let index = DOM.elid("holdIndex").innerHTML;

                contract.submitOracleResponse(parseInt(index), line, flight, stamp, (error,result) => {
                    console.log(`[REQ-OS]: index = ${index}`);

                    DOM.elid("oracle-response").style.display="none";
                    DOM.elid("table-results").style.display="block";
                    DOM.elid("status-code").innerHTML = status_codes[result.statusCode];
                    DOM.elid("flight-name").innerHTML = result.flight;
                    DOM.elid("timestamp").innerHTML = result.timestamp;

                    if(result.statusCode === 20 || result.statusCode === 40){
                        DOM.elid("amount").innerHTML = DOM.elid('delay').innerHTML;
                        DOM.elid("withdraw-funds").style.display = "block";
                    }else{
                        DOM.elid("amount").innerHTML = "0";
                    }
                });
            });
        });

        // Listen for changes.
        DOM.elid("insurance").addEventListener('change', () => {
            let insurance = DOM.elid("insurance").value;
            let delay = document.getElementById("delay");
            let premium = document.getElementById("premium");
            premium.innerHTML = insurance + " ether";
            delay.innerHTML = (insurance * 1.5) + " ether" ;
        });

        // Listen to pay event
        DOM.elid("pay").addEventListener('click', () => {
            let price = DOM.elid("insurance").value;
            let name = DOM.elid("flightName").innerHTML;
            let date = DOM.elid("flightDate").innerHTML;

            contract.buy(price, (error, result)=> {
                console.log("Insurance purchased with", price);
                display("Oracles", "Trigger oracles", [
                    {
                        label: "Assurance Detail",
                        error: error,
                        value: `Flight Name: ${name} | Departure Date: ${date} | Assurance Paid: ${price} ether | Paid on Delay: ${price * 1.5} ether`
                    }
                ],"display-flight", "display-detail");
            });
        });

        // Passenger withdraw funds
        DOM.elid("withdraw-funds").addEventListener("click", () => {
            contract.withdraw((error, result) => {
                DOM.elid("withdraw-funds").style.display = "none";
                DOM.elid("table-report").style.display = "none";
                DOM.elid("withdrawn-value").innerHTML = DOM.elid("delay").innerHTML;
                DOM.elid("withdrawn").style.display = "block";

                console.log("Great Success.");
            });

        })
    });
    

})();

/**
 * TODO: Document
 * @param title
 * @param description
 * @param results
 */
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

/**
 * Displays the contracts current operational status.
 * @param results
 */
function displayOperationalStatus(results){
    let opCircle = DOM.elid("operational-status");
    results.map((result) => {
        opCircle.classList.add(result.error !== null ? "red" : result.value ? "green" : "red");
    });
}

/**
 * TODO: Document
 */
function getOracleIndex() {
    fetch("http://localhost:3000/eventIndex")
        .then(function(data){
            if(data.status !== 200){
                console.warn(`[REQ-INDEX]: ${data.status}`);
                return;
            }

            data.json().then(function(content){
                let p = document.getElementById('holdIndex');
                content = content.result;
                p.innerHtml = parseInt(content);
            });
        })
        .catch(function(error){
            console.error(error);
        });
}







