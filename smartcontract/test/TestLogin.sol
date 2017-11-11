pragma solidity ^0.4.11;

import "truffle/Assert.sol";
import "../contracts/Admin.sol";
import "../contracts/Login.sol";


contract TestLogin
{
    ContractAddress contract_addr;
    UserList        user_list;
    Admin           admin;
    Login           login;
    string          user_list_name;

    function beforeEach()
    {
        contract_addr   = new ContractAddress();
        user_list       = new UserList();
        admin           = new Admin();
        login           = new Login();

        contract_addr.setContractAddress(user_list_name, user_list);

        admin.init(contract_addr, user_list_name);
        login.init(contract_addr, user_list_name);
    }

    function testVerfication()
    {
        admin.addUser("A", 0x123);
        admin.addUser("B", 0x456);
        admin.addUser("C", 0x789);

        var(ret,user_auth,user_addr_1) = login.verfication("B");
        var(ret_1,user_auth_1,user_addr_2) = login.verfication("B");
        var(ret_2,user_auth_2,user_addr_3) = login.verfication("D");

        //Assert.equal(ret,0,"");
        //Assert.equal(user_auth,1,"");
        //公钥不正确
        Assert.equal(ret_1,-2,"");
        Assert.equal(user_auth_1,0,"");
        //use_id不存在
        Assert.equal(ret_2,-1,"");
        Assert.equal(user_auth_2,0,"");
    }
}
