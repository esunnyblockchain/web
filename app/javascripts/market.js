// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/market.css";
// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import Proxy_artifacts from '../../smartcontract/build/contracts/Proxy.json'
import Market_artifacts from '../../smartcontract/build/contracts/Market.json'

// Proxy UserList Market ContractAddress is our usable abstraction, which we'll use through the code below.
var Proxy = contract(Proxy_artifacts);
var Market = contract(Market_artifacts);

// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;
let rowseq;

var proxy_instance;
var market_instance;

//挂单行情同步
var local_market_id;
var onDelisting = 0;

//市场行情更新操作
var local_opt_seq = 0;
var onListing = 0;

//防止重复点击按钮重复显示行情
var mutex_myReceipt = 0;
var mutex_myList = 0;
var mutex_myTrade = 0;

//第一次点击
var myListFirstClick = 0;
var myReceiptFirstClick = 0;

//user_id
var user_id;
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
    Proxy.setProvider(web3.currentProvider);
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
    
    //获取user_id
    var url = location.href;
    user_id = url.substring(url.indexOf("?")+1, url.length).split("=")[1];
    console.log("界面跳转user_id:"+user_id);

    //获取Proxy实例
    proxy_instance = await Proxy.deployed();
    
    //获取Market实例和marketID
    market_instance = await Market.deployed();
    local_market_id = await market_instance.getMarketID.call();
    console.log("Start local_market_id:"+local_market_id);
    
    //获取local_opt_seq
    var ret_seq  = await market_instance.get_opt_seq.call();
    console.log("!!!!Start get_opt_seq:"+ret_seq);
    local_opt_seq = ++ret_seq;
    console.log("!!!!Expect opt:"+local_opt_seq);

    await self.listMarket();
    setInterval(self.syncMaket,1000); 
  },

  //检查market_id改变时，进行同步
  syncMaket: async function(){
      var now_market_id = await market_instance.getMarketID.call();
      console.log("syncMarket  now_market_id:"+now_market_id);
      console.log("syncMarket local_market_id:"+local_market_id);
      App.listHook();
      App.delistHook();
  },

  //更新市场行情
  delistHook: async function(){
    //每次调用都会建立新的过滤器,在这里限制一下
    if(!onDelisting)
    {
        onDelisting++;
        var update_event = await market_instance.updateEvent({seq:local_opt_seq},{fromBlock:0, toBlock:'latest'});
        await update_event.watch(function(error, result){
              if (!error)
              {
                console.log("同步在delistHook:"+result.args.market_id+" amount:"+result.args.amount);
                var id = parseInt(result.args.market_id);
                var amount = parseInt(result.args.amount);
                App.updateTaMarketList(id ,amount);            
                //等待下一个事件
                local_opt_seq++;
              }
             update_event.stopWatching();
             onDelisting = 0;
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
                App.updateSeq();
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
 
  //删除行时，更新行情序号
  updateSeq: function(){
    var table = document.getElementById("taMarketList");
    for (var i = 1; i < table.rows.length; i++)
    {
        table.rows[i].cells[0].innerHTML = i;
    }
    rowseq = table.rows.length+1;
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
        App.addTr(date,market_id, sheet_id, class_id, make_date, lev_id,whe_id, place_id, "yikoujia",price, list_qty, deal_qty, rem_qty, dlv_uint);          
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
   
    //TODO 对sheet_id进行检查，sheet_amount进行检查
    var txHash = await proxy_instance.listRequest.sendTransaction(user_id, "UserA", sheet_id, sheet_price, sheet_amount,{from:account, gas:9000000});
    console.log("marktet_transactionHash:"+txHash);
  },

  //<事件函数
  listHook:async function(){
    var self =this;
    console.log("listHook !!!!");
    console.log("onListing:"+onListing);
    if(!onListing)
    {
        onListing++;
        var event = await market_instance.getRet({ret:local_market_id},{fromBlock: 0,toBlock:'latest'});
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
                    App.addTr(date, market_id, sheet_id, class_id,make_date, lev_id, whe_id, 
                              place_id, "yikoujia", price, list_qty,deal_qty, rem_qty, 
                              dlv_uint);
                    local_market_id++;
                }//if(retMarketid != -1)
                onListing = 0;
                event.stopWatching();
            }//if
        });//event
    }
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
            var num = await proxy_instance.getListReqNum.call(user_id);
            console.log("myList num:"+num);
            //显示我的挂单
            for (var index = 0; index < num; index++)
            {
                var ret = await proxy_instance.getListReq_1.call(user_id, index);
                var class_id = ret[0];
                var make_date = ret[1];
                var lev_id = ret[2];
                var wh_id = ret[3];
                var place_id = ret[4];

                ret = await proxy_instance.getListReq_2.call(user_id, index);
                var sheet_id = ret[0];
                var market_id = ret[1];
                var date = ret[2];
                var price = ret[3];
                var list_qty = ret[4];
                var deal_qty = ret[5];
                var rem_qty = ret[6];

                //添加我的挂单
                App.addMyList(market_id,App.transTimeStamp(date), class_id, make_date, lev_id, "卖", price, list_qty, deal_qty, rem_qty);
            }
            //解锁
            mutex_myList = 0;
            //myListFirstClick++;
       } 
    },

    //<展示我的合同
    myTrade : async function(){
       //获取table实例
       document.getElementById("myTrade").style.display="block";
       document.getElementById("myList").style.display="none";
       document.getElementById("myReceipt").style.display="none";
       if (!mutex_myTrade)
       {
            var table = document.getElementById("taTrade");
            var tBody = table.tBodies[0];
            tBody.parentNode.outerHTML = tBody.parentNode.outerHTML.replace(tBody.innerHTML, "");  
            //加锁
            mutex_myTrade = 1;

            var num = await proxy_instance.getTradeNum.call(user_id);
            console.log("!!!myTrade num:"+num);
            for (var index = 0; index < num; index++)
            {
                var ret = await proxy_instance.getTrade_1.call(user_id ,index);
                var id = ret[0];
                console.log("user_id:"+id);
                var opp_id = ret[1];
                console.log("opp_id:"+opp_id);
                var bs = ret[2];
                console.log("bs:"+bs);
                var trade_state = ret[3];
                console.log("trade_state:"+trade_state);
              
                var ret = await proxy_instance.getTrade_2.call(user_id, index);
                var trade_date = ret[0];
                console.log("Trade_date:"+trade_date);
                var trade_id = ret[1];
                console.log("Trade_id"+ trade_id);
                var sheet_id = ret[2];
                console.log("sheet_id"+sheet_id);
                var price = ret[3];
                console.log("price:"+price);
                var trade_qty = ret[4];
                console.log("trade_qty:"+trade_qty);
                var payment = ret[5];
                console.log("payment:"+payment);
                var fee = ret[6];
                console.log("fee:"+fee);

                App.addmyTrade(trade_date, trade_id, sheet_id, bs, price, trade_qty, id, opp_id, fee, payment, trade_state);
            }
            //解锁
            mutex_myTrade = 0;
       }
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
        //加锁
        mutex_myReceipt = 1;
        var len = await proxy_instance.getSheetMapNum.call(user_id);
        console.log("sheetMap len:"+len);
        for (var index = 0; index < len; index++)
        {
            var result = await proxy_instance.getSheetMap_1.call(user_id,index);
            var sheet_id = result[1];
            console.log("class_id:"+result[2]);
            var class_id = result[2];
            console.log("make_date:"+result[3]);
            var make_date = result[3];
            console.log("lev_id:"+result[4]);
            var lev_id = result[4];
            result = await proxy_instance.getSheetMap_2.call(user_id, index);
            console.log("whe_id:"+result[0]);
            var whe_id = result[0];
            console.log("place_id:"+result[1]);
            var place_id = result[1];
            var all_amount = result[2];
            console.log("all_amount:"+all_amount);
            var avail_amount = result[3];
            console.log("avail_amount:"+avail_amount);
            var frozen_amount = result[4];
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
    addMyList: function(market_id, trade_date,class_id, make_date, lev_id, buyorsell, price, list_qty, rem_qty, deal_qty){
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

        table.tBodies[0].appendChild(tr); 
    }, 

    //填充taTrade表
    //参数：合同日期, 合同编号, 仓单编号, 买/卖, 价格, 合同量, 买方, 卖方, 手续费, 总价, 状态
    addmyTrade: function(trade_date, trade_id, sheet_id, buyorsell, price, trade_qty, user_id, opp_id, fee, payment, trade_state){
        var table = document.getElementById("taTrade");
        var tr = document.createElement('tr');
        
        var td_date = document.createElement('td');
        td_date.innerHTML = App.transTimeStamp(trade_date);
        tr.appendChild(td_date);

        var td_tradeid = document.createElement('td');
        td_tradeid.innerHTML = trade_id;
        tr.appendChild(td_tradeid);

        var td_sheetid = document.createElement('td');
        td_sheetid.innerHTML = sheet_id;
        tr.appendChild(td_sheetid);

        var td_buyorsell = document.createElement('td');
        td_buyorsell.innerHTML = buyorsell;
        tr.appendChild(td_buyorsell);

        var td_price = document.createElement('td');
        td_price.innerHTML = price;
        tr.appendChild(td_price);

        var td_tradeqty = document.createElement('td');
        td_tradeqty.innerHTML = trade_qty;
        tr.appendChild(td_tradeqty);

        var td_userid = document.createElement('td');
        td_userid.innerHTML = user_id;
        tr.appendChild(td_userid);

        var td_oppid = document.createElement('td');
        td_oppid.innerHTML = opp_id;
        tr.appendChild(td_oppid);
        
        var td_fee = document.createElement('td');
        td_fee.innerHTML = fee;
        tr.appendChild(td_fee);

        var td_payment = document.createElement('td');
        td_payment.innerHTML = payment;
        tr.appendChild(td_payment);
        
        var td_trade_state = document.createElement('td');
        td_trade_state.innerHTML = trade_state;
        tr.appendChild(td_trade_state);
        
        table.tBodies[0].appendChild(tr);

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

        var delWindow = window.open("", "delWin", "height=250, width=280,toolbar=no, location=no,resizable=no,status=no,menubar=no");
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
        obj.setAttribute("value",user_id);
        obj = delWindow.document.getElementById("marketid");
        obj.setAttribute("value", market_id);
        
        delWindow.document.getElementById("confirm").onclick=function(){
                var amount =  parseInt(delWindow.document.getElementById("amount").value);
                App.delisting(tr, user_id, market_id, amount); 
                delWindow.close();
            };
    },

    //<摘牌
    delisting: async function(tr,buy_user_id,market_id, amount){
        console.log("delisting!!!!");
        console.log("挂牌序号:"+market_id);
        console.log("摘牌数量:"+amount); 
        console.log("account:"+account);
        console.log("买方ID:"+buy_user_id);
        
        //调用智能合约进行摘牌
        var ret = await proxy_instance.delistRequest.sendTransaction(user_id, buy_user_id, market_id, amount,{from:account,gas:9000000});
    },

    //<填充市场行情表单
	addTr: function(date,market_id, sheet_id, class_id, mkdate, lev, whe_id, place_id, price_type, price, list_qty, deal_qty, rem_qty, dlv_uint){
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

