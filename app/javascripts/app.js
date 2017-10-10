// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/app.css";

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import User_artifacts from '../../build/contracts/User.json'

// User is our usable abstraction, which we'll use through the code below.
var User = contract(User_artifacts);

// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;

window.App = {
  start: function() {
    var self = this;

    // Bootstrap the User abstraction for Use.
    User.setProvider(web3.currentProvider);
    console.log(web3.currentProvider);

    // Get the initial account balance so it can be displayed.
    web3.eth.getAccounts(function(err, accs) {
      if (err != null) {
        alert("There was an error fetching your accounts.");
        return;
      }

      if (accs.length == 0) {
        alert("Couldn't get any accounts! Make sure your Ethereum client is configured correctly.");
        return;
      }

      accounts = accs;
      account = accounts[0];

   //   self.refreshBalance();
    });
  },

  setStatus: function(message) {
    var status = document.getElementById("status");
    status.innerHTML = message;
  },


  createReceipt: function(){
    var self = this;
    var user_id = document.getElementById("userid").value;
    var sheet_id = parseInt(document.getElementById("sheetid").value);
    var class_id = document.getElementById("classid").value;
    var make_date = document.getElementById("makeDate").value;
    var lev_id = document.getElementById("levelid").value;
    var whe_id = document.getElementById("wheid").value;
    var place_id = document.getElementById("placeID").value; 
    var receipt_amount = parseInt(document.getElementById("receiptamount").value);
    var frozen_amount = parseInt(document.getElementById("frozenamount").value);
    var available_amount = parseInt(document.getElementById("availableamount").value);
    var meta;
    console.log(receipt_amount);

    User.deployed().then(function(instance){
        console.log(instance);
        meta = instance;
        meta.insertSheet.sendTransaction(user_id, sheet_id,class_id, make_date, lev_id, whe_id, place_id, receipt_amount,frozen_amount,available_amount,{from:account, gas:70000000}).then(function(){
            meta.getSheetAmount.call(sheet_id).then(function(ret){self.setStatus('Receipt Amount:'+ret.toString());});
        });
    });
  }
  
};

window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  
  if (typeof web3 !== 'undefined') {
    console.log('out string:');
    console.log(web3);

    console.warn("Using web3 detected from external source. If you find that your accounts don't appear or you have 0 MetaCoin, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
//    window.web3 = new Web3(new Web3.providers.HttpProvider("http://192.168.22.47:8545"));
  } else {
    console.warn("No web3 detected. Falling back to http://localhost:8545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://192.168.22.123:8545"));
  }
  App.start();
});
