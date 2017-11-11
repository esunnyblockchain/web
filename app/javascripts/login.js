import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import Login_artifacts from '../../smartcontract/build/contracts/Login.json'
let login_instance;
let account;
window.App ={
    init: async function()
    {
        let Login = contract(Login_artifacts);
        Login.setProvider(web3.currentProvider);
        login_instance = await Login.deployed();
        account = web3.eth.accounts[0];
        console.log("login addr:"+login_instance.address);
        console.log("account addr:"+account);
    },
    login: async function()
    {
        let login_name = document.getElementById("loginid").value;
        let ret = await login_instance.verfication.call(login_name,account,{from:account});
        console.log("error_no 0:"+ret[0]); //错误码
        console.log("who:"+ret[1]); //身份
        console.log("addr:"+ret[2]); //地址
        if(ret[0] == 0)
        {
            if(ret[1] == 5)
            {
                    var link ="adminUser.html?addr="+ret[2];
                    window.location.href=link;
            }
            else if(ret[1] == 1)
            {
                    var link ="market.html?addr="+login_name;
                    window.location.href=link;
            }
        }
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
