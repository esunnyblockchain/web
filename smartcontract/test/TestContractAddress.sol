pragma solidity ^0.4.11;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ContractAddress.sol";
import "../contracts/User.sol";
contract TestContractAddress
{
    ContractAddress contract_address;
    address         addr;
    address         addr_1;
    address         addr_2;
    string          contract_name;
    string          contract_name_1;
    string          contract_name_2;

    function beforeEach()
    {
        contract_address = new ContractAddress();
        addr = new User();
        addr_1 = new User();
        addr_2 = new User();
        contract_name = "test";
        contract_name_1 = "test1";
        contract_name_2 = "test2";
    }
    function testSetGet_normal()
    {
        contract_address.setContractAddress(contract_name, addr);
        Assert.equal(contract_address.getContractAddress(contract_name), addr, "");
    }
    function testGet_no_existed_key()
    {
        Assert.equal(contract_address.getContractAddress("no_existed_key"), 0x0, "");
    }
    function testGetSize_empty_map()
    {
        Assert.equal(contract_address.getSize(), 0, "");
    }
    function testGetSize_with_add_del_element()
    {
        contract_address.setContractAddress(contract_name, addr); //add
        Assert.equal(contract_address.getSize(), 1, "");
        contract_address.delContractAddress(contract_name); //del
        Assert.equal(contract_address.getSize(), 0, "");
        contract_address.delContractAddress(contract_name); //repeat del
        Assert.equal(contract_address.getSize(), 0, "");
    }
    function testTraverse_null_map()
    {
        uint size = contract_address.getSize();
        for(uint index = 0; index < size; ++index)
        {
            Assert.equal(true, false, "Impossible to trigger");
        }
    }
    function testTraverse_normal_map()
    {
        contract_address.setContractAddress(contract_name, addr);
        contract_address.setContractAddress(contract_name_1, addr_1);
        contract_address.setContractAddress(contract_name_2, addr_2);
        uint size = contract_address.getSize();
        for(uint index = 0; index < size; ++index)
        {
            if(index == 0)
            {
                Assert.equal(contract_address.getAddressByIndex(index), addr, "");
            }
            else if(index == 1)
            {
                Assert.equal(contract_address.getAddressByIndex(index), addr_1, "");
            }
            else if(index == 2)
            {
                Assert.equal(contract_address.getAddressByIndex(index), addr_2, "");
            }
            else
            {
                Assert.equal(true, false, "Impossible to trigger");
            }
        }
        Assert.equal(index, 3, "");
    }
}
