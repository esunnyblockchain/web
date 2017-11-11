pragma solidity ^0.4.11;
import "./LibString.sol";
import "./LibArray.sol";
import "./StructTrade.sol";
import "./StructMarket.sol";
library LibTradeMap
{
    using LibString for *;
    struct TradeMap
    {
        mapping(uint => StructTrade.value) data;
        uint[] keyIndex;
    }

    function insert(TradeMap storage self, uint k, StructTrade.value v)  internal returns (bool replaced)
    {
        replaced = true;
        if(self.data[k].user_id_ == "")
        {
            self.keyIndex.push(k);
            replaced = false;
        }
        self.data[k] = v;
    }
    function insert(TradeMap storage self, uint k, uint trade_date, bytes32 opp_user_id, bytes32 bs, uint confirm_qty, StructMarket.value storage market_value) internal returns (bool replaced)
    {
        replaced = true;
        if(self.data[k].user_id_ == "")
        {
            self.keyIndex.push(k);
            replaced = false;
        }
        self.data[k].trade_date_ = trade_date;
        self.data[k].trade_id_ = k;
        self.data[k].sheet_id_ = market_value.sheet_id_;
        self.data[k].bs_ = bs;
        self.data[k].price_ = market_value.price_;
        self.data[k].trade_qty_ = confirm_qty;
        //uint        fee_;               //手续费
        //uint        transfer_money_;    //已划货款
        //uint        remainder_money_;   //剩余货款
        self.data[k].opp_id_ = opp_user_id;
        self.data[k].user_id_ = market_value.user_id_;//TODO 根据买卖标志取自己的id
        //string      trade_state_;       //交收状态
        //string      trade_type_         //交易方式
    }

    /*
    function update(TradeMap storage self, uint k, uint all_amount, uint available_amount, uint frozen_amount) internal
    {
        self.data[k].all_amount_ = all_amount;
        self.data[k].available_amount_ = available_amount;
        self.data[k].frozen_amount_ = frozen_amount;
    }
    */
    function remove(TradeMap storage self, uint k) internal returns (bool existed)
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
    function getValue(TradeMap storage self, uint k) internal returns (StructTrade.value)
    {
        return self.data[k];
    }
    
    function isExisted(TradeMap storage self, uint k) internal returns (bool existed)
    {
        existed  = LibArray.isExisted(self.keyIndex, k);
    }
   
    function empty(TradeMap storage self) internal returns (bool)
    {
        return (self.keyIndex.length == 0);
    }
    function it_start(TradeMap storage self) internal returns (uint)
    {
        if(empty(self))
                return uint(-1);
        return 0;
    }
    function it_next(TradeMap storage self, uint it) internal returns (uint)
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
    function it_valid(TradeMap storage, uint it) internal returns (bool)
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
    function getValueByIndex(TradeMap storage self, uint it) internal returns (StructTrade.value)
    {
        if(it + 1 > self.keyIndex.length)
        {
            StructTrade.value memory empty_value;
            return empty_value;
        }
        return self.data[ self.keyIndex[it] ];
    }
    /*
    function getKey(TradeMap storage self, uint it) internal returns (bytes32)
    {
        return self.keyIndex[it];
    }
    */
    function size(TradeMap storage self) internal returns(uint)
    {
        return self.keyIndex.length;
    }
    function length(TradeMap storage self) internal returns(uint)
    {
        return self.keyIndex.length;
    }
}
