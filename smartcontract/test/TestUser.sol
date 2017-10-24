pragma solidity ^0.4.11;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/User.sol";
import "../contracts/ContractAddress.sol";
import "../contracts/Market.sol";
import "../contracts/UserList.sol";
import "../contracts/CreateID.sol";
contract TestUser
{
	User user;
	UserList user_list;
	Market market;
	CreateID create_id;
	ContractAddress contract_addr;
	string market_name;
	string create_id_name;
	string user_list_name;
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

		sheet_id            = 12345;
		all_amount          = 40;
		available_amount    = 30;
		frozen_amount       = 20;

		user            = new User();
		user_a          = new User();
		user_b          = new User();
		user_list       = new UserList();
		contract_addr   = new ContractAddress();
		market          = new Market();
		create_id       = new CreateID();

		market_name     = "market";
		create_id_name  = "create_id";
		user_list_name  = "user_list";
		user_id         = "user";
		user_a_id       = "I am user a";
		user_b_id       = "I am user b";

		contract_addr.setContractAddress(market_name, market);
		contract_addr.setContractAddress(create_id_name, create_id);
		contract_addr.setContractAddress(user_list_name, user_list);

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

		user_a.setContractAddress(contract_addr);
		user_a.setMarketName(market_name);
		user_a.setCreateIDName(create_id_name);
		user_a.setUserListName(user_list_name);
		user_a.setUserID(user_a_id);

		user_b.setContractAddress(contract_addr);
		user_b.setMarketName(market_name);
		user_b.setCreateIDName(create_id_name);
		user_b.setUserListName(user_list_name);
		user_b.setUserID(user_b_id);

	}
	function testInsertsheet_normal()
	{
		user.insertSheet(user_id,sheet_id,"SR","make_date","level_id","wh_id","产地",all_amount, frozen_amount, available_amount);
		var(ret_all_amount, ret_available_amount, ret_frozen_amount) = user.getSheetAmount(sheet_id);
		Assert.equal(all_amount, ret_all_amount, "");
		Assert.equal(available_amount, ret_available_amount, "");
		Assert.equal(frozen_amount, ret_frozen_amount, "");
	}
	function testFreeze_exceed_owned_sheet()
	{
		user.insertSheet(user_id,sheet_id,"SR","make_date","level_id","wh_id","产地",all_amount, frozen_amount, available_amount);
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
	function testListRequest_one_time()
	{
		uint sell_price = 100;
		uint sell_qty = 6;
		user.insertSheet(user_id,sheet_id,"SR","make_date","level_id","wh_id","产地",all_amount, frozen_amount, available_amount);
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
		user.insertSheet(user_id,sheet_id,"SR","make_date","level_id","wh_id","产地",all_amount, frozen_amount, available_amount);
		var ret_market_id = user.listRequest(user_id,sheet_id,sell_price,sell_qty); //one time
		ret_market_id = user.listRequest(user_id,sheet_id,sell_price,sell_qty);     //two time
		var(ret_all_amount, ret_available_amount, ret_frozen_amount) = user.getSheetAmount(sheet_id);
		Assert.equal(ret_available_amount, available_amount - sell_qty*2, "");
		Assert.equal(ret_frozen_amount, frozen_amount + sell_qty*2, "");
		Assert.equal(market.getMarketNum(), 2, "");
		Assert.equal(user.getListReqNum(), 2, "");
	}
	function testDelistRequest_listqty_greater_delistqty()
	{
		//user_a 挂牌
		uint sell_price = 100;
		uint sell_qty = 6;
		user_a.insertSheet(user_id,sheet_id,"SR","make_date","level_id","wh_id","产地",all_amount, frozen_amount, available_amount);
		var ret_market_id = user_a.listRequest(user_id,sheet_id,sell_price,sell_qty);

		//user_b 摘牌
		uint buy_qty = 2;
		var ret_delist = user_b.delistRequest(user_b_id, ret_market_id, buy_qty);

		//Assert
		Assert.equal(ret_market_id, 1, "ret_market_id == 1");
		Assert.equal(ret_delist, 0, "red_delist == 0");
		Assert.equal(market.getMarketNum(), 1, "market_num == 1");
		Assert.equal(user_a.getTradeNum(), 1, "a_trade_num == 1");
		Assert.equal(user_b.getTradeNum(), 1, "b_trade_num == 1");
		//var(ret_all_amount, ret_available_amount, ret_frozen_amount) = user.getSheetAmount(sheet_id);

	}
	function testDelistRequest_listqty_equal_delistqty()
	{
		//user_a 挂牌
		uint sell_price = 100;
		uint sell_qty = 6;
		user_a.insertSheet(user_a_id,sheet_id,"SR","make_date","level_id","wh_id","产地",all_amount, frozen_amount, available_amount);
		var ret_market_id = user_a.listRequest(user_a_id,sheet_id,sell_price,sell_qty);

		//user_b 摘牌
		uint buy_qty = 6;
		var ret_delist = user_b.delistRequest(user_b_id, ret_market_id, buy_qty);

		//Assert
		Assert.equal(ret_market_id, 1, "");
		Assert.equal(ret_delist, 0, "");
		Assert.equal(market.getMarketNum(), 0, "");
		Assert.equal(user_a.getTradeNum(), 1, "");
		Assert.equal(user_b.getTradeNum(), 1, "");
	}

	function testSendNegReq()
	{
		uint sell_price = 100;
		uint sell_qty = 6;

		//创建仓单
		user_a.insertSheet(user_a_id,sheet_id,"SR","make_date","level_id","wh_id","产地",all_amount, frozen_amount, available_amount);
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


	function testAgreeNeg()
	{
		int ret = 0;
		uint sell_price = 100;
		uint sell_qty = 6;

		//创建仓单
		user_a.insertSheet(user_a_id,sheet_id,"SR","make_date","level_id","wh_id","产地",all_amount, frozen_amount, available_amount);
		//发送协商交易请求
		//发送协商交易请求
		user_a.sendNegReq(sheet_id,sell_qty,sell_price,user_b_id);



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


		Assert.equal(b_length, 1, "b_length = 1");
		Assert.equal(b_ret_trade_id, 1, "b_ret_trade_id = 1");
		Assert.equal(b_ret_sheet_id, sheet_id, "");
		Assert.equal(b_ret_bs, "买", " b_ret_bs  ");
		Assert.equal(b_ret_opp_id, user_a_id," b_ret_opp_id = I am user b ");

	}

}
