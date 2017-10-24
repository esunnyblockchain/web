pragma solidity ^0.4.11;
import "./LibString.sol";
import "./LibArray.sol";
import "./StructSheet.sol";
library LibSheetMap
{
    using LibString for *;
    struct SheetMap
    {
        mapping(uint => StructSheet.value) data;
        uint[] keyIndex;
    }

    function insert(SheetMap storage self, uint k, StructSheet.value v)  internal returns (bool replaced)
    {
        replaced = true;
        if(self.data[k].user_id_ == "")
        {
            self.keyIndex.push(k);
            replaced = false;
        }
        self.data[k] = v;
    }
    function update(SheetMap storage self, uint k, uint all_amount, uint available_amount, uint frozen_amount) internal
    {
        self.data[k].all_amount_ = all_amount;
        self.data[k].available_amount_ = available_amount;
        self.data[k].frozen_amount_ = frozen_amount;
    }
    function remove(SheetMap storage self, uint k) internal returns (bool existed)
    {
        if(self.data[k].user_id_ == "")
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
    function getValue(SheetMap storage self, uint k) internal returns (StructSheet.value)
    {
        return self.data[k];
    }
    /*
    function isExisted(SheetMap storage self, bytes32 k) internal returns (bool existed)
    {
        var (ret, ) = LibString.inArray(k, self.keyIndex);
        return ret;
    }
    */
    function empty(SheetMap storage self) internal returns (bool)
    {
        return (self.keyIndex.length == 0);
    }
    function it_start(SheetMap storage self) internal returns (uint)
    {
        if(empty(self))
                return uint(-1);
        return 0;
    }
    function it_next(SheetMap storage self, uint it) internal returns (uint)
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
    function it_valid(SheetMap storage, uint it) internal returns (bool)
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
    function getValueByIndex(SheetMap storage self, uint it) internal returns (StructSheet.value)
    {
        if(it + 1 > self.keyIndex.length)
        {
            StructSheet.value empty_value;
            return empty_value;
        }
        return self.data[ self.keyIndex[it] ];
    }
    /*
    function getKey(SheetMap storage self, uint it) internal returns (bytes32)
    {
        return self.keyIndex[it];
    }
    */
    function size(SheetMap storage self) internal returns(uint)
    {
        return self.keyIndex.length;
    }
    function length(SheetMap storage self) internal returns(uint)
    {
        return self.keyIndex.length;
    }
}
