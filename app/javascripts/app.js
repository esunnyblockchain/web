// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/app.css";

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import User_artifacts from '../../smartcontract/build/contracts/User.json'
import ContractAddress_artifacts from '../../smartcontract/build/contracts/ContractAddress.json'
import UserList_artifacts from '../../smartcontract/build/contracts/UserList.json'
import Market_artifacts  from '../../smartcontract/build/contracts/Market.json'
import CreateID_artifacts from '../../smartcontract/build/contracts/CreateID.json'

// User is our usable abstraction, which we'll use through the code below.
var User = contract(User_artifacts);
var ContractAddress = contract(ContractAddress_artifacts);
var UserList = contract(UserList_artifacts);
var Market = contract(Market_artifacts);
var CreateID = contract(CreateID_artifacts);

// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;

var user_addr;
var contract_addr;
var market_addr;
var userList_addr;
var createID_addr;

//获取contractAddr实例
var meta_user;
var meta_contractAddr;
var meta_market;
var meta_userList;
var meta_createID


window.App = {
  init: async function(){
    User.setProvider(web3.currentProvider);
    CreateID.setProvider(web3.currentProvider);
    UserList.setProvider(web3.currentProvider);
    ContractAddress.setProvider(web3.currentProvider);
    //获取合约地址
    Market.setProvider(web3.currentProvider);
    
    meta_market = await Market.deployed();
    market_addr = meta_market.address;
    await meta_market.setCreateIDName.sendTransaction("CreateID",{from:account, gas:300000});
    await meta_market.setUserListName.sendTransaction("UserList",{from:account, gas:300000});  
        
    meta_createID = await CreateID.deployed();
    createID_addr = meta_createID.address;
        
    //DEBUG:marketID是否初始化
    var ret = await meta_createID.getMarketID.call();
    console.log("marketID:"+ret);
   
    meta_userList = await UserList.deployed();
    userList_addr = meta_userList.address;   
    console.log("userList:"+userList_addr);
    
    meta_contractAddr = await ContractAddress.deployed();
    contract_addr = meta_contractAddr.address;
    
    //debug
    console.log("contract_addr:"+contract_addr);
    console.log("createID_addr:"+createID_addr); 
    console.log("market_addr:"+market_addr);
    console.log("userList_addr:"+userList_addr);
    //记录合约地址
    await meta_contractAddr.setContractAddress.sendTransaction("Market", market_addr,{from:account, gas:300000});
    await meta_contractAddr.setContractAddress.sendTransaction("CreateID", createID_addr,{from:account, gas:300000});
    await meta_contractAddr.setContractAddress.sendTransaction("UserList", userList_addr,{from:account, gas:300000});
       
    //Market设置合约地址 
    await meta_market.setContractAddress.sendTransaction(contract_addr,{from:account, gas:300000});
  },
  
  start: function() {
    var self = this;

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


  createReceipt: async function(){
    var self = this;
    var user_id = document.getElementById("userid").value;

    var class_id = document.getElementById("classid").value;
    var asscii_class_id = web3.fromAscii(class_id);
    console.log("asscii_class_id:"+asscii_class_id);
    
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

    var receipt_amount = parseInt(document.getElementById("receiptamount").value);
    var frozen_amount = parseInt(document.getElementById("frozenamount").value);
    var available_amount = parseInt(document.getElementById("availableamount").value);
    console.log(receipt_amount);

    meta_user = await User.new({from:account,gas:7000000});
    user_addr = meta_user.address;
    console.log("new user_addr:"+user_addr);
    //关联合约Map地址
    await meta_user.setContractAddress.sendTransaction(contract_addr, {from:account,gas:300000});
    // 登记MarketName, CreateIDName,UserListName,UserID
    await meta_user.setMarketName.sendTransaction("Market", {from:account, gas:300000});
    await meta_user.setCreateIDName.sendTransaction("CreateID", {from:account,gas:300000});
    await meta_user.setUserListName.sendTransaction("UserList", {from:account, gas:300000});
    await meta_user.setUserID.sendTransaction(user_id,{from:account, gas:300000});

    //登记到userlist
    await meta_userList.addUser.sendTransaction(user_addr, user_addr,user_id,1,{from:account, gas:300000});
    //录入用户仓单
    await meta_user.insertSheet.sendTransaction(user_id, asscii_class_id, ascii_make_date,  ascii_lev_id, ascii_whe_id, ascii_palce_id, receipt_amount,frozen_amount,available_amount,{from:account, gas:70000000});

    var ret = await meta_createID.getSheetID.call();
    var id = ret - 1;
    console.log("InserSheet sheet_id:"+id);
    ret = await meta_user.getSheetAmount.call(id);
    self.setStatus('Receipt Amount:'+ret[0]+',Avaliable_amount:'+ret[1]+',Frozen_amount:'+ret[2]);
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
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://192.168.22.123:8545"));
  } else {
    console.warn("No web3 detected. Falling back to http://localhost:8545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://192.168.22.123:8545"));
  }
  App.start();
  App.init();
});
