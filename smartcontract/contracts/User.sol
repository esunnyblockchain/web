pragma solidity ^0.4.5;

import "./CreateID.sol";
import "./Market.sol";
import "./UserList.sol";
import "./ContractAddress.sol";
import "./lib/LibSheetMap.sol";
import "./lib/StructSheet.sol";
import "./lib/LibTradeMap.sol";
import "./lib/StructTrade.sol";
import "./lib/StructMarket.sol";
import "./lib/StructFunds.sol";
import "./lib/LibFunds.sol";
import "./lib/LibString.sol";


contract User
{
    event getRet(uint indexed ret);
    //挂牌请求数据结构
    struct ListRequest
    {
        uint        sheet_id_;      //仓单序号
        uint        market_id_;     //挂单编号
        uint        date_;           //挂牌日期
        bytes32     class_id_;       //品种代码
        bytes32     make_date_;      //产期
        bytes32     lev_id_;         //等级
        uint        price_;         //价格（代替浮点型）
        uint        list_qty_;      //挂牌量
        uint        rem_qty_;       //剩余量
        uint        deal_qty_;      //成交量
    }

    //协商交易请求数据结构 发送
    struct NegSendRequest
    {
        uint        sheet_id_;    //仓单序号
        uint        neg_qty_;      //交易数量
        uint        price_;         //价格
        uint        neg_id_;  //协商编号
        bytes32     opp_id_;//对手方id
        bytes32     trade_state_;    //成交状态
    }

    //协商交易请求数据结构 接收
    struct NegReceiveRequest
    {
        uint        sheet_id_;        //仓单序号
        uint        neg_qty_;          //交易数量
        uint        price_;             //价格
        uint        neg_id_;            //协商编号
        bytes32     opp_id_;      //对手方id
        bytes32     trade_state_;        //成交状态
    }

    using LibSheetMap   for     LibSheetMap.SheetMap;
    using LibTradeMap   for     LibTradeMap.TradeMap;
    using LibFunds      for     LibFunds.Funds;

    LibSheetMap.SheetMap    sheet_map;  //仓单
    LibTradeMap.TradeMap    trade_map;  //合同
    LibFunds.Funds          funds;      //资金
    uint                    fee;        //手续费

    Market                 market; 
    CreateID               create_id;
    UserList               user_list;

    ContractAddress        contract_address;
    string                 market_name;
    string                 create_id_name;
    string                 user_list_name;
    bytes32                my_user_id;
    bytes32                tmp_id;      //临时id变量
    StructMarket.value     temp_market; //临时行情变量
    StructTrade.value      tmp_trade;   //临时合同变量
    StructSheet.value      tmp_sheet;  //临时仓单变量

    ListRequest[]                     list_req; //协商交易请求列表     
    NegSendRequest[]                  neg_req_send_array; 
    NegReceiveRequest[]               neg_req_receive_array; 
    


    function setContractAddress(address addr)
    {
        contract_address = ContractAddress(addr); 
    }
    function setMarketName(string name)
    {
        market_name = name;
    }
    function setCreateIDName(string name)
    {
        create_id_name = name;
    }
    function setUserListName(string name)
    {
        user_list_name = name;
    }
    function setUserID(bytes32 id)
    {
        my_user_id = id;
    }
    //初始化CreateID合约变量
    function setCreateID()
    {
        create_id =  CreateID(contract_address.getContractAddress(create_id_name));
    }

    //初始化仓单
    function insertSheet(bytes32 user_id, bytes32 class_id, bytes32 make_date,bytes32 lev_id, bytes32 wh_id, bytes32 place_id, uint all_amount,uint frozen_amount, uint available_amount)
    {
        create_id =  CreateID(contract_address.getContractAddress(create_id_name));
        uint sheet_id = create_id.getSheetID();
        sheet_map.insert(sheet_id, StructSheet.value(user_id, sheet_id, class_id, make_date, lev_id, wh_id, place_id, all_amount,
                                                      available_amount,frozen_amount));
    }

    //获取持有者的仓单数量
    function getSheetAmount(uint sheet_id) returns (uint all_amount, uint available_amount, uint frozen_amount)
    {
        StructSheet.value memory sheet = sheet_map.getValue(sheet_id);
        all_amount = sheet.all_amount_;
        available_amount = sheet.available_amount_;
        frozen_amount = sheet.frozen_amount_;
    }

    //获取持有者的仓单总数量
    function getSheetAllAmount(uint sheet_id) returns (uint all_amount)
    {
        StructSheet.value memory sheet = sheet_map.getValue(sheet_id);
        all_amount = sheet.all_amount_;
    }

    //获取持有者的仓单可用数量
    function getSheetAvailableAmount(uint sheet_id) returns (uint available_amount)
    {
        StructSheet.value memory sheet = sheet_map.getValue(sheet_id);
        available_amount = sheet.available_amount_;
    }
    
    //获取持有者的仓单冻结数量
    function getSheetFrozenAmount(uint sheet_id) returns (uint frozen_amount)
    {
        StructSheet.value memory sheet = sheet_map.getValue(sheet_id);
        frozen_amount = sheet.frozen_amount_;
    }

    //获取仓单信息
    function getSheetAttribute(uint sheet_id) returns(bytes32 class_id,bytes32 make_date,bytes32 lev_id,bytes32 wh_id,bytes32 place_id)
    {
        tmp_sheet   =   sheet_map.getValue(sheet_id);
        class_id    =   tmp_sheet.class_id_;
        make_date   =   tmp_sheet.make_date_;
        lev_id      =   tmp_sheet.lev_id_;
        wh_id       =   tmp_sheet.wh_id_;
        place_id    =   tmp_sheet.place_id_;
    }

    //初始化资金 资金数扩大100倍
    function insertFunds(uint qty)
    {
        funds.insert(qty);
    }

    function setFee(uint n)
    {
        fee = n;
    }

    function getTotalFunds() returns(uint)
    {
        return funds.getTotalFunds();
    }

    function getAvaFunds() returns(uint)
    {
        return funds.getAvaFunds();
    }

    function getFrozenFunds() returns(uint)
    {
        return funds.getFrozenFunds();
    }



    //挂牌请求 "zhang",0,10,20
    function listRequest(bytes32 seller_user_id, uint sheet_id, uint price, uint sell_qty) returns( uint)
    {
        var sheet = sheet_map.getValue(sheet_id);
        if(sheet.available_amount_ == 0)
            {
                getRet(uint(-1));
                return uint(-1);
            }
            market =  Market(contract_address.getContractAddress(market_name));
            market.insertMarket_1(sheet.sheet_id_,sheet.class_id_, sheet.make_date_,sheet.lev_id_, sheet.wh_id_, sheet.place_id_);
            //TODO modify deadline、dlv_unit
            var(ret_market_id,date) = market.insertMarket_2(price, sell_qty, 0, sell_qty, "deadline", 5, sheet.user_id_ );
            if(ret_market_id >0)
            {
                    freeze(sheet_id, sell_qty);

                    //将挂牌数据保存到挂牌请求列表中
                    //仓单序号,挂牌编号,挂牌日期,类别,产期,等级,价格,挂牌量,剩余量,成交量,
                    list_req.push(ListRequest(sheet_id, ret_market_id, date, sheet.class_id_, sheet.make_date_, sheet.lev_id_, price, sell_qty, sell_qty,0)); 
                    getRet(ret_market_id);
            }
            return ret_market_id;
    }


    //摘牌请求 "li",1,10
    function delistRequest(bytes32 buy_user_id, uint selected_market_id, uint confirm_qty) returns (int)
    {
        getMarketTemp_1(selected_market_id);
        getMarketTemp_2(selected_market_id);
        uint payment = confirm_qty * temp_market.price_;

        if( payment > funds.getAvaFunds() )
            return -1;

        market =  Market(contract_address.getContractAddress(market_name));
        int ret = market.updateMarket(buy_user_id, selected_market_id, confirm_qty);

        //判断是否摘牌成功
        if(ret != 0)
            return -2;

        return 0;
    }

    //获取行情数据
    function getMarketTemp_1(uint market_id)
    {
        market =  Market(contract_address.getContractAddress(market_name));
        var(
            date,    //挂牌日期
            ret_market_id,        //挂牌编号
            sheet_id,    //仓单编号
            class_id,      //品种代码
            make_date,     //产期
            lev_id,        //等级
            wh_id,         //仓库代码
            place_id,      //产地代码
            price_type      //报价类型
        ) = market.getMarket_1(market_id);
        temp_market.date_       = date;
        temp_market.market_id_  = ret_market_id;
        temp_market.sheet_id_   = sheet_id;
        temp_market.class_id_   = class_id;
        temp_market.make_date_  = make_date;
        temp_market.lev_id_     = lev_id;
        temp_market.wh_id_      = wh_id;
        temp_market.place_id_   = place_id;
        temp_market.type_       = price_type;
    }
    function getMarketTemp_2(uint market_id)
    {
        var(
            price,         //价格（代替浮点型）
            list_qty,       //挂牌量
            deal_qty,      //成交量
            rem_qty,       //剩余量
            deadline,  //挂牌截止日
            dlv_unit,      //交割单位
            user_id,       //用户id
            seller_addr   //卖方地址
        ) = market.getMarket_2(market_id);
        temp_market.price_      = price;
        temp_market.list_qty_   = list_qty;
        temp_market.deal_qty_   = deal_qty;
        temp_market.rem_qty_    = rem_qty;
        temp_market.deadline_   = deadline;
        temp_market.dlv_unit_   = dlv_unit;
        temp_market.user_id_    = user_id;
        temp_market.seller_addr_= seller_addr;
    }

    //构建合同
    function recordTrade(uint trade_date, uint trade_id, bytes32 opp_user_id, bytes32 bs, uint confirm_qty, uint market_id) returns(int)
    {
        int ret = -1;
        getMarketTemp_1(market_id);
        getMarketTemp_2(market_id);
        trade_map.insert(trade_id,trade_date, opp_user_id, bs, confirm_qty,temp_market); 

        if(bs == "买")
              funds.freeze(confirm_qty * temp_market.price_);

         ret = 0;
    }

    function getTradeNum() returns (uint)
    {
        return trade_map.size();
    }

    //管理员确认挂牌交易
    function confirmList(uint trade_id) 
    {
        uint sheet_id   =   trade_map.data[trade_id].sheet_id_; 
        uint qty        =   trade_map.data[trade_id].trade_qty_;
        uint price      =   trade_map.data[trade_id].price_;
        bytes32 user_id =   trade_map.data[trade_id].user_id_;
        bytes32 opp_id  =   trade_map.data[trade_id].opp_id_;

        if(trade_map.data[trade_id].bs_  == "卖")
            {
                sheet_map.reduce(sheet_id,qty);
                funds.insert(qty * price);
                funds.deductFee(qty*price*fee);
            }
        else
            {
                //初始化user_list
                user_list =  UserList(contract_address.getContractAddress(user_list_name));
                        
                User user_sell = User(user_list.getUserAgentAddr(opp_id));
                var(class_id,make_date,lev_id,wh_id,place_id)= user_sell.getSheetAttribute(sheet_id); 

                if(sheet_map.isExisted(class_id,make_date,lev_id,wh_id,place_id))
                        sheet_map.add(sheet_id,qty);
                else
                    {
                        sheet_id = create_id.getSheetID();
                        sheet_map.insert(sheet_id, StructSheet.value(user_id, sheet_id, class_id, make_date, lev_id, wh_id, place_id,qty,0,qty));
                    }

                funds.reduce(qty * price);
            }
    }

    //更新卖方挂牌请求
    function updateListReq(uint market_id, uint deal_qty)
    {
        var list_num = list_req.length;
        for(uint i = 0; i<list_num; ++i)
        {
            if(list_req[i].market_id_ == market_id)
                {
                    list_req[i].deal_qty_      +=     deal_qty;
                    list_req[i].rem_qty_       -=     deal_qty;
                    break;
                }
        }
    }

    //冻结仓单
    function freeze(uint sheet_id, uint amount) returns (bool)
    {
        var available_amount  = getSheetAvailableAmount(sheet_id);
        if(amount > available_amount)  
            return false;

        sheet_map.freeze(sheet_id, amount);         
        return true;
    }



    //发送协商交易请求 卖方调用
    function sendNegReq(uint sheet_id, uint qty, uint price, bytes32 opp_id) returns(int ret)
    {
        //冻结仓单
        if( ! freeze(sheet_id, qty))
            {
                //TODO event
                ret = -1;
                return ret;
            }

            create_id =  CreateID(contract_address.getContractAddress(create_id_name));
            uint  neg_id = create_id.getNegID();//协商交易编号

            //更新协商交易请求列表（发送）
            neg_req_send_array.push( NegSendRequest(sheet_id,qty,price,neg_id,opp_id,"未成交") );

            //初始化user_list
            user_list =  UserList(contract_address.getContractAddress(user_list_name));
            //调用对手方协商交易请求的接收方法
            User buy_user =  User( user_list.getUserAgentAddr(opp_id) );
            //TODO assert 判断buy_user不为空
            buy_user.recNegReq(sheet_id, qty, price,neg_id, my_user_id);

            ret = 0;
    }

    //接收协商交易请求 卖方调用买方
    function recNegReq(uint sheet_id, uint qty, uint price, uint neg_id,bytes32 user_sell_id)
    {
        neg_req_receive_array.push( NegReceiveRequest(sheet_id,qty,price, neg_id,user_sell_id, "未成交") );
    }

    //获取接收的协商交易请求数据
    function getNegReqRec(uint k) returns(uint length, uint sheet_id, uint price, uint neg_id, bytes32 user_sell_id_)
    {
        length = neg_req_receive_array.length;
        sheet_id = neg_req_receive_array[k].sheet_id_;
        price   = neg_req_receive_array[k].price_;
        neg_id  = neg_req_receive_array[k].neg_id_;
        user_sell_id_ = neg_req_receive_array[k].opp_id_;

        return (length,sheet_id,price,neg_id,user_sell_id_);
    }

    //确认协商交易 买方调用此函数
    function agreeNeg(bytes32 buy_user_id, uint neg_id) returns(int ret)
    {
        //判断数组是否为空
        if(neg_req_receive_array.length ==0)
            {
                ret = -1;
                return;
            }

            for(uint i= 0; i<neg_req_receive_array.length; i++ )
            {
                if(neg_req_receive_array[i].neg_id_ == neg_id)
                    break;
            }
            //判断可用资金是否足够
            uint payment = neg_req_receive_array[i].neg_qty_ * neg_req_receive_array[i].price_;
            if( payment > funds.getAvaFunds() )
                {
                    ret = -2;
                    return;
                }

                //初始化user_list
                user_list =  UserList(contract_address.getContractAddress(user_list_name));

                //构建成交
                bytes32 sell_user_id =  neg_req_receive_array[i].opp_id_;
                User sell_user =  User( user_list.getUserAgentAddr(sell_user_id) );

                //获取合同编号
                CreateID create_id = CreateID(contract_address.getContractAddress(create_id_name));
                uint trade_id = create_id.getTradeID();
                uint date = now;

                ret = recordNegTrade(trade_id, date, buy_user_id, sell_user_id, "买", neg_id);
                if(ret != 0)
                    {
                        ret = -3;
                        return ;
                    }

                    ret = sell_user.recordNegTrade(trade_id,date, buy_user_id, sell_user_id, "卖", neg_id);
                    if(ret != 0)
                        {
                            ret = -4;
                            return ;
                        }

                        ret = 0;    
    }

    //构建合同
    function recordNegTrade(uint trade_id, uint date, bytes32 buy_user_id,bytes32 sell_user_id, bytes32 bs, uint neg_id) returns(int ) 
    {
        if(bs == "卖")
            {
                //判断发送请求数组是否为空
                if(neg_req_send_array.length ==0)
                    return -1;

                for(uint i= 0; i < neg_req_send_array.length; i++ )
                {
                    if(neg_req_send_array[i].neg_id_ == neg_id)
                        break;
                }

                trade_map.insert(trade_id, StructTrade.value(date,trade_id,neg_req_send_array[i].sheet_id_,bs,neg_req_send_array[i].price_,neg_req_send_array[i].neg_qty_,sell_user_id,buy_user_id));

                //funds.insert(neg_req_send_array[i].qty_ * neg_req_send_array[i].price_);
            }
            else
                {
                    //判断接收请求数组是否为空
                    if(neg_req_receive_array.length ==0)
                        return -2;

                    for(uint k= 0; k < neg_req_receive_array.length; k++ )
                    {
                        if(neg_req_receive_array[k].neg_id_ == neg_id)
                            break;
                    }

                    trade_map.insert(trade_id, StructTrade.value(date,trade_id,neg_req_receive_array[k].sheet_id_,bs,neg_req_receive_array[k].price_,neg_req_receive_array[k].neg_qty_,buy_user_id,sell_user_id));

                    //funds.reduce(neg_req_receive_array[k].qty_ * neg_req_receive_array[k].price_);
                    funds.freeze(neg_req_receive_array[k].neg_qty_ * neg_req_receive_array[k].price_);
                    return 0;
                }
    }

    //获取合同数据
    function getTradeMap(uint k) returns(uint length, uint trade_id, uint sheet_id, bytes32 bs, bytes32 opp_id)
    {
        tmp_trade = trade_map.getValue(k);

        length      =   trade_map.length(); 
        trade_id    =   tmp_trade.trade_id_;
        sheet_id    =   tmp_trade.sheet_id_;
        bs          =   tmp_trade.bs_;
        opp_id      =   tmp_trade.opp_id_;
    }

    //管理员确认协商交易
    function confirmNeg(uint trade_id) 
    {
        uint sheet_id   =   trade_map.data[trade_id].sheet_id_; 
        uint qty        =   trade_map.data[trade_id].trade_qty_;
        uint price      =   trade_map.data[trade_id].price_;
        bytes32 user_id =   trade_map.data[trade_id].user_id_;
        bytes32 opp_id  =   trade_map.data[trade_id].opp_id_;

        if(trade_map.data[trade_id].bs_  == "卖")
            {
                sheet_map.reduce(sheet_id,qty);
                funds.insert(qty * price);
                funds.deductFee(qty*price*fee);
            }
        else
            {
                //初始化user_list
                user_list =  UserList(contract_address.getContractAddress(user_list_name));
                        
                User user_sell = User(user_list.getUserAgentAddr(opp_id));
                var(class_id,make_date,lev_id,wh_id,place_id)= user_sell.getSheetAttribute(sheet_id); 

                if(sheet_map.isExisted(class_id,make_date,lev_id,wh_id,place_id))
                        sheet_map.add(sheet_id,qty);
                else
                    {
                        sheet_id = create_id.getSheetID(); 
                        sheet_map.insert(sheet_id, StructSheet.value(user_id, sheet_id, class_id, make_date, lev_id, wh_id, place_id,qty,0,qty));
                    }

                funds.reduce(qty * price);
            }
    }

    
	//获取sheetMap元素个数
    function getSheetMapNum() returns(uint)
    {
       return sheet_map.size();
    }
    //获取sheetMap元素信息
    function getSheetMap_1(uint index) external returns(string user_id, uint sheet_id,string class_id, string make_date, string level_id, string wh_id, string place_id)
    {
        tmp_sheet = sheet_map.getValueByIndex(index);
        user_id = LibString.bytes32ToString(tmp_sheet.user_id_);
        sheet_id = tmp_sheet.sheet_id_;
        class_id = LibString.bytes32ToString(tmp_sheet.class_id_);
        make_date = LibString.bytes32ToString(tmp_sheet.make_date_);
        level_id = LibString.bytes32ToString(tmp_sheet.lev_id_);
        wh_id = LibString.bytes32ToString(tmp_sheet.wh_id_);
        place_id = LibString.bytes32ToString(tmp_sheet.place_id_);
    }
    function getSheetMap_2(uint index) external returns(uint all_amount, uint avail_amount, uint frozen_amount)
    {
        tmp_sheet = sheet_map.getValueByIndex(index);
        all_amount = tmp_sheet.all_amount_;
        avail_amount = tmp_sheet.available_amount_;
        frozen_amount = tmp_sheet.frozen_amount_; 
    }

    //获取挂牌请求列表的长度
    function getListReqNum() returns(uint)
    {
        return list_req.length;
    }
    //获取挂牌请求列表数据
	function getListReq(uint i) external returns(uint sheet_id, uint market_id, uint date, string class_id, string make_date, string lev_id, uint price, uint list_qty, uint deal_qty, uint rem_qty)
    {
        if (i < list_req.length)
        {
            sheet_id    =       list_req[i].sheet_id_;
            market_id   =       list_req[i].market_id_;
            date        =       list_req[i].date_;
            class_id    =       LibString.bytes32ToString(list_req[i].class_id_);
            make_date   =       LibString.bytes32ToString(list_req[i].make_date_);
            lev_id      =       LibString.bytes32ToString(list_req[i].lev_id_);
            price       =       list_req[i].price_;
            list_qty    =       list_req[i].list_qty_;
            deal_qty    =       list_req[i].deal_qty_;
            rem_qty     =       list_req[i].rem_qty_;
        }
    }

    //获取协商请发送求列表数据
	function getNegReqSend(uint i) external returns(uint sheet_id, uint neg_id, uint price, uint neg_qty, string opp_id, string trade_state)
    {
        if (i < neg_req_send_array.length)
        {
            sheet_id    =       neg_req_send_array[i].sheet_id_;
            neg_id      =       neg_req_send_array[i].neg_id_;
            price       =       neg_req_send_array[i].price_;
            neg_qty     =       neg_req_send_array[i].neg_qty_;
            opp_id      =       LibString.bytes32ToString(neg_req_send_array[i].opp_id_);
            trade_state =       LibString.bytes32ToString(neg_req_send_array[i].trade_state_);
        }
    }

    //获取协商请接收求列表数据
	function getNegReqReceive(uint i) external returns(uint sheet_id, uint neg_id, uint price, uint neg_qty, string opp_id, string trade_state)
    {
        if (i < neg_req_receive_array.length)
        {
            sheet_id    =       neg_req_receive_array[i].sheet_id_;
            neg_id      =       neg_req_receive_array[i].neg_id_;
            price       =       neg_req_receive_array[i].price_;
            neg_qty     =       neg_req_receive_array[i].neg_qty_;
            opp_id      =       LibString.bytes32ToString(neg_req_receive_array[i].opp_id_);
            trade_state =       LibString.bytes32ToString(neg_req_receive_array[i].trade_state_);
        }
    }
	 //根据索引获取合同数据
    function getTrade(uint it) external returns(uint trade_date, uint trade_id, uint sheet_id, string bs, uint price, uint trade_qty,string user_id,string opp_id)
   {
       tmp_trade = trade_map.getValueByIndex(it);
       
       trade_date   =   tmp_trade.trade_date_;
       trade_id     =   tmp_trade.trade_id_;
       sheet_id     =   tmp_trade.sheet_id_;
       bs           =   LibString.bytes32ToString(tmp_trade.bs_);
       price        =   tmp_trade.price_;
       trade_qty    =   tmp_trade.trade_qty_;
       user_id      =   LibString.bytes32ToString(tmp_trade.user_id_);
       opp_id       =   LibString.bytes32ToString(tmp_trade.opp_id_);
   }
} 

