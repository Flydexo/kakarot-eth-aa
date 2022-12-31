import os
import pytest
import web3
import pytest
import starknet_py
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.models import StarknetChainId
from starknet_py.contract import Contract
from eth_account.account import Account, SignedMessage
from typing import Tuple
from eth_keys import keys

async def setup(client: GatewayClient, account: Contract, ACCOUNT_CONTRACT_FILE: str, DEPLOYER_CONTRACT_FILE: str) -> Tuple[bytes, Account, int, Contract, Contract] : 
    private_key = os.urandom(32)
    tempAccount: Account = web3.eth.Account().from_key(private_key)
    evm_address = web3.Web3().toInt(hexstr=tempAccount.address) 

    account_class = await Contract.declare(
        account=account, compiled_contract=ACCOUNT_CONTRACT_FILE, max_fee=int(1e16)
    )

    await account_class.wait_for_acceptance()

    deployer_class = await Contract.declare(
        account=account, compiled_contract=DEPLOYER_CONTRACT_FILE, max_fee=int(1e16)
    )

    await deployer_class.wait_for_acceptance()

    deployment = await deployer_class.deploy(constructor_args={account_class.class_hash},max_fee=int(1e16))
    #
    await deployment.wait_for_acceptance();

    contract = deployment.deployed_contract

    (computed_contract_address,) = await contract.functions["compute_starknet_address"].call(evm_address)

    invocation = await contract.functions["create_account"].invoke(
        evm_address=evm_address,
        max_fee=int(1e16)
    )

    await invocation.wait_for_acceptance()

    aa_contract = await Contract.from_address(client=client, address=computed_contract_address)

    return private_key,tempAccount, evm_address, contract, aa_contract