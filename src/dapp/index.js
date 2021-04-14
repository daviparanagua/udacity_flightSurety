
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';

const flightsURL = 'http://localhost:3000/api/flights';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
        // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })
    
    });
    

})();


function updateFlights() {
    let displayDiv = DOM.elid("flight-number");

    fetch(flightsURL)
    .then((resp) => resp.json())
    .then(function(data) {
      let flights = data.flights;
      displayDiv.innerHTML = '';
      return flights.map(function(flight) {
          const option = document.createElement('OPTION');
          option.innerText = `${flight.number}: ${flight.from} => ${flight.to}`;
          option.value = flight.number;
          displayDiv.appendChild(option);
        console.log(flight);
      })
    })
    .catch(function(error) {
      console.log(error);
    });

    
    console.log(flights);

}

window.addEventListener('DOMContentLoaded', updateFlights);

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







