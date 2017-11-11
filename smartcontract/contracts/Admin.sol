pragma solidity ^0.4.11;

import "./lib/LibString.sol";
import "./ContractAddress.sol";
import "./UserList.sol";
import "./User.sol";

contract Admin
{
    struct ConfirmListReq
    {
        bytes32 user_id_;
        bytes32 user_sell_id_;
        uint    trade_id_;
        bool    status_;
    }
    struct ConfirmNegReq
    {
        bytes32 user_id_;
        bytes32 user_sell_id_;
        uint    trade_id_;
        bool    status_;
    }

    ContractAddress     contract_address;
    UserList            user_list;
    ConfirmListReq[]    confirm_list_req;
    ConfirmNegReq[]     confirm_neg_req;
    User                user;
    User                user_sell;

    function init(address addr, string user_list_name)
    {
        contract_address = ContractAddress(addr);
        user_list =  UserList(contract_address.getContractAddress(user_list_name));
    }

    function insertConfirmListReq(bytes32 user_id, bytes32 user_sell_id,uint trade_id)
    {
        confirm_list_req.push( ConfirmListReq(user_id,user_sell_id,trade_id,false));
    }

    function insertConfirmNegReq(bytes32 user_id, bytes32 user_sell_id, uint trade_id)
    {
        confirm_neg_req.push( ConfirmNegReq(user_id,user_sell_id,trade_id,false));
    }

    //确认挂牌交易
    function confirmList(uint index)
    {
        user        = User(user_list.getUserAgentAddr(confirm_list_req[index].user_id_));
        user_sell   = User(user_list.getUserAgentAddr(confirm_list_req[index].user_sell_id_));
        user.confirmList(confirm_list_req[index].trade_id_);
        user_sell.confirmList(confirm_list_req[index].trade_id_);
        confirm_list_req[index].status_  =   true;
    }

    //确认协商交易
    function confirmNeg(uint index)
    {
        user        = User(user_list.getUserAgentAddr(confirm_neg_req[index].user_id_));
        user_sell   = User(user_list.getUserAgentAddr(confirm_neg_req[index].user_sell_id_));
        user.confirmNeg(confirm_neg_req[index].trade_id_);
        user_sell.confirmNeg(confirm_neg_req[index].trade_id_);
        confirm_neg_req[index].status_   =   false;
    }
    
    //添加用户
    /*
    function addUser(bytes32 user_id, address external_addr)
    {
        user = new User();
        user.setContractAddress(contract_address);
        user.setMarketName("Market");
        user.setCreateIDName("CreateID");
        user.setUserListName("UserList");
        user.setUserID(user_id);
        user.setAdmin("Admin");
        user_list.addUser(external_addr,user,user_id,1);
    }
    */
    function addUser(address external_addr, bytes32 user_id, bytes32 class_id, bytes32 make_date,
                    bytes32 lev_id, bytes32 wh_id, bytes32 place_id, uint all_amount,
                    uint frozen_amount, uint available_amount, uint funds)
    {//TODO 重复用户判断
        user = new User();
        user.setContractAddress(contract_address);
        user.setMarketName("Market");
        user.setCreateIDName("CreateID");
        user.setUserListName("UserList");
        user.setUserID(user_id);
        user.setAdmin("Admin");
        user_list.addUser(external_addr,user,user_id,1);
        user.insertSheet(user_id, class_id, make_date, lev_id, wh_id, place_id, all_amount, frozen_amount, available_amount);
        user.insertFunds(funds);
    }

    //删除用户
    function delUser(bytes32 user_id)
    {
            user_list.delUserInfo(user_id);
    }
    //获取挂牌交易确认请求列表的长度
    function getConfirmListReqSize() returns(uint)
    {
            return confirm_list_req.length; 
    }

    //获取协商交易确认请求列表的长度
    function getConfirmNegReqSize() returns(uint)
    {
            return confirm_neg_req.length; 
    }

    //获取挂牌交易确认请求列表的元素
    /*
    function getConfirmListReq(uint index) returns(string user_id,string user_sell_id,uint trade_id,bool status)
    {
            user_id         =   LibString.bytes32ToString(confirm_list_req[index].user_id_);
            user_sell_id    =   LibString.bytes32ToString(confirm_list_req[index].user_sell_id_);
            trade_id        =   confirm_list_req[index].trade_id_;
            status          =   confirm_list_req[index].status_;
    }
    */

    //获取协商交易确认请求列表的元素
    /*
    function getConfirmNegReq(uint index) returns(string user_id,string user_sell_id,uint trade_id,bool status)
    {
            user_id         =   LibString.bytes32ToString(confirm_neg_req[index].user_id_);
            user_sell_id    =   LibString.bytes32ToString(confirm_neg_req[index].user_sell_id_);
            trade_id        =   confirm_neg_req[index].trade_id_;
            status          =   confirm_neg_req[index].status_;
    }
    */
}
