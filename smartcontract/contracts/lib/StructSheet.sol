pragma solidity ^0.4.11;
library StructSheet{
        struct  value 
        {
            bytes32      user_id_;       //客户id
            uint        sheet_id_;    //仓单序号
            bytes32      class_id_;      //品种id
            bytes32      make_date_;     //产期
            bytes32      lev_id_;        //等级
            bytes32      wh_id_;         //仓库代码
            bytes32      place_id_;      //产地代码
            uint        all_amount_;  //仓单总量
            uint        available_amount_;//可用数量
            uint        frozen_amount_;   //冻结数量   
        }
}
