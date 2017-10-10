// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/market.css";
// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import CreateID_artifacts from '../../build/contracts/CreateID.json'
// CreateID is our usable abstraction, which we'll use through the code below.
var CreateID = contract(CreateID_artifacts);

// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;
let rowseq;
window.App = {
  start: function() {
    var self = this;
    // Bootstrap the User abstraction for Use.
    CreateID.setProvider(web3.currentProvider);
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
	addTr: function(){
  //获取table实例
  var table = document.getElementById("addRow");
  //定义行元素
  var tr = document.createElement('tr');
  //插入index
  var td_index = document.createElement('td');
  td_index.innerHTML = rowseq++;
  td_index.setAttribute("text-align", "center");
  tr.appendChild(td_index);

  //插入date
  var td_date = document.createElement('td');
  var now = new Date();
  var year = now.getFullYear();
  var month = now.getMonth();
  var day = now.getDate();
  var time = year;
  if(month < 10)
  	time += "0";
  time +=month;
  if (day < 10)
  	time += "0";
  time += day;
  td_date.innerHTML = time;
  tr.appendChild(td_date);

  //插入list_id
  var td_list_id = document.createElement('td');
  td_list_id.innerHTML = list_id;
  tr.appendChild(td_list_id);

  //插入 sheet_id
  var td_sheet_id = document.createElement('td');
  td_sheet_id.innerHTML = sheet_id;
  tr.appendChild(td_sheet_id);

  //插入class_id
  var td_class_id = document.createElement('td');
  td_class_id.innerHTML = class_id;
  tr.appendChild(td_class_id);

  //插入mkdate
  var td_mkdate = document.createElement('td');
  td_mkdate.innerHTML = mkdate;
  tr.appendChild(td_mkdate);

  //插入lev
  var td_lev = document.createElement('td');
  td_lev.innerHTML = lev;
  tr.appendChild(td_lev);

  //插入whe_id
  var td_whe_id = document.createElement('td');
  td_whe_id.innerHTML = whe_id;
  tr.appendChild(td_whe_id);

  //插入place_id
  var td_place_id = document.createElement('td');
  td_place_id.innerHTML = place_id;
  tr.appendChild(td_place_id);

  //插入price_type
  var td_price_type = document.createElement('td');
  td_price_type.innerHTML= price_type;
  tr.appendChild(td_price_type);

  //掺入price
  var td_price = document.createElement('td');
  td_price.innerHTML = price;
  tr.appendChild(td_price);

  //插入list_qty
  var td_list_qty = document.createElement('td');
  td_list_qty.innerHTML = list_qty;
  tr.appendChild(td_list_qty);

  //插入deal_qty
  var td_deal_qty = document.createElement('td');
  td_deal_qty.innerHTML = deal_qty;
  tr.appendChild(td_deal_qty);

  //插入rem_qty
  var td_rem_qty = document.createElement('td');
  td_rem_qty.innerHTML = rem_qty;
  tr .appendChild(td_rem_qty);

  //插入dealine
  var td_deadline = document.createElement('td');
  td_deadline.innerHTML = deadline;
  tr.appendChild(td_deadline);

  //插入dlv_uint
  var td_dlv_uint = document.createElement('td');
  td_dlv_uint.innerHTML = dlv_uint;
  tr.appendChild(td_dlv_uint);
  table.tBodies[0].appendChild(tr);
  }	
};

window.addEventListener('load', function() {
    rowseq = 0;
    console.log("load !!!");
	rowseq = document.getElementById("addRow").tBodies[0].rows.length + 1; 
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

