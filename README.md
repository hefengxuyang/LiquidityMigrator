# LiquidityMigrator

LiquidityMigrator migrate the liquity which contains the same two tokens between pools for bnb chains.

## 安装依赖

安装依赖包：
```sh
yarn 

or

npm i
```

编译合约：
```sh
truffle compile
```

设置环境变量：
```sh
export PRIVATE_KEY="0x......"
```

部署合约：
```sh
truffle migrate --network bsctest
```


## BSC 测试网配置

```sh
Network Name：BSC Testnet
New RPC URL ：https://data-seed-prebsc-1-s1.binance.org:8545/
Chain ID：97
Currency symbol：BNB
Block Explorer URL：https://testnet.bscscan.com
```

测试合约参数：

user： 0x9Ba9Ae032a2709efb6eB5651b78058F19f01A38C

BUSD： 0x8301f2213c0eed49a7e28ae4c3e91722919b8b47
