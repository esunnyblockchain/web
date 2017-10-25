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

contract User
{
    event getRet(uint ret);
	//挂牌请求数据结构
	struct ListRequest
	{
		uint       sheet_id_;    //仓单序号
		uint       market_id_;        //挂单编号
		uint       price_;         //价格（代替浮点型）
		uint       list_qty_;       //挂牌量
		uint       deal_qty_;      //成交量
		uint       rem_qty_;       //剩余量
	}

	//协商交易请求数据结构 发送
	struct NegSendRequest
	{
		uint        sheet_id_;    //仓单序号
		uint        qty_;      //交易数量
		uint        price_;         //价格
		uint        neg_id_;  //协商编号
		bytes32     opp_id_;//对手方id
		bytes32     trade_state;    //成交状态
	}

	//协商交易请求数据结构 接收
	struct NegReceiveRequest
	{
		uint        sheet_id_;        //仓单序号
		uint        qty_;          //交易数量
		uint        price_;             //价格
		uint        neg_id_;            //协商编号
		bytes32     opp_id_;      //对手方id
		bytes32     trade_state;        //成交状态
	}

	using LibSheetMap for LibSheetMap.SheetMap;
	using LibTradeMap for LibTradeMap.TradeMap;

	LibSheetMap.SheetMap   sheet_map;
	LibTradeMap.TradeMap   trade_map;

    Market                 market; 
	CreateID               create_id;
	UserList               user_list;

	ContractAddress        contract_address;
	string                 market_name;
	string                 create_id_name;
	string                 user_list_name;
	bytes32                my_user_id;
	bytes32				   tmp_id;		//临时id变量

    StructMarket.value     temp_market; //临时行情变量
	StructTrade.value	   tmp_trade;	//临时合同变量
    StructSheet.value      tmp_sheet;   //临时仓单变量
	ListRequest[]          list_req;     
	//协商交易请求列表
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

	function insertSheet(bytes32 user_id, uint sheet_id, bytes32 class_id, bytes32 make_date,
			bytes32 lev_id, bytes32 wh_id, bytes32 place_id, uint all_amount, 
			uint frozen_amount, uint available_amount)
	{
		//if(user_id != my_user_id) return;
		sheet_map.insert(sheet_id, StructSheet.value(user_id, sheet_id, 
					class_id, make_date, lev_id, wh_id, place_id, all_amount,
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

	//挂牌请求 "zhang",0,10,20
	function listRequest(bytes32 seller_user_id, uint sheet_id, uint price, uint sell_qty) returns(uint ret_market_id)
	{
		var sheet = sheet_map.getValue(sheet_id);
		if(sheet.available_amount_ == 0)
		{
			//TODO event
            getRet(uint(-1));
			return uint(-1);
		}
		market =  Market(contract_address.getContractAddress(market_name));
		market.insertMarket_1(sheet.sheet_id_,sheet.class_id_, sheet.make_date_,sheet.lev_id_, sheet.wh_id_, sheet.place_id_);
		//TODO modify deadline、dlv_unit
		ret_market_id = market.insertMarket_2(price, sell_qty, 0, sell_qty, "deadline", 5, sheet.user_id_ );
		if(ret_market_id >0)
		{
			freeze(sheet_id, sell_qty);
		}
		list_req.push(ListRequest(sheet_id, ret_market_id, price, sell_qty, 0, sell_qty)); 
        getRet(ret_market_id);
	}
	function getListReqNum() returns(uint)
	{
		return list_req.length;
	}

	//摘牌请求 "li",1,10
	function delistRequest(bytes32 buy_user_id, uint selected_market_id, uint confirm_qty) returns (uint)
	{
		market =  Market(contract_address.getContractAddress(market_name));
		return market.updateMarket(buy_user_id, selected_market_id, confirm_qty);
	}
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
	function recordTrade(uint trade_date, uint trade_id, bytes32 opp_user_id, bytes32 bs, uint confirm_qty, uint market_id)
	{
		getMarketTemp_1(market_id);
		getMarketTemp_2(market_id);
		trade_map.insert(trade_id,trade_date, opp_user_id, bs, confirm_qty,temp_market); 
	}
	function getTradeNum() returns (uint)
	{
		return trade_map.size();
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
		var(all_amount, available_amount, frozen_amount) = getSheetAmount(sheet_id);
		if(amount > available_amount)  
			return false;

		sheet_map.update(sheet_id, all_amount, available_amount - amount, frozen_amount + amount);         
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
			ret = -2;
			return ;
		}

		ret = sell_user.recordNegTrade(trade_id,date, buy_user_id, sell_user_id, "卖", neg_id);
		if(ret != 0)
		{
			ret = -3;
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

			trade_map.insert1(trade_id, StructTrade.value(date,trade_id,neg_req_send_array[i].sheet_id_,bs,neg_req_send_array[i].price_,neg_req_send_array[i].qty_,sell_user_id,buy_user_id));

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

			trade_map.insert1(trade_id, StructTrade.value(date,trade_id,neg_req_receive_array[k].sheet_id_,bs,neg_req_receive_array[k].price_,neg_req_receive_array[k].qty_,buy_user_id,sell_user_id));

			return 0;
		}
	}

	//获取合同数据
	function getTradeMap(uint k) returns(uint length, uint trade_id, uint sheet_id, bytes32 bs, bytes32 opp_id)
	{
		tmp_trade = trade_map.getValue(k);

		length		=	trade_map.length(); 
		trade_id	=	tmp_trade.trade_id_;
		sheet_id	=	tmp_trade.sheet_id_;
		bs			=	tmp_trade.bs_;
		opp_id		=	tmp_trade.opp_id_;
    }
	//获取marketid
    function getMarketID() returns(uint ret_market_id)
    {
        create_id =  CreateID(contract_address.getContractAddress(create_id_name));
        ret_market_id = create_id.getMarketID();
    }
    //获取sheetMap元素个数
    function getSheetMapNum() returns(uint)
    {
       return sheet_map.size();
    }
    
    function bytes32ToString(bytes32 x) returns (string){
            bytes memory bytesString = new bytes(32);
            uint charCount = 0;
            for (uint j = 0; j < 32; j++) 
            {
                    byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
                    if (char != 0) 
                    {
                            bytesString[charCount] = char;
                            charCount++;
                    }
            }
            bytes memory bytesStringTrimmed = new bytes(charCount);
            for (j = 0; j < charCount; j++) 
            {
                    bytesStringTrimmed[j] = bytesString[j];
            }
            return string(bytesStringTrimmed);
    }
    //获取sheetMap元素信息
    function getSheetMap_1(uint index) returns(string user_id, uint sheet_id,string class_id, string make_date, string level_id, string wh_id, string place_id)
    {
        tmp_sheet = sheet_map.getValueByIndex(index);
        user_id = bytes32ToString(tmp_sheet.user_id_);
        sheet_id = tmp_sheet.sheet_id_;
        class_id = bytes32ToString(tmp_sheet.class_id_);
        make_date = bytes32ToString(tmp_sheet.make_date_);
        level_id = bytes32ToString(tmp_sheet.lev_id_);
        wh_id = bytes32ToString(tmp_sheet.wh_id_);
        place_id = bytes32ToString(tmp_sheet.place_id_);
    }
    function getSheetMap_2(uint index) returns(uint all_amount, uint avail_amount, uint frozen_amount)
    {
        tmp_sheet = sheet_map.getValueByIndex(index);
        all_amount = tmp_sheet.all_amount_;
        avail_amount = tmp_sheet.available_amount_;
        frozen_amount = tmp_sheet.frozen_amount_; 
    }

} 
