// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/market.css";
// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import User_artifacts from '../../smartcontract/build/contracts/User.json'
import UserList_artifacts from '../../smartcontract/build/contracts/UserList.json'
import Market_artifacts from '../../smartcontract/build/contracts/Market.json'

// User UserList Market ContractAddress is our usable abstraction, which we'll use through the code below.
var User = contract(User_artifacts);
var UserList = contract(UserList_artifacts);
var Market = contract(Market_artifacts);

// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;
let rowseq;

var user_instance;
var market_instance;
var userList_instance;

var local_market_id;//全局行情id

//防止重复点击按钮重复显示行情
var mutex_myReceipt = 0;
var mutex_myList = 0;
var mutex_myTrade = 0;
//第一次点击
var myListFirstClick = 0;
var myReceiptFirstClick = 0;

//市场行情更新操作
var opt_seq;
var have = 0;

window.App = {
  //<系统时间戳转为yyyymmdd
  transTimeStamp: function(time){
    var date = new Date(time*1000);
    var year = date.getFullYear();
    var month = date.getMonth()+1;
    console.log("month:"+month);
    var day = date.getDate();
    var yyyymmdd = year.toString();
    if(month < 10)
        yyyymmdd += "0";
    yyyymmdd +=month.toString();
    if (day < 10)
        yyyymmdd+= "0";
    yyyymmdd += day.toString();
    return yyyymmdd;
  },

  start: async function() {
    var self = this;
    User.setProvider(web3.currentProvider);
    UserList.setProvider(web3.currentProvider);
    Market.setProvider(web3.currentProvider);

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
    });
    
    //获取user合约地址
    userList_instance = await UserList.deployed();
    var user_id = "User";
    var ret = await userList_instance.getUserInfo.call(user_id);
    var user_addr = ret[1];
    console.log("From userList:"+user_id+ "user_addr"+user_addr.toString());
    user_instance = await User.at(user_addr);
    
    //获取marketID
    market_instance = await Market.deployed();
    local_market_id = await market_instance.getMarketID.call();
    console.log("Start local_market_id:"+local_market_id);
    
    //获取opt_seq
    var ret_seq  = await market_instance.get_opt_seq.call();
    console.log("!!!!Start get_opt_seq:"+ret_seq);
    opt_seq = ++ret_seq;
    console.log("!!!!Expect opt:"+opt_seq);

    await self.listMarket();
    setInterval(self.syncMaket,5000); 
  },

  //检查market_id改变时，进行同步
  syncMaket: async function(){
      var now_market_id = await market_instance.getMarketID.call();
      console.log("sync Now MarketID:"+now_market_id);
      console.log("sync local_market_id:"+local_market_id);
      if (now_market_id > local_market_id)
      {
        //market_id落后就同步
        //方案1
        //App.eventTrigger();
        //方案2 
        var ret_1 = await market_instance.getMarketStrByMarketID_1.call(local_market_id);
        var ret_2 = await market_instance.getMarketStrByMarketID_2.call(local_market_id);
        App.addTr(ret_1[0],ret_1[1],ret_1[2],ret_1[3],ret_1[4],ret_1[5], ret_1[6], ret_1[7],"yiloujia",ret_2[0],ret_2[1],ret_2[2],ret_2[3],ret_2[4],ret_2[5]);
        local_market_id++; 
      }
      App.updateList();
  },

  //更新市场行情
  updateList: async function(){
    //每次调用都会建立新的过滤器,在这里限制一下
    if(!have)
    {
        have++;
        var update_event = await market_instance.updateEvent({seq:opt_seq});
        await update_event.watch(function(error, result){
              if (!error)
              {
                console.log("同步在updateList:"+result.args.market_id+" amount:"+result.args.amount);
                var id = parseInt(result.args.market_id);
                var amount = parseInt(result.args.amount);
                App.updateTaMarketList(id ,amount);            
                //等待下一个事件
                opt_seq++;
              }
             update_event.stopWatching();
             have = 0;
         });
     }
  },

  //根据market_id更新行情表
  updateTaMarketList:function(market_id, amount){
      var table = document.getElementById("taMarketList");
      for (var i = 0; i < table.rows.length; i++)
      {
        //获取market_id;
         var id = parseInt(table.rows[i].cells[2].innerHTML);
         if (id == market_id)
         {
            //更新剩余量
            var rem_qty = parseInt(table.rows[i].cells[13].innerHTML);
            console.log("REM_QTY:"+rem_qty);
            rem_qty -= amount;
            if (!rem_qty)
            {
                table.deleteRow(i);
            }
            else
            {
                table.rows[i].cells[13].innerHTML = rem_qty;
                //更新成交量
                var deal_qty = parseInt(table.rows[i].cells[12].innerHTML);
                console.log("DEAL_QTY:"+deal_qty);
                var new_deal_qty = deal_qty + amount;
                console.log(typeof(amount));
                console.log("!!!!new_deal_qty:"+new_deal_qty);
                table.rows[i].cells[12].innerHTML = new_deal_qty;
            }
            break;
         }
      }
  },
 
  //显示市场行情
  listMarket: async function(){
      var self = this;
      //检查实例
      console.log(market_instance);
      //获取市场行情数量
      var num = await market_instance.getMarketNum.call();
      console.log("Market num:"+num);
      for (var index = 0; index < num; index++)
      {
        console.log("开始第"+index+"轮");
        var ret = await market_instance.getMarketStr_1.call(index);
        var date = ret[0];
        console.log(index+" getMarketStr_1 marketID:"+ret[1]);
        var market_id = ret[1];
        console.log("getMarketStr_1 sheet_id:"+ret[2]);
        var sheet_id = ret[2];
        console.log("getMarketStr_1 class_id:"+ret[3]);
        var class_id = ret[3];
        console.log("getMarketStr_1 make_date:"+ret[4]);
        var make_date = ret[4];
        console.log("getMarket_1 lev_id:"+ret[5]);
        var lev_id = ret[5];
        console.log("getMarket_1 wh_id:"+ret[6]);
        var whe_id = ret[6];
        console.log("getMarketStr_1 place_id:"+ret[7]);
        var place_id = ret[7];
        console.log("getMarketStr_1 执行完!!!"+index);

        var result = await market_instance.getMarketStr_2.call(index);
        var price = result[0];
        console.log("getMarket_2 price:"+result[0]);
        var list_qty = result[1];
        console.log("getMarket_2 listqty:"+ result[1]);
        var deal_qty = result[2];
        console.log("getMarket_2 deal_qty:"+result[2]);
        var rem_qty = result[3];
        console.log("getMarket_2 rem_qty:"+result[3]);
        var dead_line = result[4];
        console.log("getMarket_2 dealine:"+result[4]);
        var dlv_uint = result[5];
        console.log("getMarket_2 dlv_uint:"+result[5]);
        var user_id = result[6]; 
        console.log("getMarket_2 user_id:"+result[6]);
        var seller_addr = result[7];
        console.log("getMarket_2 seller_addr:"+result[7]);
        
        //在界面增加行情内容
        App.addTr(date,market_id, sheet_id, class_id, make_date, lev_id,whe_id, place_id, "yikoujia",price, list_qty, deal_qty, rem_qty, dead_line,dlv_uint);          
      }//for
  },

  //<挂单.Userid写死
  listRequests: async function(){
    var self = this;
    //获取内容
    var sheet_id = parseInt(document.getElementById("textfield0").value);
    console.log("sheet_id:"+sheet_id);
    var sheet_price=parseInt(document.getElementById("textfield1").value);
    console.log("sheet_price:"+sheet_price);
    var sheet_amount = parseInt(document.getElementById("textfield2").value);
    console.log("sheet_amount:"+sheet_amount);
   
    var dead_line = document.getElementById("textfield3").value;
    console.log("dead_line:"+dead_line);

    //TODO 对sheet_id进行检查，sheet_amount进行检查
    var txHash = await user_instance.listRequest.sendTransaction("User",sheet_id, sheet_price, sheet_amount,{from:account, gas:9000000});
    console.log("marktet_transactionHash:"+txHash);
  },

  //<事件函数
  eventTrigger:async function(){
    var self =this;
    console.log("eventTrigger !!!!");
    var event = await market_instance.getRet({formBlock:'latest',toBlock:'latest'});
    console.log(event);
    await event.watch(async function(error, result){
        if (!error)
        {
            console.log("listRequest retMarketid:"+result.args.ret);
            var retMarketid = result.args.ret;
            if (retMarketid != -1)
            {
                //获取市场行情 
                var ret = await market_instance.getMarketStrByMarketID_1.call(retMarketid);
                var date = ret[0];
                var market_id = ret[1];
                var sheet_id = ret[2];
                var class_id = ret[3];
                var make_date = ret[4];
                var lev_id = ret[5];
                var whe_id = ret[6];
                var place_id = ret[7];
                ret = await market_instance.getMarketStrByMarketID_2.call(retMarketid);
                var price = ret[0];
                var list_qty = ret[1];
                var deal_qty = ret[2];
                var rem_qty = ret[3];
                var dead_line = ret[4];
                var dlv_uint = ret[5];
                var user_id = ret[6];
                App.addTr(date, market_id, sheet_id, class_id,make_date, lev_id, whe_id, place_id, "yikoujia", price, list_qty,deal_qty, rem_qty, dead_line, dlv_uint);
                local_market_id++;
              }//if(retMarketid != -1)
           }//if
        //停止
        await event.stopWatching();
     });//event
  },

  //<展示我的挂单  
   myList: async function(){
        document.getElementById("myList").style.display="block";
        document.getElementById("myTrade").style.display="none";
        document.getElementById("myReceipt").style.display="none";

        if (!mutex_myList)
        {
            //每次点击都会清空tbody
            var table = document.getElementById("taList");
            var tBody = table.tBodies[0];
            tBody.parentNode.outerHTML = tBody.parentNode.outerHTML.replace(tBody.innerHTML, "");  
            //加锁
            mutex_myList = 1;
            //获取我的挂单数量
            var num = await user_instance.getListReqNum.call();
            console.log("myList num:"+num);
            //显示我的挂单
            for (var index = 0; index < num; index++)
            {
                var ret = await user_instance.getListReq.call(index);
                //添加我的挂单
                App.addMyList(ret[1],App.transTimeStamp(ret[2]),ret[3],ret[4],ret[5],"卖出",ret[6],ret[7],ret[8],ret[9],"deadline");
            }
            //解锁
            mutex_myList = 0;
            //myListFirstClick++;
       } 
    },

    //<展示我的合同
    myTrade :function(){
       //获取table实例
       document.getElementById("myTrade").style.display="block";
       document.getElementById("myList").style.display="none";
       document.getElementById("myReceipt").style.display="none";
       var table = document.getElementById("taTrade");
       //TODO: 从User.sol getTrade()获取合同
       //TODO: addmyTrade();
    },

    //<展示我的仓单
    myReceipt: async function(){
      var self = this;
      document.getElementById("myReceipt").style.display="block";
      document.getElementById("myTrade").style.display="none";
      document.getElementById("myList").style.display="none";
      var table = document.getElementById("taMyReceipt");
      //获取map长度
      if (!mutex_myReceipt)
      {
        //每次点击都会清空tbody
        var tBody = table.tBodies[0];
        tBody.parentNode.outerHTML = tBody.parentNode.outerHTML.replace(tBody.innerHTML, "");  
        //数据参数
        var user_id = "User";
        //加锁
        mutex_myReceipt = 1;
        var len = await user_instance.getSheetMapNum.call();
        console.log("sheetMap len:"+len);
        for (var index = 0; index < len; index++)
        {
            var result = await user_instance.getSheetMap_1.call(index);
            var sheet_id = result[1];
            console.log("class_id:"+result[2]);
            var class_id = result[2];
            console.log("make_date:"+result[3]);
            var make_date = result[3];
            console.log("lev_id:"+result[4]);
            var lev_id = result[4];
            console.log("whe_id:"+result[5]);
            var whe_id = result[5];
            console.log("place_id:"+result[6]);
            var place_id = result[6];
            result = await user_instance.getSheetMap_2.call(index);
            var all_amount = result[0];
            console.log("all_amount:"+all_amount);
            var avail_amount = result[1];
            console.log("avail_amount:"+avail_amount);
            var frozen_amount = result[2];
            console.log("frozen_amount:"+frozen_amount);
            await self.addmyReceipt(user_id, sheet_id, class_id, make_date, lev_id, whe_id, place_id, all_amount, avail_amount, frozen_amount);
       }
       //解锁
      mutex_myReceipt = 0;
      //myReceiptFirstClick++;
    }
  },
    //<撤单
    withdrawList: function(column){
        var tr = column.parentNode;
        console.log("rowIndex:"+tr.cells[0].innerHTML);
        var ret = confirm("挂牌编号:"+tr.cells[1].innerHTML+" 挂牌日期:"+tr.cells[2].innerHTML+" 价格:"+tr.cells[7].innerHTML+" 挂牌量:"+tr.cells[8].innerHTML+" 成交量:"
              +tr.cells[9].innerHTML+" 剩余量:"+tr.cells[10].innerHTML);
        if(ret == true)
        {
            //我的挂单删除行
            document.getElementById('taList').deleteRow(tr.rowIndex);
            //TODO 调用智能合约删除该条挂牌请求;
            //TODO 市场行情也删除,根据marketID删除市场行情
            console.log("确认撤单！！！");
        }
        else
        {
            console.log("不撤了!!!");
        }
    },
    //填充taList表
    //参数：委托编号(挂单编号),委托日期(挂单日期),等级,产期,等级,买卖,价格,挂牌量,剩余量,成交量,挂牌到期日
    addMyList: function(market_id, trade_date,class_id, make_date, lev_id, buyorsell, price, list_qty, rem_qty, deal_qty, dead_line){
        var table = document.getElementById("taList");
        var tr = document.createElement('tr');

        var td_opt = document.createElement('td');
        td_opt.innerHTML = "撤单";
        tr.appendChild(td_opt);
        td_opt.setAttribute("onclick","App.withdrawList(this)"); 
        var td_id = document.createElement('td');
        td_id.innerHTML= market_id;
        tr.appendChild(td_id);

        var td_date = document.createElement('td');
        td_date.innerHTML = trade_date;
        tr.appendChild(td_date);

        var td_classid = document.createElement('td');
        td_classid.innerHTML = class_id;
        tr.appendChild(td_classid);

        var td_makedate = document.createElement('td');
        td_makedate.innerHTML= make_date;
        tr.appendChild(td_makedate);

        var td_lev = document.createElement('td');
        td_lev.innerHTML = lev_id;
        tr.appendChild(td_lev);

        var td_buyOrsell = document.createElement('td');
        td_buyOrsell.innerHTML= buyorsell;
        tr.appendChild(td_buyOrsell);

        var td_price = document.createElement("td");
        td_price.innerHTML = price;
        tr.appendChild(td_price);

        var td_amount = document.createElement("td");
        td_amount.innerHTML = list_qty;
        tr.appendChild(td_amount);

        var td_remainAmount = document.createElement('td');
        td_remainAmount.innerHTML = rem_qty;
        tr.appendChild(td_remainAmount);

        var td_dealAmount = document.createElement('td');
        td_dealAmount.innerHTML = deal_qty;
        tr.appendChild(td_dealAmount);

        var td_deadline = document.createElement('td');
        td_deadline.innerHTML = dead_line;
        tr.appendChild(td_deadline);

        table.tBodies[0].appendChild(tr); 
    }, 

    //填充taTrade表
    //参数：合同日期, 合同编号, 仓单编号, 买卖, 价格, 合同量, 手续费, 已拨货款, 剩余货款, 己方id, 对手方id, 交收状态, 交易方式
    addmyTrade: function(trade_date, trade_id, sheet_id, buyorsell, price, trade_qty, fee, trans_money, rem_money, user_id, opp_id, trade_state, trade_type){
    },

    //填充taMyReceipt
    //参数: 用户id, 仓单序号, 品种id, 产期, 等级, 仓库代码, 产地代码, 仓单总量, 可用数量, 冻结数量
    addmyReceipt: function(user_id, sheet_id, class_id, make_date, lev_id, whe_id, place_id, all_amount, available_amount, frozen_amount){
       var table = document.getElementById("taMyReceipt");
       var tr = document.createElement('tr');
       //插入用户id
       var td_userid = document.createElement('td');
       td_userid.innerHTML = user_id;
       tr.appendChild(td_userid);

       //插入仓单序号
       var td_sheetid = document.createElement('td');
       td_sheetid.innerHTML = sheet_id;
       tr.appendChild(td_sheetid);

       var td_classid = document.createElement('td');
       td_classid.innerHTML = class_id;
       tr.appendChild(td_classid);

       var td_makedate = document.createElement('td');
       td_makedate.innerHTML=make_date;
       tr.appendChild(td_makedate);
       
       var td_levid = document.createElement('td');
       td_levid.innerHTML = lev_id;
       tr.appendChild(td_levid);

       var td_whid = document.createElement('td');
       td_whid.innerHTML = whe_id;
       tr.appendChild(td_whid);

       var td_placeid = document.createElement('td');
       td_placeid.innerHTML = place_id;
       tr.appendChild(td_placeid);

       var td_allamount=document.createElement('td');
       td_allamount.innerHTML=all_amount;
       tr.appendChild(td_allamount);

       var td_availamount = document.createElement('td');
       td_availamount.innerHTML = available_amount;
       tr.appendChild(td_availamount);

       var td_frozenamount = document.createElement('td');
       td_frozenamount.innerHTML=frozen_amount;
       tr.appendChild(td_frozenamount);
       table.tBodies[0].appendChild(tr);
    },


    //<摘牌弹出框
    popBox: function(tr){ 
        var market_id = tr.cells[2].innerHTML;
        console.log("popBox MarketID:"+market_id);

        var delWindow = window.open("", "delWin", "height=250, width=280,toolbar=no, location=no,resizable=no");
        delWindow.document.write("<html>");
        delWindow.document.write("<title>delisting</title>");
        delWindow.document.write("<body>");
        delWindow.document.write("<h1 align=\"center\">摘牌</h1>");
        delWindow.document.write("<table border=\"0\">");
        delWindow.document.write("<tr><td><lable>买方ID:</lable></td><td><input type=\"text\" id =\"userid\" /></td></tr>");
        delWindow.document.write("<tr><td><lable>挂牌编号:</lable></td><td><input type=\"text\" id=\"marketid\" /></td></tr>");
        delWindow.document.write("<tr><td><lable>数量:</lable></td><td><input type=\"text\" id=\"amount\"></input></td></tr>");
        delWindow.document.write("</table>");
        delWindow.document.write("<br><input type=\"button\" id=\"confirm\" name=\"confirm\"value=\"确定\" />");
        delWindow.document.write("</body>");
        delWindow.document.write("</html>");
        delWindow.document.close();
        //设置买方ID和摘牌数量
        var obj = delWindow.document.getElementById("userid");
        obj.setAttribute("value","User");
        obj = delWindow.document.getElementById("marketid");
        obj.setAttribute("value", market_id);
        
        var buy_user_id = "User";
        delWindow.document.getElementById("confirm").onclick=function(){
                var amount =  parseInt(delWindow.document.getElementById("amount").value);
                App.delisting(tr, buy_user_id, market_id, amount); 
                delWindow.close();
            };
    },

    //<摘牌
    delisting: async function(tr,buy_user_id,market_id, amount){
        console.log("delisting!!!!");
        console.log("挂牌序号:"+market_id);
        console.log("摘牌数量:"+amount);
        console.log(user_instance); 
        console.log("account:"+account);
        
        //设置资金
        await user_instance.insertFunds.sendTransaction(900000,{from:account, gas:9000000});
        //调用智能合约进行摘牌
        var ret = await user_instance.delistRequest.sendTransaction(buy_user_id, market_id, amount,{from:account,gas:9000000});
        //更新市场行情表
        var table = document.getElementById("taMarketList");
        //获取剩余量
        var rem_qty = tr.cells[13]
            
    },
    //<填充市场行情表单
	addTr: function(date,market_id, sheet_id, class_id, mkdate, lev, whe_id, place_id, price_type, price, list_qty, deal_qty, rem_qty, deadline, dlv_uint){
     //获取table实例
     var table = document.getElementById("taMarketList");
     //定义行元素
     var tr = document.createElement('tr');
     //插入index
     var td_index = document.createElement('td');
     td_index.innerHTML = rowseq++;
     td_index.setAttribute("text-align", "center");
     tr.appendChild(td_index);

     //插入挂牌日期
     var td_date = document.createElement('td');
     var time = App.transTimeStamp(date);
     td_date.innerHTML = time;
     tr.appendChild(td_date);

     //插入挂牌编号
     var td_list_id = document.createElement('td');
     td_list_id.innerHTML = market_id;
    // td_list_id.setAttribute("onclick","App.popBox(this)");
     tr.appendChild(td_list_id);

     //插入仓单编号 sheet_id
     var td_sheet_id = document.createElement('td');
     td_sheet_id.innerHTML = sheet_id;
     tr.appendChild(td_sheet_id);

     //插入等级 class_id
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
     tr.appendChild(td_rem_qty);

     //插入dealine
     var td_deadline = document.createElement('td');
     td_deadline.innerHTML = deadline;
     tr.appendChild(td_deadline);

     //插入dlv_uint
     var td_dlv_uint = document.createElement('td');
     td_dlv_uint.innerHTML = dlv_uint;
     tr.appendChild(td_dlv_uint);
     tr.setAttribute("onclick","App.popBox(this)");
     table.tBodies[0].appendChild(tr);
  }	
};

window.addEventListener('load', function() {
    rowseq = 0;
    console.log("load !!!");
	rowseq = document.getElementById("taMarketList").tBodies[0].rows.length + 1; 
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

