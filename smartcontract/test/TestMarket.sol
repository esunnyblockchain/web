pragma solidity ^0.4.11;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ContractAddress.sol";
import "../contracts/Market.sol";
import "../contracts/CreateID.sol";
import "../contracts/lib/StructMarket.sol";
contract TestMarket
{
    Market market;
    ContractAddress contract_address;
    string create_id_name = "id_name";
    
    // market element start
    uint sheet_id       = 5;
    uint market_date    = now;
    bytes32 make_date    = "2017XXXX";
    bytes32 class_id     = "SR";
    bytes32 lev_id       = "super";
    bytes32 wh_id        = "ss";
    bytes32 place_id     = "henan";
    bytes32 market_type  = "a price";
    uint price          = 1999;
    uint list_qty       = 10;
    uint deal_qty       = 5;
    uint rem_qty        = 0;
    bytes32 deadline     = "2018999";
    uint dlv_unit       = 100;
    bytes32 user_id      = "userA";
    address seller_addr;
    // market element end
    StructMarket.value market_value;

    function beforeEach()
    {
        market              = new Market();
        contract_address    = new ContractAddress();
        CreateID create_id  = new CreateID();

        contract_address.setContractAddress(create_id_name, create_id);

        market.setContractAddress(contract_address);
        market.setCreateIDName(create_id_name);
    }
    function testGetMarketID_one_time()
    {
       Assert.equal(market.getMarketID(), 1, ""); 
    }
    function testGetMarketID_two_time()
    {
       Assert.equal(market.getMarketID(), 1, ""); 
       Assert.equal(market.getMarketID(), 2, ""); 
    }
    function testInsertMarket()
    {
            market.insertMarket_1(
                sheet_id,
                class_id, 
                make_date,   
                lev_id, 
                wh_id, 
                place_id);
            var (id,date) = market.insertMarket_2(
                price, 
                list_qty, 
                deal_qty,
                rem_qty, 
                deadline, 
                dlv_unit, 
                user_id);
       Assert.equal(id, 1, ""); 
       Assert.equal(market.getMarketNum(), 1, "");
    }
    function testGetMarket1_by_non_existed_market_id()
    {
            market.insertMarket_1(
                sheet_id,
                class_id, 
                make_date,   
                lev_id, 
                wh_id, 
                place_id);
            var (id,date) = market.insertMarket_2(
                price, 
                list_qty, 
                deal_qty,
                rem_qty, 
                deadline, 
                dlv_unit, 
                user_id);
        var(ret_date,ret_market_id,ret_sheet_id,ret_class_id,ret_make_date,ret_lev_id,ret_wh_id,ret_place_id,ret_price_type) 
            = market.getMarket_1(3333); //3333 is a non existed id
        Assert.equal(ret_date, 0 , "");
    }
    function testGetMarket2_by_non_existed_market_id()
    {
            market.insertMarket_1(
                sheet_id,
                class_id, 
                make_date,   
                lev_id, 
                wh_id, 
                place_id);
            var (id,date) = market.insertMarket_2(
                price, 
                list_qty, 
                deal_qty,
                rem_qty, 
                deadline, 
                dlv_unit, 
                user_id);
        var(ret_price,ret_list_qty,ret_deal_qty,ret_rem_qty,ret_deadline,ret_dlv_unit,ret_user_id,ret_sell_addr) 
            = market.getMarket_2(3334); //3334 is a non existed 
        Assert.equal(ret_price, 0 , "");
    }
    function testGetMarketIdByIndex_by_non_existed_index()
    {
        var id = market.getMarketIdByIndex(3322);
        Assert.equal(id, 0, "");
    }
    function testGetMarketIdByIndex_by_existed_index()
    {
        market.insertMarket_1(
                        sheet_id,
                        class_id, 
                        make_date,   
                        lev_id, 
                        wh_id, 
                        place_id);
        var (id,date) = market.insertMarket_2(
                        price, 
                        list_qty, 
                        deal_qty,
                        rem_qty, 
                        deadline, 
                        dlv_unit, 
                        user_id);
        Assert.equal(id, 1, ""); 
        var ret_id = market.getMarketIdByIndex(0); //first element
        Assert.equal(id, ret_id, "");
    }
    function testGetDynamicMarket_by_existed_market_id()
    {
        market.insertMarket_1(
                        sheet_id,
                        class_id, 
                        make_date,   
                        lev_id, 
                        wh_id, 
                        place_id);
        var (id,date) = market.insertMarket_2(
                        price, 
                        list_qty, 
                        deal_qty,
                        rem_qty, 
                        deadline, 
                        dlv_unit, 
                        user_id);
        Assert.equal(id, 1, ""); 
        var(sell_user_id, ret_deal_qty, ret_rem_qty) = market.getDynamicMarket(id); //first element
        Assert.equal(user_id, sell_user_id, "");
        Assert.equal(deal_qty, ret_deal_qty, "");
        Assert.equal(rem_qty, ret_rem_qty, "");
    }
}
