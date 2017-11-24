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

    doingRequest: async function()
    {
        document.getElementById("doing").style.display="block";
		document.getElementById("done").style.display="none";  
		//每次点击都会清空tbody
		var table = document.getElementById("tadoing");
		var tBody = table.tBodies[0];
		tBody.parentNode.outerHTML = tBody.parentNode.outerHTML.replace(tBody.innerHTML, "");
		var num = await admin_instance.getConfirmListReqSize.call();
        console.log("挂牌交易请求:"+num);
		for (var index = 0; index < num; index++)
		{
			var ret = await admin_instance.getConfirmListReq.call(index);
			var user_id = ret[0];
			var seller_id = ret[1];
			var trade_id = ret[2];
			var class_id = ret[3];
			var trade_qty = ret[4];
            var price = ret[5];
			var funds = ret[6];
			var fee = ret[7]/100;
			var state = ret[8];
			console.log("合同状态:"+state);
			if (!state)
        		App.addDoingRequest(trade_id, class_id, user_id, seller_id,fee,price, trade_qty, funds);
		}
    },

    doneRequest: async function()
    {
        document.getElementById("done").style.display="block";
        document.getElementById("doing").style.display="none";
		
        //每次点击都会清空tbody
		var table = document.getElementById("tadone");
		var tBody = table.tBodies[0];
		tBody.parentNode.outerHTML = tBody.parentNode.outerHTML.replace(tBody.innerHTML, "");
		var num = await admin_instance.getConfirmListReqSize.call();
        console.log("确认的挂牌交易请求:"+num);
		for (var index = 0; index < num; index++)
		{
			var ret = await admin_instance.getConfirmListReq.call(index);
			var user_id = ret[0];
			var seller_id = ret[1];
			var trade_id = ret[2];
			var class_id = ret[3];
			var trade_qty = ret[4];
            var price = ret[5];
			var funds = ret[6];
			var fee = ret[7]/100;
			var state = ret[8];
			console.log("合同状态:"+state);
			if (state)
        		App.addDoneRequest(trade_id, class_id, user_id, seller_id,fee,price, trade_qty, funds);
		}
    },

    addDoingRequest: function(trade_id, class_id, buyer_id, seller_id, fee, deal_price, deal_amount, price)
    {
		var table = document.getElementById("tadoing");
		var tr = document.createElement("tr");
		
		var td_trade_id =document.createElement("td");
		td_trade_id.innerHTML=trade_id;
		tr.appendChild(td_trade_id);

		var td_class_id = document.createElement("td");
		td_class_id.innerHTML=class_id;
		tr.appendChild(td_class_id);

		var td_buyer_id = document.createElement("td");
		td_buyer_id.innerHTML = buyer_id;
		tr.appendChild(td_buyer_id);

		var td_seller_id = document.createElement("td");
		td_seller_id.innerHTML = seller_id;
		tr.appendChild(td_seller_id);

		var td_fee = document.createElement("td");
		td_fee.innerHTML = fee;
		tr.appendChild(td_fee);

		var td_deal_price = document.createElement("td");
		td_deal_price.innerHTML = deal_price;
		tr.appendChild(td_deal_price);
		
		var td_deal_amount = document.createElement("td");
		td_deal_amount.innerHTML = deal_amount;
		tr.appendChild(td_deal_amount);
		
		var td_price = document.createElement("td");
		td_price.innerHTML = price;
		tr.appendChild(td_price);
		
		var td_opt = document.createElement("td"); 
		var agree_btn = document.createElement("button");
		var reject_btn = document.createElement("button");
		
		agree_btn.innerHTML="同意";
		reject_btn.innerHTML="拒绝";	
		
		agree_btn.onclick = async function()
								{
									await admin_instance.confirmList.sendTransaction(trade_id, {from:account});	
									//同意后删除该条请求
									var row = td_opt.parentNode.rowIndex;
									table.deleteRow(row);
								};
		reject_btn.onclick = async function(){};

		td_opt.appendChild(agree_btn);
		td_opt.appendChild(reject_btn);
		tr.appendChild(td_opt);
		
		table.tBodies[0].appendChild(tr);			
    },
    
    addDoneRequest: function(trade_id, class_id, buyer_id, seller_id, fee, deal_price, deal_amount, price)
    {
		var table = document.getElementById("tadone");
		var tr = document.createElement("tr");
		
		var td_trade_id =document.createElement("td");
		td_trade_id.innerHTML=trade_id;
		tr.appendChild(td_trade_id);

		var td_class_id = document.createElement("td");
		td_class_id.innerHTML=class_id;
		tr.appendChild(td_class_id);

		var td_buyer_id = document.createElement("td");
		td_buyer_id.innerHTML = buyer_id;
		tr.appendChild(td_buyer_id);

		var td_seller_id = document.createElement("td");
		td_seller_id.innerHTML = seller_id;
		tr.appendChild(td_seller_id);

		var td_fee = document.createElement("td");
		td_fee.innerHTML = fee;
		tr.appendChild(td_fee);

		var td_deal_price = document.createElement("td");
		td_deal_price.innerHTML = deal_price;
		tr.appendChild(td_deal_price);
		
		var td_deal_amount = document.createElement("td");
		td_deal_amount.innerHTML = deal_amount;
		tr.appendChild(td_deal_amount);
		
		var td_price = document.createElement("td");
		td_price.innerHTML = price;
		tr.appendChild(td_price);
		//合同状态
		var td_state = document.createElement("td"); 
        td_state.innerHTML="已交收";
		tr.appendChild(td_state);
		
		table.tBodies[0].appendChild(tr);			
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
