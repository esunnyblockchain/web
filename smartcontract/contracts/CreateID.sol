pragma solidity ^0.4.5;
contract CreateID
{
    uint        sheet_id_;    //仓单id
    uint        trade_id_;        //合同id
    uint        neg_id_;        //协商id
    uint        market_id_;
    
    //创建仓单id
    function getSheetID() returns(uint)
    {
        return ++sheet_id_;
    }

    //创建合同id
    function getTradeID() returns(uint )
    {
        return ++trade_id_;
    }
    
    //创建协商交易编号
    function getNegID() returns(uint )
    {
        return  ++neg_id_;
    }
    function getMarketID() returns(uint)
    {
        return ++market_id_;
    }
}

