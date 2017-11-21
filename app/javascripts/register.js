import "../stylesheets/app.css";
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import Admin_artifacts from '../../smartcontract/build/contracts/Admin.json'
var Admin = contract(Admin_artifacts);
let account;
let admin_instance;
var str=location.href;//取地址参数部分
window.App ={
    init: async function()
    {
        Admin.setProvider(web3.currentProvider);
        var addr  = location.href.split("?")[1].split("=")[1];
        admin_instance = await Admin.deployed();
        console.log("admin addr:"+admin_instance.address);
        account = await web3.eth.accounts[0];
        console.log("account addr:"+account); 
        if(addr != admin_instance.address) 
            console.log("you are not a admin");
        else
            console.log("you are a admin");
    },
    /*
    addUser: async function()
    {
        let user_id = document.getElementById("userid").value;
        let user_addr = document.getElementById("useraddr").value;
        console.log("user_addr:"+user_addr);
        console.log("user_id:"+user_id);
        await admin_instance.addUser.sendTransaction(user_addr,user_id,{from:account});
    },
    */
    addUser: async function()
    {
        var self = this;
        var user_addr = document.getElementById("useraddr").value;
        var user_id = document.getElementById("userid").value; 
        var funds = parseInt(document.getElementById("funds").value);

        //登记到userlist
        console.log("account addr:"+account); 
        //录入用户仓单
        await admin_instance.addUser.sendTransaction(user_id, user_addr, funds,{from:account});
   },

   insertSheet: async function()
   {
        
        var user_id = document.getElementById("userid").value;

        var class_id = document.getElementById("classid").value;
        var ascii_class_id = web3.fromAscii(class_id);
        console.log("asscii_class_id:"+ascii_class_id);
    
        var make_date = document.getElementById("makeDate").value;
        var ascii_make_date = web3.fromAscii(make_date);
        console.log("ascii_make_date:"+ascii_make_date);

        var lev_id = document.getElementById("levelid").value;
        var ascii_lev_id = web3.fromAscii(lev_id);
        console.log("asscii_lev_id:"+ascii_lev_id);

        var whe_id = document.getElementById("wheid").value;
        var ascii_whe_id = web3.fromAscii(whe_id);
        console.log("ascii_whe_id:"+ascii_whe_id);

        var place_id = document.getElementById("placeID").value; 
        var ascii_palce_id = web3.fromAscii(place_id);
        console.log("ascii_palce_id:"+ascii_palce_id);

        var all_amount = parseInt(document.getElementById("receiptamount").value);
        var frozen_amount = parseInt(document.getElementById("frozenamount").value);
        var available_amount = parseInt(document.getElementById("availableamount").value);
        console.log(all_amount);

        await admin_instance.insertSheet.sendTransaction(user_id, ascii_class_id, ascii_make_date, ascii_lev_id, ascii_whe_id, ascii_palce_id, all_amount, frozen_amount, available_amount,{from:account});
   }
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
