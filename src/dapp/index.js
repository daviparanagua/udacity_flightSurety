
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';

const flightsURL = 'http://localhost:3000/api/flights';
let updateInsuranceValue, updateMyBalance;


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            
            if(error) console.error(error);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
        // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
                setTimeout(updateInsuranceValue, 1000);
            });
        })

        // User-submitted transaction
        DOM.elid('buy-insurance').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
        // Write transaction
            contract.buyInsurance(flight, (error, result) => {
                if (error) return console.error(error)
                console.log('Bought insurance' + result);
                updateInsuranceValue();
            });
        })

        // Withdraw
        DOM.elid('btn-withdraw').addEventListener('click', () => {
            contract.withdrawFunds((error, result) => {
                if (error) return console.error(error)
                console.log('Withdrew funds');
                updateInsuranceValue();
            });
        })

        updateInsuranceValue = function updateInsuranceValue(){
                let flight = DOM.elid('flight-number').value;
                contract.getInsurance(flight, (error, result) => {
                    if (error) return console.error(error)
                    DOM.elid('insurance-amount').innerHTML = result / Math.pow(10, 18);
                    updateMyBalance();
            });
        }

        updateMyBalance = function updateMyBalance(){
            contract.getWithdrawBalance((error, result) => {
                if (error) return console.error(error)
                console.log(result);
                DOM.elid('withdraw-balance').innerHTML = result / Math.pow(10, 18);
            });
            contract.getMyBalance((error, result) => {
                if (error) return console.error(error)
                console.log(result);
                DOM.elid('my-balance').innerHTML = result / Math.pow(10, 18);
            });
    }

    

        initialize();

    });
    

})();

function updateFlights() {
    let displayDiv = DOM.elid("flight-number");

    fetch(flightsURL)
    .then((resp) => resp.json())
    .then(function(data) {
      let flights = data.flights;
      displayDiv.innerHTML = '';
      flights.forEach(function(flight) {
          const option = document.createElement('OPTION');
          option.innerText = `${flight.id}: ${flight.from} => ${flight.to}`;
          option.value = flight.id;
          displayDiv.appendChild(option);
      })
      updateInsuranceValue();
    })
    .catch(function(error) {
      console.log(error);
    });
}

function initialize()  {
    updateFlights();
    const selectElement = document.querySelector('#flight-number');

    selectElement.addEventListener('change', (event) => {
        updateInsuranceValue();
    });
};

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







