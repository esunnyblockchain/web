pragma solidity ^0.4.11;
library StructMarket {
    struct  value 
    {
        uint        date_;      //挂牌日期
        uint        market_id_;        //挂牌编号
        uint        sheet_id_;    //仓单编号
        bytes32      class_id_;      //品种代码
        bytes32      make_date_;     //产期
        bytes32      lev_id_;        //等级
        bytes32      wh_id_;         //仓库代码
        bytes32      place_id_;      //产地代码
        bytes32      type_;      //报价类型
        uint        price_;         //价格（代替浮点型）
        uint        list_qty_;       //挂牌量
        uint        deal_qty_;      //成交量
        uint        rem_qty_;       //剩余量
        bytes32      deadline_;  //挂牌截止日
        uint        dlv_unit_;      //交割单位
        bytes32      user_id_;       //用户id
        address     seller_addr_;   //卖方地址
    }
}
