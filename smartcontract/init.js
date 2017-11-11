//可配置
var god_account= "0x4c34655804601ee05028726a7e0b5669b52b25a3"; //root
var admin_extern_addr = "0x4c34655804601ee05028726a7e0b5669b52b25a3";

//不要改动
var market_name ="Market";
var create_id_name ="CreateID";
var user_list_name ="UserList";
var admin_name ="Admin";

// Step 1: Get a contract into my application
var UserList_json           = require("./build/contracts/UserList.json");
var ContractAddress_json    = require("./build/contracts/ContractAddress.json");
var Market_json             = require("./build/contracts/Market.json");
var CreateID_json           = require("./build/contracts/CreateID.json");
var Login_json              = require("./build/contracts/Login.json");
var Admin_json              = require("./build/contracts/Admin.json");
var Proxy_json              = require("./build/contracts/Proxy.json");

var Web3                    = require('web3');

// Step 2: Turn that contract into an abstraction I can use
var contract        = require("truffle-contract");
var UserList        = contract(UserList_json);
var ContractAddress = contract(ContractAddress_json);
var Market          = contract(Market_json);
var CreateID        = contract(CreateID_json);
var Login           = contract(Login_json);
var Admin           = contract(Admin_json);
var Proxy           = contract(Proxy_json);

// Step 3: Provision the contract with a web3 provider
var web3 = new Web3.providers.HttpProvider("http://192.168.22.123:8545");
UserList.setProvider(web3);
ContractAddress.setProvider(web3);
Market.setProvider(web3);
CreateID.setProvider(web3);
Login.setProvider(web3);
Admin.setProvider(web3);
Proxy.setProvider(web3);

// Step 4: Use the contract!
let UserList_instance;
let ContractAddress_instance;
let Market_instance;
let CreateID_instance;
let Login_instance;
let Admin_instance;
let Proxy_instance;

async function initAddress()
{
   console.log("Start:获取系统合约的地址....");
   UserList_instance = await UserList.deployed(); 
   console.log("\tUserList Address:"+UserList_instance.address);
   ContractAddress_instance = await ContractAddress.deployed(); 
   console.log("\tContractAddress Address:"+ContractAddress_instance.address);
   Market_instance = await Market.deployed(); 
   console.log("\tMarket Address:"+Market_instance.address);
   CreateID_instance = await CreateID.deployed(); 
   console.log("\tCreateID Address:"+CreateID_instance.address);
   Login_instance = await Login.deployed(); 
   console.log("\tLogin Address:"+Login_instance.address);
   Admin_instance = await Admin.deployed(); 
   console.log("\tAdmin Address:"+Admin_instance.address);
   Proxy_instance = await Proxy.deployed(); 
   console.log("\tProxy Address:"+Proxy_instance.address);
   console.log("End:...获取系统合约地址结束");
   
}
async function setDep()
{
    console.log("Start:设置合约依赖关系....");
    console.log("\t设置ContractAddress合约");
    await ContractAddress_instance.setContractAddress.sendTransaction(market_name,Market_instance.address,{from:god_account});
    await ContractAddress_instance.setContractAddress.sendTransaction(create_id_name,CreateID_instance.address,{from:god_account});
    await ContractAddress_instance.setContractAddress.sendTransaction(user_list_name,UserList_instance.address,{from:god_account});
    await ContractAddress_instance.setContractAddress.sendTransaction(admin_name,Admin_instance.address,{from:god_account});

    console.log("\t设置Market合约");
    await Market_instance.setContractAddress.sendTransaction(ContractAddress_instance.address,{from:god_account});
    await Market_instance.setCreateIDName.sendTransaction(create_id_name,{from:god_account});
    await Market_instance.setUserListName.sendTransaction(user_list_name,{from:god_account});

    console.log("\t设置Login合约");
    await Login_instance.init.sendTransaction(ContractAddress_instance.address,user_list_name,{from:god_account});

    console.log("\t设置Admin合约");
    await Admin_instance.init.sendTransaction(ContractAddress_instance.address,user_list_name,{from:god_account,gas:9999999});
    
    console.log("\t设置Proxy合约");
    await Proxy_instance.init.sendTransaction(ContractAddress_instance.address,{from:god_account,gas:9999999});
    console.log("End:...设置合约依赖关系完毕");
}
async function setAdminExternAddr()
{
    console.log("Start:设置Admin合约外部账户地址....");
    await UserList_instance.addUser.sendTransaction(admin_extern_addr,Admin_instance.address,admin_name,"5",{from:god_account,gas:9999999});
    console.log("\tAdmin合约的外部账户地址:"+admin_extern_addr);
    console.log("End:...设置Admin合约外部账户地址完毕");
}
initAddress().then( async function(){
    await setDep();
    await setAdminExternAddr();
});
