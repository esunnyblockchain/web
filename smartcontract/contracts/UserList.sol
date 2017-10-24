pragma solidity ^0.4.11;
 
import "./lib/StructUserAddr.sol";
import "./lib/LibUserAddrMap.sol";

contract UserList
{
    using LibUserAddrMap for LibUserAddrMap.UserAddrMap;
    LibUserAddrMap.UserAddrMap   user_map;
    StructUserAddr.value user_addr;

    function addUser(address external_addr, address agent_addr, bytes32 user_id, int user_auth)
    {
        user_map.insert(user_id, StructUserAddr.value(external_addr, agent_addr, user_id, user_auth));
    }
    function getUserInfo(bytes32 user_id) returns(address external_addr, address agent_addr, bytes32 ret_user_id, int user_auth)
    {
        user_addr    = user_map.getValue(user_id);
        external_addr           = user_addr.extern_addr_;
        agent_addr              = user_addr.agent_addr_;
        ret_user_id             = user_addr.user_id_;
        user_auth               = user_addr.user_auth_;
    }
    function getUserAgentAddr(bytes32 user_id) returns(address agent_addr)
    {
        user_addr    = user_map.getValue(user_id);
        agent_addr   = user_addr.agent_addr_;
    }
    function getUserNum() returns (uint)
    {
        return user_map.size();
    }
    function getUserInfoByIndex(uint index) returns(address external_addr, address agent_addr, bytes32 ret_user_id, int user_auth)
    {
        user_addr  = user_map.getValue(index);
        external_addr           = user_addr.extern_addr_;
        agent_addr              = user_addr.agent_addr_;
        ret_user_id             = user_addr.user_id_;
        user_auth               = user_addr.user_auth_;
    }
    function delUserInfo(bytes32 user_id)
    {
        user_map.remove(user_id);
    }
}
