<p align="center">
    <img src="https://github.com/sayajin-labs/kakarot/blob/main/docs/img/kakarot_github_banner.png?raw=true" height="200">
</p>
<div align="center">
  <h3 align="center">
    Kakarot Ethereum Account Abstraction written in Cairo
  </h3>
</div>

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/Flydexo/kakarot-eth-aa/codecov.yaml?branch=main&style=flat-square&logo=github)
![GitHub](https://img.shields.io/github/license/Flydexo/kakarot-eth-aa?style=flat-square&logo=github)
![GitHub contributors](https://img.shields.io/github/contributors/Flydexo/kakarot-eth-aa?logo=github&style=flat-square)
![GitHub top language](https://img.shields.io/github/languages/top/Flydexo/kakarot-eth-aa?style=flat-square)
[![Telegram](https://img.shields.io/badge/telegram-Kakarot-yellow.svg?logo=telegram)](https://t.me/KakarotZkEvm)
![Contributions welcome](https://img.shields.io/badge/contributions-welcome-green.svg)
![GitHub Repo stars](https://img.shields.io/github/stars/Flydexo/kakarot-eth-aa)
[![Twitter Follow](https://img.shields.io/twitter/follow/KakarotZkEvm?style=social)](https://twitter.com/KakarotZkEvm)

The Kakarot Ethereum Account Abstraction (KETHAA) is an account contract written in Cairo which verifies EVM compatible transactions and executes them inside the [Kakarot ZK EVM](https://kakarot.org) on [Starknet](https://starkware.co/starknet/). 

# What is Kakarot ?

Kakarot is an Ethereum Virtual Machine written in Cairo. It means it can be deployed on StarkNet, a layer 2 scaling solution for Ethereum, and run an EVM bytecode program. Hence, Kakarot can be used to run Ethereum smart contracts on StarkNet. Kakarot is the super sayajin zkEVM! Why? Because: `It's over 9000!!!!!`.

It is a work in progress, and it is not ready for production.

More information [here](https://github.com/sayajin-labs/kakarot/)

# How can we validate Ethereum Transactions on Starknet (non EVM) ?

The core functionality is *Account Abstraction*. On Ethereum, an External Owned Account (EOA) is created with a private key: no need to interact with the blockchain. But it constraints a lot of modularity and customization. On the other side, we have contracts but they must be executed by at least one EOA. Here is where *Account Abstraction* comes into play: it is the ability to program an account. On Starknet, accounts are contracts, but with one main difference, an account contract can choose programmatically what it considers a valid transaction. If it considers the transaction valid, the account contract is assigned as the sender of the transaction (pays the fees). So technically we could create an account contract that validates all transactions including an emoji. To make it work with Ethereum Transactions we verify that the transaction has been signed with the correct Ethereum private key using the Ethereum signing algorithm.

Read more about:
- [Account Abstraction](https://eips.ethereum.org/EIPS/eip-2938)
- [Account Abstraction on Starknet](https://docs.starknet.io/documentation/architecture_and_concepts/Account_Abstraction/introduction/)
- [Ethereum Accounts](https://ethereum.org/en/developers/docs/accounts/)

# Infrastructure

![Schema describing how the Account Abstraction will interact with Kakarot](docs/img/infrastructure_1.png)


# Setup

Default account seed: 497146928
