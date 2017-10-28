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

    //创建仓单
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

    //更新仓单数量
    function update(SheetMap storage self, uint k, uint all_amount, uint available_amount, uint frozen_amount) internal
    {
        self.data[k].all_amount_ = all_amount;
        self.data[k].available_amount_ = available_amount;
        self.data[k].frozen_amount_ = frozen_amount;
    }

    //增加仓单
    function add(SheetMap storage self,uint k, uint qty)
    {
        self.data[k].all_amount_        += qty;
        self.data[k].available_amount_  += qty;

    }

    //减少仓单
    function reduce(SheetMap storage self, uint k, uint qty)
    {
        self.data[k].all_amount_ -=  qty;
    }

    //冻结仓单
    function freeze(SheetMap storage self, uint k, uint qty)
    {
        self.data[k].available_amount_  -=  qty;
        self.data[k].frozen_amount_      += qty;
    }

    //移除仓单
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

    //判断该种仓单是否存在
    function isExisted(SheetMap storage self, bytes32 class_id, bytes32 make_date, bytes32 lev_id, bytes32 wh_id, bytes32 place_id) internal returns (bool)
    {
        for(uint i = 0; i < self.keyIndex.length; i++)
        {
            if( self.data[i].class_id_ == class_id && self.data[i].make_date_ == make_date && self.data[i].lev_id_ == lev_id && self.data[i].wh_id_ == wh_id && self.data[i].place_id_ == place_id) 
                return true;
        }
        return false;
    }

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
