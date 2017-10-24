pragma solidity ^0.4.11;
import "./lib/StructAddressInfo.sol";
import "./lib/LibAddressMap.sol";
contract ContractAddress
{
    using LibAddressMap for LibAddressMap.AddressMap;
    LibAddressMap.AddressMap address_map;

    function  setContractAddress(string contract_name, address addr)
    {
        address_map.insert(contract_name, StructAddressInfo.value(addr));
    }
    function delContractAddress(string contract_name)
    {
        address_map.remove(contract_name);
    }
    function getContractNum() returns (uint)
    {
        return address_map.size();
    }
    function getSize() returns (uint)
    {
        return getContractNum();
    }
    /*
    function getValueByIndex(uint index) returns (address addr)
    {
        if(index < getSize())
        {
            addr = address_map.getValue(index);
        }
        return addr;
    }
    */
    function getAddressByIndex(uint index) returns (address addr)
    {
        if(index < getSize())
        {
            addr = address_map.getValue(index).addr;
        }
        return addr;
    }
    function getKeyByIndex(uint index) returns (string key) //only use for *.js
    {
        if(index < getSize())
        {
            key = address_map.getKey(index);
        }
        return key;
    }
    function getContractAddress(string contract_name) returns (address)
    {
        return address_map.getValue(contract_name);        
    }
}
