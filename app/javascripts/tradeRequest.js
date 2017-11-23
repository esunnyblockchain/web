import "../stylesheets/app.css";
import "../stylesheets/buttons.css";
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract';
// Import our contract artifacts and turn them into usable abstractions.
import Admin_artifacts from '../../smartcontract/build/contracts/Admin.json';
var Admin = contract(Admin_artifacts);
let account;
let admin_instance;

window.App={
    
    init: async function()
    {
        Admin.setProvider(web3.currentProvider);
        admin_instance = await Admin.deployed();
        console.log("admin addr:"+admin_instance.address);
        account = await web3.eth.accounts[0];
        console.log("account addr:"+account); 
    },
}
    
window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn("Using MetaMask web3")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected.");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://192.168.22.123:8545"));
  }
  App.init();
});
