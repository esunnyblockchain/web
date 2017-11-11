pragma solidity ^0.4.11;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/User.sol";
import "../contracts/ContractAddress.sol";
import "../contracts/Market.sol";
import "../contracts/UserList.sol";
import "../contracts/CreateID.sol";
import "../contracts/Admin.sol";

contract TestUser
{
	User user;// {{{
	UserList user_list;
	Market market;
    Admin admin;
	CreateID create_id;
	ContractAddress contract_addr;// }}}
	string market_name;
	string create_id_name;
	string user_list_name;
    string admin_name;
	bytes32 user_id;
	uint sheet_id;
	uint all_amount;
	uint available_amount;
	uint frozen_amount;

	User user_a;
	User user_b;
	bytes32 user_a_id;
	bytes32 user_b_id;


	function beforeEach()
	{

		sheet_id            = 1;
		all_amount          = 60;
		available_amount    = 40;
		frozen_amount       = 20;

		user            = new User();
		user_a          = new User();
		user_b          = new User();
		user_list       = new UserList();
		contract_addr   = new ContractAddress();
		market          = new Market();
		create_id       = new CreateID();
        admin           = new Admin();

		market_name     = "market";
		create_id_name  = "create_id";
		user_list_name  = "user_list";
        admin_name      = "admin";
		user_id         = "user";
		user_a_id       = "I am user a";
		user_b_id       = "I am user b";

		contract_addr.setContractAddress(market_name, market);
		contract_addr.setContractAddress(create_id_name, create_id);
		contract_addr.setContractAddress(user_list_name, user_list);
		contract_addr.setContractAddress(admin_name, admin);

		market.setContractAddress(contract_addr);
		market.setCreateIDName(create_id_name);
		market.setUserListName(user_list_name);

		user_list.addUser(user,user,user_id,1); 
		user_list.addUser(user_a,user_a,user_a_id,1); 
		user_list.addUser(user_b,user_b,user_b_id,1); 

		user.setContractAddress(contract_addr);
		user.setMarketName(market_name);
		user.setCreateIDName(create_id_name);
		user.setUserListName(user_list_name);
		user.setUserID(user_id);
        user.setAdmin(admin_name);

		user_a.setContractAddress(contract_addr);
		user_a.setMarketName(market_name);
		user_a.setCreateIDName(create_id_name);
		user_a.setUserListName(user_list_name);
		user_a.setUserID(user_a_id);
        user_a.setCreateID();
        user_a.setAdmin(admin_name);

		user_b.setContractAddress(contract_addr);
		user_b.setMarketName(market_name);
		user_b.setCreateIDName(create_id_name);
		user_b.setUserListName(user_list_name);
		user_b.setUserID(user_b_id);
        user_b.setCreateID();
        user_b.setAdmin(admin_name);
	}

	function testInsertsheet_normal()
	{
		user.insertSheet(user_id,"SR","make_date","level_id","wh_id","产地",all_amount, frozen_amount, available_amount);
		var(ret_all_amount, ret_available_amount, ret_frozen_amount) = user.getSheetAmount(sheet_id);
		Assert.equal(all_amount, ret_all_amount, "");
		Assert.equal(available_amount, ret_available_amount, "");
		Assert.equal(frozen_amount, ret_frozen_amount, "");
	}

	function testFreeze_exceed_owned_sheet()
	{
		user.insertSheet(user_id,"SR","make_date","level_id","wh_id","产地",all_amount,frozen_amount,available_amount);
		user.freeze(1, available_amount + 1);
		var(ret_all_amount, ret_available_amount, ret_frozen_amount) = user.getSheetAmount(sheet_id);
		Assert.equal(all_amount, ret_all_amount, "");
		Assert.equal(available_amount, ret_available_amount, "");
		Assert.equal(frozen_amount, ret_frozen_amount, "");
	}
	function testGetMarketAddr()
	{
		address market_addr = contract_addr.getContractAddress(market_name);
		Assert.equal(market_addr, market, "");
	}

    //测试挂牌
	function testListRequest_one_time()
	{
		uint sell_price = 100;
		uint sell_qty = 6;
		user.insertSheet(user_id,"SR","make_date","level_id","wh_id","产地",all_amount,frozen_amount,available_amount);
		var ret_market_id = user.listRequest(user_id,sheet_id,sell_price,sell_qty);
		var(ret_all_amount, ret_available_amount, ret_frozen_amount) = user.getSheetAmount(sheet_id);

		Assert.equal(ret_available_amount, available_amount - sell_qty, "");
		Assert.equal(ret_frozen_amount, frozen_amount + sell_qty, "");
		Assert.equal(market.getMarketNum(), 1, "");
		Assert.equal(user.getListReqNum(), 1, "");
        
	}
	function testListRequest_two_time()
	{
		uint sell_price = 100;
		uint sell_qty = 6;
		user.insertSheet(user_id,"SR","make_date","level_id","wh_id","产地",all_amount,frozen_amount,available_amount);
		var ret_market_id = user.listRequest(user_id,sheet_id,sell_price,sell_qty); //one time
		ret_market_id = user.listRequest(user_id,sheet_id,sell_price,sell_qty);     //two time
		var(ret_all_amount, ret_available_amount, ret_frozen_amount) = user.getSheetAmount(sheet_id);
		Assert.equal(ret_available_amount, available_amount - sell_qty*2, "");
		Assert.equal(ret_frozen_amount, frozen_amount + sell_qty*2, "");
		Assert.equal(market.getMarketNum(), 2, "");
		Assert.equal(user.getListReqNum(), 2, "");
	}

    //测试摘牌
	function testDelistRequest_listqty_greater_delistqty()
	{
		//user_a 挂牌
		uint sell_price = 100;
		uint sell_qty = 6;
		user_a.insertSheet(user_a_id,"SR","make_date","level_id","wh_id","产地",all_amount,frozen_amount,available_amount);
        user_a.insertFunds(1000);      //初始化资金

		var ret_market_id = user_a.listRequest(user_a_id,sheet_id,sell_price,sell_qty);

		//user_b 摘牌
        user_b.insertFunds(1000);      //初始化资金

		uint buy_qty = 2;
		var ret_delist = user_b.delistRequest(user_b_id, ret_market_id, buy_qty);
        var ret_a_funds =  user_a.getTotalFunds();
        var ret_b_funds =  user_b.getAvaFunds();

		//Assert
		Assert.equal(ret_market_id, 1, "");
		Assert.equal(ret_delist, 0, "");
		Assert.equal(market.getMarketNum(), 1, "");
		Assert.equal(user_a.getTradeNum(), 1, "");
		Assert.equal(user_b.getTradeNum(), 1, "");
        Assert.equal(ret_a_funds, 100000, "");
        Assert.equal(ret_b_funds, 80000, "");

	}

	function testDelistRequest_listqty_equal_delistqty()
	{
		//user_a 挂牌
		uint sell_price = 100;
		uint sell_qty = 6;
		user_a.insertSheet(user_a_id,"SR","make_date","level_id","wh_id","产地",all_amount,frozen_amount,available_amount);
        user_a.insertFunds(1000);      //初始化资金

		var ret_market_id = user_a.listRequest(user_a_id,sheet_id,sell_price,sell_qty);

		//user_b 摘牌
		uint buy_qty = 6;
        user_b.insertFunds(1000);      //初始化资金

		var ret_delist = user_b.delistRequest(user_b_id, ret_market_id, buy_qty);
        var ret_a_funds =  user_a.getTotalFunds();
        var ret_b_funds =  user_b.getAvaFunds();

		//Assert
		Assert.equal(ret_market_id, 1, "");
		Assert.equal(ret_delist, 0, "");
		Assert.equal(market.getMarketNum(), 0, "");
		Assert.equal(user_a.getTradeNum(), 1, "");
		Assert.equal(user_b.getTradeNum(), 1, "");
        Assert.equal(ret_a_funds, 100000, "");
        Assert.equal(ret_b_funds, 40000, "");
	}

    //测试挂牌管理员确认函数 挂牌量为6,摘牌量为2
    function testConfirmListGreater()
    {
		//user_a 挂牌
		uint sell_price = 100;
		uint sell_qty = 6;
		user_a.insertSheet(user_a_id,"SR","make_date","level_id","wh_id","产地",all_amount,frozen_amount,available_amount);
        user_a.insertFunds(1000);       //初始化资金
        user_a.setFee(3);               //设置手续费比率

		var ret_market_id = user_a.listRequest(user_a_id,sheet_id,sell_price,sell_qty);

		//user_b 摘牌
		uint buy_qty = 2;
        user_b.insertFunds(1000);       //初始化资金
        user_b.setFee(3);               //设置手续费比率

		var ret_delist  = user_b.delistRequest(user_b_id, ret_market_id, buy_qty);//摘牌
        user_a.confirmList(1);         //确认
        user_b.confirmList(1);         //确认
        var ret_confirm     = user_a.confirmList(2);
        var ret_a_funds     =  user_a.getTotalFunds();
        var ret_b_funds     =  user_b.getTotalFunds();
        var ret_a_sheet     =  user_a.getSheetAllAmount(sheet_id);
        var ret_b_sheet     =  user_b.getSheetAllAmount(2);

		//Assert
		Assert.equal(ret_market_id, 1, "");
		Assert.equal(ret_delist, 0, "");
		Assert.equal(market.getMarketNum(), 1, "");
		Assert.equal(user_a.getTradeNum(), 1, "");
		Assert.equal(user_b.getTradeNum(), 1, "");
        Assert.equal(ret_a_funds, 119400, "");
        Assert.equal(ret_b_funds, 80000, "");
        Assert.equal(ret_a_sheet,58, "");
        Assert.equal(ret_b_sheet,2, "");
        Assert.equal(ret_confirm,-1, "");
	
    }

    //测试挂牌管理员确认函数 摘牌量与挂牌量相等
    function testConfirmListEqual()
    {
		//user_a 挂牌
		uint sell_price = 100;
		uint sell_qty = 6;
		user_a.insertSheet(user_a_id,"SR","make_date","level_id","wh_id","产地",all_amount,frozen_amount,available_amount);
        user_a.insertFunds(1000);       //初始化资金
        user_a.setFee(3);               //设置手续费比率

		var ret_market_id = user_a.listRequest(user_a_id,sheet_id,sell_price,sell_qty);

		//user_b 摘牌
		uint buy_qty = 6;
        user_b.insertFunds(1000);       //初始化资金
        user_b.setFee(3);               //设置手续费比率

		var ret_delist  = user_b.delistRequest(user_b_id, ret_market_id, buy_qty);//摘牌
        user_a.confirmList(1);         //确认
        user_b.confirmList(1);         //确认
        var ret_a_funds     =  user_a.getTotalFunds();
        var ret_b_funds     =  user_b.getTotalFunds();
        var ret_a_sheet     =  user_a.getSheetAllAmount(sheet_id);
        var ret_b_sheet     =  user_b.getSheetAllAmount(2);

		//Assert
		Assert.equal(ret_market_id, 1, "");
		Assert.equal(ret_delist, 0, "");
		Assert.equal(market.getMarketNum(), 0, "");
		Assert.equal(user_a.getTradeNum(), 1, "");
		Assert.equal(user_b.getTradeNum(), 1, "");
        Assert.equal(ret_a_funds, 158200, "");
        Assert.equal(ret_b_funds, 40000, "");
        Assert.equal(ret_a_sheet,54, "");
        Assert.equal(ret_b_sheet,6, "");
    }

    //测试协商交易
	function testSendNegReq()
	{
		uint sell_price = 100;
		uint sell_qty = 6;

		//创建仓单
		user_a.insertSheet(user_a_id,"SR","make_date","level_id","wh_id","产地",all_amount,frozen_amount,available_amount);
		//发送协商交易请求
		user_a.sendNegReq(sheet_id,sell_qty,sell_price,user_b_id);

		var(ret_all_amount, ret_available_amount, ret_frozen_amount) = user_a.getSheetAmount(sheet_id);
		var(ret_length, ret_sheet_id, ret_price, ret_neg_id, ret_user_sell_id) = user_b.getNegReqRec(0);

		Assert.equal(ret_length, 1, "");
		Assert.equal(ret_available_amount, available_amount - sell_qty, "");
		Assert.equal(ret_frozen_amount, frozen_amount + sell_qty, "");
		Assert.equal(market.getMarketNum(), 0, "");

		Assert.equal(ret_sheet_id, sheet_id, "");
		Assert.equal(ret_price, sell_price, "ret_price = 100");
		Assert.equal(ret_neg_id, 1, "ret_neg_id = 1");
		Assert.equal(ret_user_sell_id, user_a_id, "ret_user_sell_id = I am user_a");
	}

    //测试协商交易的同意函数
	function testAgreeNeg()
	{
		int ret = 0;
		uint sell_price = 100;
		uint sell_qty = 6;

		//创建仓单
		user_a.insertSheet(user_a_id,"SR","make_date","level_id","wh_id","产地",all_amount,frozen_amount,available_amount);
        //初始化资金
        user_a.insertFunds(1000);      

		//发送协商交易请求
		user_a.sendNegReq(sheet_id,sell_qty,sell_price,user_b_id);

        //初始化资金
        user_b.insertFunds(1000);      

		//同意协商交易
		ret = user_b.agreeNeg(user_b_id, 1);

		//获取双方的合同数据
		var(a_length,a_ret_trade_id, a_ret_sheet_id, a_ret_bs, a_ret_opp_id) = user_a.getTradeMap(1);
		var(b_length,b_ret_trade_id, b_ret_sheet_id, b_ret_bs, b_ret_opp_id) = user_b.getTradeMap(1);

		Assert.equal(ret, 0, "user_b.agreeNeg ret = 0");
		Assert.equal(a_length, 1, "a_length = 1");
		Assert.equal(a_ret_trade_id, 1, "a_ret_trade_id = 1");
		Assert.equal(a_ret_sheet_id, sheet_id, "");
		Assert.equal(a_ret_bs, "卖", "");
		Assert.equal(a_ret_opp_id, user_b_id,"");
        Assert.equal(user_a.getTotalFunds(), 100000, "");


		Assert.equal(b_length, 1, "b_length = 1");
		Assert.equal(b_ret_trade_id, 1, "b_ret_trade_id = 1");
		Assert.equal(b_ret_sheet_id, sheet_id, "");
		Assert.equal(b_ret_bs, "买", " b_ret_bs  ");
		Assert.equal(b_ret_opp_id, user_a_id," b_ret_opp_id = I am user b ");
        Assert.equal(user_b.getAvaFunds(), 40000, "");

	}

    //测试协商交易的管理员确认函数
	function testConfirmNeg()
	{
		int ret = 0;
		uint sell_price = 100;
		uint sell_qty = 6;

		//创建仓单
		user_a.insertSheet(user_a_id,"SR","make_date","level_id","wh_id","产地",all_amount,frozen_amount,available_amount);
        user_a.insertFunds(1000);       //初始化资金
        user_a.setFee(3);               //设置手续费比率

		//发送协商交易请求
		user_a.sendNegReq(sheet_id,sell_qty,sell_price,user_b_id);

        user_b.insertFunds(1000);       //初始化资金
        user_b.setFee(3);               //设置手续费比率

		//同意协商交易
		ret = user_b.agreeNeg(user_b_id, 1);

        //管理员确认
        user_a.confirmNeg(1);
        user_b.confirmNeg(1);

		//获取双方的合同数据
		var(a_length,a_ret_trade_id, a_ret_sheet_id, a_ret_bs, a_ret_opp_id) = user_a.getTradeMap(1);
		var(b_length,b_ret_trade_id, b_ret_sheet_id, b_ret_bs, b_ret_opp_id) = user_b.getTradeMap(1);

		Assert.equal(ret, 0, "user_b.agreeNeg ret = 0");
		Assert.equal(a_length, 1, "a_length = 1");
		Assert.equal(a_ret_trade_id, 1, "a_ret_trade_id = 1");
		Assert.equal(a_ret_sheet_id, sheet_id, "");
		Assert.equal(a_ret_bs, "卖", "");
		Assert.equal(a_ret_opp_id, user_b_id,"");
        Assert.equal(user_a.getTotalFunds(), 158200, "");
        Assert.equal(user_a.getSheetAllAmount(sheet_id), 54, "");


		Assert.equal(b_length, 1, "b_length = 1");
		Assert.equal(b_ret_trade_id, 1, "b_ret_trade_id = 1");
		Assert.equal(b_ret_sheet_id, sheet_id, "");
		Assert.equal(b_ret_bs, "买", " b_ret_bs  ");
		Assert.equal(b_ret_opp_id, user_a_id," b_ret_opp_id = I am user b ");
        Assert.equal(user_b.getTotalFunds(), 40000, "");
        Assert.equal(user_b.getAvaFunds(), 40000, "");
        Assert.equal(user_b.getFrozenFunds(), 0, "");
        Assert.equal(user_b.getSheetAllAmount(2), 6, "");
	}
}
