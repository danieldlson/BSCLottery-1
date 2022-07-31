# BSC Lottery 

This Repository Contains the Source Code of a Lottery Program which is Programmed by Solidity and Deployed on Rinkeby and Binance Smart Chain Testnet. 

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

* *Node* v14.18.3
* *NPM* v6.14.10
* *Ganache CLI* v6.12.2 (ganache-core: 2.13.2)
* *Truffle* v5.4.16 (core: 5.4.16)
* *Solidity* v0.8.13 (solc-js)
* *Web3.js* v1.5.3
* *truffle-hdwallet-provider* v2.0.4
* *OpenZeppelin* v4.5.0
* *ChainLink* v0.4.0

### Additional Libraries Used

-  **Truffle**: To compile, test and migrate contracts.
-  **Solidity**: To compile Solidity codes.  
-  **Web3**: To Connect on BlockChain.
-  **truffle-hdwallet-provider**: Used to Manage connection to Wallet from Truffle.
-  **OpenZeppelin**: For Increase Security of Smart Contracts.
-  **ChainLink**: For Generating Random Number with ChainLink VRF v2 Library.
-  **Infura**: For Deploying Smart Contract.


### Installing

Clone this repository:

```
git clone https://github.com/baties/BSCLottery.git
```

Then Install all requisite npm packages (as listed in ```package.json```):

```
npm install
```

Launch Ganache:

```
ganache-cli 
```

In a separate terminal window, Compile smart contracts:

```
truffle compile --all
```

This will create the smart contract artifacts in folder ```build\contracts```.

Migrate smart contracts to the locally running blockchain, ganache-cli:

```
truffle migrate --reset
```

Test smart contracts: 

```
truffle test
```

All tests should pass.


In a separate terminal window, launch the DApp:

```
cd App/lottery
npm run dev
```

## Built With

* [Ethereum](https://www.ethereum.org/) - Ethereum is a decentralized platform that runs smart contracts.
* [Truffle Framework](http://truffleframework.com/) - Truffle is the most popular development framework for Ethereum with a mission to make your life a lot easier.
* [ChainLink](https://chain.link/) - Securely connect smart contracts with off-chain data and services.
* [OpenZeppelin](https://www.openzeppelin.com/) - The standard for secure blockchain applications.

## Acknowledgments

* Solidity  
* Ganache-cli
* Truffle

## Building & Running Notes 
* **VRF V2** :
    - In the new Version The Project can not be built under Ganache local Development because of useing VRFv2 Which is not accessible outside Testnet.
    - Please Replace the VRFv2 with randomGenerator to running The Test Module on local Development Platform without any problem. 
    - In the next Version The Test Module will be fully compatible with VRFv2.

## Example workflow

* User identifies himself/herself with Metamask wallet.
* User can check his/her Balance in current Pot.
* User press Start to contribute in current Pot.
* User send some BNB(ETH) to the Smart Contract (Multiple of 0.01 BNB(ETH)).
* The Lottery Smart-Contract starts Lottery Process and choses the Winner of current Pot.   
* The Winner Prize will be transfered to the Winner Wallet.
* The result will be shown to the all users.




