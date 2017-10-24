pragma solidity ^0.4.11;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/lib/StructUserAddr.sol";
import "../contracts/UserList.sol";
import "../contracts/User.sol";
contract TestUserList
{
    address extern_addr;
    address agent_addr;
    bytes32 user_a;
    bytes32 user_b;
    int     user_auth;
    UserList user_list;

    function beforeEach()
    {
        extern_addr = new User(); //只是测试，生成一个地址，真实的外部地址，不是User合约的地址
        agent_addr  = new User();
        user_a     =   "user_a";
        user_b     =   "user_b";
        user_auth   = 1;
        user_list   = new UserList();
    }
    function testAddUser_only_add_one()
    {
       user_list.addUser(extern_addr, agent_addr, user_a, user_auth); 
       Assert.equal(user_list.getUserNum(), 1, "");
    }

    function testAddUser_add_two_same_value()
    {
       user_list.addUser(extern_addr, agent_addr, user_a, user_auth); 
       Assert.equal(user_list.getUserNum(), 1, "");

       user_list.addUser(extern_addr, agent_addr, user_a, user_auth); //repeate add some value
       Assert.equal(user_list.getUserNum(), 1, "");
    }

    function testAddUser_add_two_differ_value()
    {
       user_list.addUser(extern_addr, agent_addr, user_a, user_auth); 
       Assert.equal(user_list.getUserNum(), 1, "");

       user_list.addUser(extern_addr, agent_addr, user_b, user_auth); //repeate add some value
       Assert.equal(user_list.getUserNum(), 2, "");
    }

    function testGetUserInfo_by_non_existed_user_id()
    {
        var(ret_extern_addr , ret_agent_addr, ret_user_id, ret_user_auth) = user_list.getUserInfo("non_exist_user");
        Assert.equal(ret_user_auth, 0, "");
        Assert.equal(ret_user_id, "", "");
    }
    function testGetUserInfo_by_right_user_id()
    {
       user_list.addUser(extern_addr, agent_addr, user_a, user_auth); 
       user_list.addUser(extern_addr, agent_addr, user_b, user_auth); //repeate add some value
       var(ret_extern_addr , ret_agent_addr, ret_user_id, ret_user_auth) = user_list.getUserInfo(user_a);
       Assert.equal(ret_user_id, user_a, "");
    }

    function testGetUserInfo_by_non_exist_index()
    {
       user_list.addUser(extern_addr, agent_addr, user_a, user_auth); 
       user_list.addUser(extern_addr, agent_addr, user_b, user_auth); //repeate add some value
       var(ret_extern_addr , ret_agent_addr, ret_user_id, ret_user_auth) = user_list.getUserInfoByIndex(3);     //3 exceed index.length
       Assert.equal(ret_user_id, "", "");
       Assert.equal(ret_user_auth, 0, "");
    }
    function testGetUserInfo_by_right_index()
    {
       user_list.addUser(extern_addr, agent_addr, user_a, user_auth); 
       user_list.addUser(extern_addr, agent_addr, user_b, user_auth); //repeate add some value
       uint user_num = user_list.getUserNum();
       Assert.equal(user_num, 2, "");
       for(uint index = 0; index < user_num; ++index)
       {
               var(ret_extern_addr , ret_agent_addr, ret_user_id, ret_user_auth) = user_list.getUserInfoByIndex(index);
               if(index == 0)
               {
                    Assert.equal(ret_user_id, user_a, "");
               }
               else if(index == 1)
               {
                    Assert.equal(ret_user_id, user_b, "");
               }
               else
               {
                    Assert.equal(true, false, "Impossible to trigger");
               }
       }
    }
    function testDelUserInfo_by_non_existed_user_id()
    {
       user_list.addUser(extern_addr, agent_addr, user_a, user_auth); 
       user_list.addUser(extern_addr, agent_addr, user_b, user_auth); //repeate add some value
       uint user_num = user_list.getUserNum();
       Assert.equal(user_num, 2, "");
       user_list.delUserInfo("non_existed_user_id");
       Assert.equal(user_num, 2, "");
    }
    function testDelUserInfo_by_existed_user_id()
    {
       user_list.addUser(extern_addr, agent_addr, user_a, user_auth); 
       user_list.addUser(extern_addr, agent_addr, user_b, user_auth); //repeate add some value
       Assert.equal(user_list.getUserNum(), 2, "");
       user_list.delUserInfo(user_a);
       Assert.equal(user_list.getUserNum(), 1, "");
    }
}
