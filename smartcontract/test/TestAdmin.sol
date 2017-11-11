pragma solidity ^0.4.11;

import "truffle/Assert.sol";
import "../contracts/Admin.sol";
import "../contracts/User.sol";

contract TestAdmin
{
    ContractAddress 	contract_addr;
	UserList 			user_list;
    Market 				market;
    CreateID 			create_id;
    Admin 				admin;
    User 				user_a;
    User 				user_b;
    string 				market_name;
    string 				create_id_name;
    string 				user_list_name;
    string 				admin_name;

	bytes32 			user_a_id;
    bytes32 			user_b_id;

	uint 				sheet_id;
    uint 				all_amount;
    uint 				available_amount;
    uint 				frozen_amount;



    function beforeEach()
    {
		sheet_id            = 1;
        all_amount          = 60;
        available_amount    = 40;
        frozen_amount       = 20;


        user_a          =   new User();
        user_b          =   new User();
        user_list       =   new UserList();
        contract_addr   =   new ContractAddress();
        market          =   new Market();
        create_id       =   new CreateID();
        admin           =   new Admin();

		market_name     = "market";
        create_id_name  = "create_id";
        user_list_name  = "user_list";
        admin_name      = "admin";
        user_a_id       = "I am user a";
        user_b_id       = "I am user b";

		contract_addr.setContractAddress(market_name, market);
        contract_addr.setContractAddress(create_id_name, create_id);
        contract_addr.setContractAddress(user_list_name, user_list);
        contract_addr.setContractAddress(admin_name, admin);

		market.setContractAddress(contract_addr);
        market.setCreateIDName(create_id_name);
        market.setUserListName(user_list_name);

        user_list.addUser(user_a,user_a,user_a_id,1);
        user_list.addUser(user_b,user_b,user_b_id,1);

        admin.init(contract_addr, user_list_name);

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

	 //测试摘牌
    function testDelistRequest()
    {

        //user_a 挂牌
        uint sell_price = 100;
        uint sell_qty = 10;
        user_a.insertSheet(user_a_id,"SR","make_date","level_id","wh_id","产地",all_amount,frozen_amount,available_amount);

        user_a.insertFunds(1000);      //初始化资金
		user_a.setFee(5);

       var ret_market_id = user_a.listRequest(user_a_id,sheet_id,sell_price,sell_qty);

        //user_b 摘牌
        user_b.insertFunds(1000);      //初始化资金
		user_a.setFee(5);
        uint buy_qty = 2;
        var ret_delist = user_b.delistRequest(user_b_id, ret_market_id, buy_qty);
        			     user_b.delistRequest(user_b_id, ret_market_id, buy_qty);
        			   	 user_b.delistRequest(user_b_id, ret_market_id, buy_qty);
        admin.confirmList(0);
        admin.confirmList(1);
		admin.confirmList(2);
        var ret_b_funds =  user_b.getAvaFunds();

        Assert.equal(ret_market_id, 1, "");
        Assert.equal(ret_delist, 0, "");
        Assert.equal(market.getMarketNum(), 1, "");
        Assert.equal(user_a.getTradeNum(), 3, "");
        Assert.equal(user_b.getTradeNum(), 3, "");

        Assert.equal(admin.getConfirmListReqSize(), 3, "");
        Assert.equal(user_a.getSheetAllAmount(sheet_id),54,"");
 		Assert.equal(user_a.getTotalFunds(), 157000, "");
 		Assert.equal(user_a.getAvaFunds(), 157000, "");
        Assert.equal(user_b.getSheetAllAmount(2),6,"");
 		Assert.equal(user_b.getTotalFunds(), 40000, "");
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
        admin.confirmNeg(0);

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

