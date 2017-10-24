pragma solidity ^0.4.5;
import "./LibString.sol";
import "./LibArray.sol";
import {StructAddressInfo as Data} from "./StructAddressInfo.sol";
library LibAddressMap
{
    using LibString for *;
    struct AddressMap
    {
        mapping(string => Data.value) data;
        string[] keyIndex;
    }

    function insert(AddressMap storage self, string k, Data.value v)  internal returns (bool replaced)
    {
        replaced = true;
        if(self.data[k].addr == 0x0)
        {
            self.keyIndex.push(k);
            replaced = false;
        }
        self.data[k] = v;
    }
    function remove(AddressMap storage self, string k) internal returns (bool existed)
    {
        if(self.data[k].addr == 0x0)
        {
            return false;
        }
        else
        {
            delete self.data[k];
            LibArray.deleteElement(self.keyIndex, k);
            return true;
        }
    }
    function getValue(AddressMap storage self, string k) internal returns (address)
    {
        return self.data[k].addr;
    }
    function isExisted(AddressMap storage self, string k) internal returns (bool existed)
    {
        var (ret, ) = LibString.inArray(k, self.keyIndex);
        return ret;
    }
    function empty(AddressMap storage self) internal returns (bool)
    {
        return (self.keyIndex.length == 0);
    }
    function it_start(AddressMap storage self) internal returns (uint)
    {
        if(empty(self))
                return uint(-1);
        return 0;
    }
    function it_next(AddressMap storage self, uint it) internal returns (uint)
    {
        it++;
        if(it < self.keyIndex.length)
            return it;
        else
            return uint(-1);
    }

    function it_valid(uint it) internal returns (bool)
    {
        if( (uint(-1) != it) )
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    function it_valid(AddressMap storage, uint it) internal returns (bool)
    {
        if( (uint(-1) != it) )
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    function getValue(AddressMap storage self, uint it) internal returns (Data.value)
    {
        if(it + 1 > self.keyIndex.length)
        {
            Data.value empty_value;
            return empty_value;
        }
        return self.data[ self.keyIndex[it] ];
    }
    function getKey(AddressMap storage self, uint it) internal returns (string)
    {
        return self.keyIndex[it];
    }
    function size(AddressMap storage self) internal returns(uint)
    {
        return self.keyIndex.length;
    }
    function length(AddressMap storage self) internal returns(uint)
    {
        return self.keyIndex.length;
    }
}
