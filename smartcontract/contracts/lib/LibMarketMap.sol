pragma solidity ^0.4.11;
import "./LibString.sol";
import "./LibArray.sol";
import "./StructMarket.sol";
library LibMarketMap
{
    using LibString for *;
    struct MarketMap
    {
        mapping(uint => StructMarket.value) data;
        uint[] keyIndex;
    }

    function insert(MarketMap storage self, uint k, StructMarket.value v)  internal returns (bool replaced)
    {
        replaced = true;
        if(self.data[k].dlv_unit_ == 0)
        {
            self.keyIndex.push(k);
            replaced = false;
        }
        self.data[k] = v;
    }
    function update(MarketMap storage self, uint k, uint deal_qty, uint rem_qty) internal
    {
       self.data[k].deal_qty_ = deal_qty; 
       self.data[k].rem_qty_ = rem_qty; 
    }
    function remove(MarketMap storage self, uint k) internal returns (bool existed)
    {
        if(self.data[k].dlv_unit_ == 0)
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
    function getValue(MarketMap storage self, uint k) internal returns (StructMarket.value)
    {
        return self.data[k];
    }
    /*
    function isExisted(MarketMap storage self, uint k) internal returns (bool existed)
    {
        var (ret, ) = LibString.inArray(k, self.keyIndex);
        return ret;
    }
    */
    function empty(MarketMap storage self) internal returns (bool)
    {
        return (self.keyIndex.length == 0);
    }
    function it_start(MarketMap storage self) internal returns (uint)
    {
        if(empty(self))
                return uint(-1);
        return 0;
    }
    function it_next(MarketMap storage self, uint it) internal returns (uint)
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
    function it_valid(MarketMap storage, uint it) internal returns (bool)
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
    function getValueByIndex(MarketMap storage self, uint it) internal returns (StructMarket.value)
    {
        if(it + 1 > self.keyIndex.length)
        {
            StructMarket.value empty_value;
            return empty_value;
        }
        return self.data[ self.keyIndex[it] ];
    }
    function getKey(MarketMap storage self, uint it) internal returns (uint)
    {
        if(it + 1 > self.keyIndex.length)
        {
            return 0;
        }
        return self.keyIndex[it];
    }
    function size(MarketMap storage self) internal returns(uint)
    {
        return self.keyIndex.length;
    }
    function length(MarketMap storage self) internal returns(uint)
    {
        return self.keyIndex.length;
    }
}
