import "../stylesheets/app.css";
import "../stylesheets/buttons.css";
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
   },
   getUserList: async function()
   {
      //清空表格信息
	  var table = document.getElementById("tauserlist");
      var tBody = table.tBodies[0];
      tBody.parentNode.outerHTML = tBody.parentNode.outerHTML.replace(tBody.innerHTML, "");

      console.log(admin_instance);
      //获取用户数量
      var amount = await admin_instance.getUserAmount.call();
      console.log("用户数量:"+amount);
      //显示用户信息
      for (var index = 1; index < amount; index++)
      {
        var ret = await admin_instance.getSheetFunds.call(index);
        var id = ret[0];
        var external_addr = ret[1];
        var total_sheet = ret[2];
        var avail_sheet = ret[3];
        var frozen_sheet = ret[4];
        var total_funds = ret[5];
        var avail_funds = ret[6];
        var frozen_funds = ret[7];
        console.log("UserID:"+id);
        console.log("账户地址:"+external_addr);
        console.log("仓单总量:"+total_sheet);
        console.log("可用量:"+avail_sheet);
        console.log("冻结量:"+frozen_sheet);
        console.log("资金总量:"+total_funds);
        console.log("资金可用量:"+avail_funds);
        console.log("资金冻结量:"+frozen_funds);
      	App.addUserList(id, external_addr, total_sheet, avail_sheet, frozen_sheet, total_funds, frozen_funds, avail_funds);
      }
   },
   addUserList: function(id, external_addr, total_sheet, avail_sheet, frozen_sheet, total_funds, frozen_funds, avail_funds)
   {
       //获取table对象
       var table = document.getElementById("tauserlist");
       var tr = document.createElement('tr');
       var td_id = document.createElement('td');
       td_id.innerHTML = id;
       tr.appendChild(td_id);

       var td_external_addr = document.createElement('td');
       td_external_addr.setAttribute("style","word-break:break-all; word-wrap:break-all");
       td_external_addr.innerHTML = external_addr;
       tr.appendChild(td_external_addr);

       var td_total_sheet = document.createElement('td');
       td_total_sheet.innerHTML = total_sheet;
       tr.appendChild(td_total_sheet);

       var td_frozen_sheet = document.createElement('td');
       td_frozen_sheet.innerHTML = frozen_sheet;
       tr.appendChild(td_frozen_sheet);
       
       var td_avail_sheet = document.createElement('td');
       td_avail_sheet.innerHTML = avail_sheet;
       tr.appendChild(td_avail_sheet);

       var td_total_funds = document.createElement('td');
       td_total_funds.innerHTML = total_funds/100;
       tr.appendChild(td_total_funds);

       var td_frozen_funds = document.createElement('td');
       td_frozen_funds.innerHTML = frozen_funds;
       tr.appendChild(td_frozen_funds);

       var td_avail_funds = document.createElement("td");
       td_avail_funds.innerHTML = avail_funds/100;
       tr.appendChild(td_avail_funds);
       
       //仓单详情
       var td_detail = document.createElement('td');
       var detail_btn = document.createElement("input");
       detail_btn.type = "button";
       detail_btn.value = "详情";
       detail_btn.className="del_btn";
       detail_btn.onclick = async function(){
                                //遍历用户的仓单
                                App.detailList(id);
       };
       td_detail.appendChild(detail_btn);
       tr.appendChild(td_detail);
       
       //操作
       var td_opt = document.createElement('td');
       var del_btn = document.createElement("button");
       var edit_btn = document.createElement("button");
       var save_btn = document.createElement("button");
       var li_remove = document.createElement("li");
       var li_edit = document.createElement("li");
       var li_save = document.createElement("li");

       li_remove.className="fa fa-remove";
       li_edit.className="fa fa-edit";
       li_save.className="fa fa-save";
       
       del_btn.appendChild(li_remove);
       del_btn.onclick= async function(){
								  console.log(id);
								  await admin_instance.delUser.sendTransaction(id,{from:account});	
								  //删除
								  var row = td_opt.parentNode.rowIndex;
								  document.getElementById("tauserlist").deleteRow(row);
					   			};
       edit_btn.appendChild(li_edit);
       edit_btn.onclick = function(){App.update(this);};
       save_btn.appendChild(li_save);
       save_btn.onclick= async function(){
            
                            }

       td_opt.appendChild(del_btn);
       td_opt.appendChild(edit_btn);
       td_opt.appendChild(save_btn);
       tr.appendChild(td_opt);

       table.tBodies[0].appendChild(tr);
       
   },
   //修改资金
   update: function(btn)
   {
        //设置btn保存按钮
       btn.className = undefined; 
       btn.className = "fa fa-save";
        //var tr = btn.parentNode.parentNode;
       // console.log(tr);
   },
   //查看用户仓单详情
   detailList: async function(id)
   {
        var ascii_userid = web3.fromAscii(id);
        console.log("查看仓单详情");
        //清空表格信息
	    var table = document.getElementById("tadetail");
        var tBody = table.tBodies[0];
        tBody.parentNode.outerHTML = tBody.parentNode.outerHTML.replace(tBody.innerHTML, "");
        //仓单种类数
        var kinds = await admin_instance.getSheetMapSize.call();
        console.log("仓单种类数:"+kinds);
        for (var index = 0; index < kinds; index++)
        {
            var ret = await admin_instance.getSheetInfo.call(ascii_userid,index);
            var sheet_id = ret[0];//仓单号
            var class_id = ret[1];//品种
            var make_date = ret[2];//产期
            var lev_id = ret[3];//等级
            var whe_id = ret[4];//产地
            var place_id = ret[5];//仓库
            
            ret = await admin_instance.getSheetAmount.call(id, index);
            var all_amount = ret[0];
            var avail_amount = ret[1];
            var frozen_amount = ret[2];
            App.addDetailList(class_id, sheet_id, whe_id, place_id, make_date, lev_id, all_amount, frozen_amount, avail_amount);
        }
   },
   //tadetail增加仓单详情
   addDetailList: function(class_id, sheet_id, whe_id, place_id, make_date, lev_id, all_amount, frozen_amount, avail_amount)
   {
       var table = document.getElementById("tadetail");
       var tr = document.createElement('tr');
       
       var td_class_id = document.createElement('td');
       td_class_id.innerHTML = class_id;
       tr.appendChild(td_class_id);

       var td_sheet_id = document.createElement('td');
       td_sheet_id.innerHTML = sheet_id;
       tr.appendChild(td_sheet_id);
       
       var td_whe_id = document.createElement('td');
       td_whe_id.innerHTML = whe_id;
       tr.appendChild(td_whe_id);

       var td_place_id = document.createElement('td');
       td_place_id.innerHTML = place_id;
       tr.appendChild(td_place_id);

       var td_make_date = document.createElement('td');
       td_make_date.innerHTML = make_date;
       tr.appendChild(td_make_date);

       var td_lev_id = document.createElement('td');
       td_lev_id.innerHTML = lev_id;
       tr.appendChild(td_lev_id);

       var td_all_amount = document.createElement('td');
       td_all_amount.innerHTML = all_amount;
       tr.appendChild(td_all_amount);

       var td_frozen_amount = document.createElement('td');
       td_frozen_amount.innerHTML = frozen_amount;
       tr.appendChild(td_frozen_amount);

       var td_avail_amount = document.createElement('td');
       td_avail_amount.innerHTML = avail_amount;
       tr.appendChild(td_avail_amount);

       table.tBodies[0].appendChild(tr);
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
