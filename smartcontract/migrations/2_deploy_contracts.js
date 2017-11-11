//independ
var CreateID = artifacts.require("CreateID");

//struct
var StructAddressInfo = artifacts.require("StructAddressInfo");
var StructMarket = artifacts.require("StructMarket");
var StructUserAddr = artifacts.require("StructUserAddr");
var StructSheet = artifacts.require("StructSheet");
var StructTrade = artifacts.require("StructTrade");

//lib
var LibArray = artifacts.require("LibArray");
var LibString = artifacts.require("LibString");
var LibAddressMap = artifacts.require("LibAddressMap");
var LibMarketMap = artifacts.require("LibMarketMap");
var LibUserAddrMap = artifacts.require("LibUserAddrMap");
var LibSheetMap = artifacts.require("LibSheetMap");
var LibTradeMap = artifacts.require("LibTradeMap");

//contract
var ContractAddress = artifacts.require("ContractAddress");
var User = artifacts.require("User");
var UserList = artifacts.require("UserList");
var Market = artifacts.require("Market");
var Proxy = artifacts.require("Proxy");
var Login = artifacts.require("Login");
var Admin = artifacts.require("Admin");

module.exports = function(deployer) {

  //independ
  deployer.deploy(CreateID);

  //struct
  deployer.deploy(StructAddressInfo);
  deployer.deploy(StructMarket);
  deployer.deploy(StructUserAddr);
  deployer.deploy(StructSheet);
  deployer.deploy(StructTrade);

  //lib
  deployer.deploy(LibString);
  deployer.deploy(LibArray);
  deployer.deploy(LibAddressMap);
  deployer.deploy(LibMarketMap);
  deployer.deploy(LibUserAddrMap);
  deployer.deploy(LibSheetMap);
  deployer.deploy(LibTradeMap);

  //befor deploy contract. link lib.
  deployer.link(StructAddressInfo, [ContractAddress]);
  deployer.link(LibArray, [ContractAddress, Market, UserList]);
  deployer.link(LibString, [ContractAddress,Admin]);
  deployer.link(LibAddressMap, [ContractAddress]);

  deployer.link(StructMarket, [Market]);
  deployer.link(LibMarketMap, [Market]);

  deployer.link(StructUserAddr, [UserList]);
  deployer.link(LibUserAddrMap, [UserList]);

  deployer.link(StructSheet, [User]);
  deployer.link(LibSheetMap, [User,Admin]);
  deployer.link(StructTrade, [User]);
  deployer.link(LibTradeMap, [User]);

  //contract
  deployer.deploy(ContractAddress);
  deployer.deploy(Market);
  deployer.deploy(UserList);
  deployer.deploy(Admin);
  deployer.deploy(CreateID);
  deployer.deploy(Proxy);
  deployer.deploy(Login);
};
