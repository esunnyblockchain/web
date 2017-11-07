require('babel-register')
module.exports = {
  networks: {
    development: {
      host: '192.168.22.123',
      port: 8545,
      network_id: "*", //match any networkID
	  gas:70000000,
//	  gasprice:1
    }
  }
}
