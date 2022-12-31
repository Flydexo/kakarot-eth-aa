import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), "../"))

import pytest
import web3
import pytest
from starkware.starknet.testing.starknet import Starknet
from eth_account.account import Account, SignedMessage
from starkware.starknet.testing.contract import StarknetContract
from starkware.starkware_utils.error_handling import StarkException
from eth_keys import keys
from utils.setup import setup_test_env
from utils.signer import MockEthSigner

def to_uint(a):
    a = int(a)
    return (a & ((1 << 128) - 1), a >> 128)

@pytest.mark.asyncio
async def test_address_compute():
    starknet = await Starknet.empty()
    (deployer, account, private_key, evm_address) = await setup_test_env(starknet)

    call_info = await deployer.compute_starknet_address(evm_address=evm_address).call()
    
    assert call_info.result.contract_address == account.contract_address

    call_info = await account.get_eth_address().call()  

    assert call_info.result.eth_address == evm_address

@pytest.mark.asyncio
async def test_eth_aa_signature():
    starknet = await Starknet.empty()
    (deployer, account, private_key, evm_address) = await setup_test_env(starknet)
    example_hash = os.urandom(30)
    signer = keys.PrivateKey(private_key_bytes=private_key)
    sig = signer.sign_msg_hash(web3.Web3.toInt(example_hash).to_bytes(32, 'big'))
    call_info = await account.is_valid_signature(web3.Web3.toInt(example_hash), [sig.v, *to_uint(sig.r), *to_uint(sig.s)]).call()
    assert call_info.result.is_valid == True
    with pytest.raises(StarkException):
        await account.is_valid_signature(web3.Web3.toInt(os.urandom(30)), [sig.v, *to_uint(sig.r), *to_uint(sig.s)]).call()


@pytest.mark.asyncio
async def test_execute():
    starknet = await Starknet.empty()

    (deployer, account, private_key, evm_address) = await setup_test_env(starknet)

    tempAccount: Account = web3.eth.Account().from_key(private_key=private_key)
    evm_address = web3.Web3().toInt(hexstr=tempAccount.address) 

    signer = MockEthSigner(private_key)

    tx = await signer.send_transaction(account, 1409719322379134103315153819531084269022823759702923787575976457644523059131, 'execute_at_address', [
        1409719322379134103315153819531084269022823759702923787575976457644523059131, 
        0, 
        100000000, 
        0, 
        0
    ])

    assert tx != None

    with pytest.raises(StarkException):
        signer = MockEthSigner(os.urandom(32))

        await signer.send_transaction(account, 1409719322379134103315153819531084269022823759702923787575976457644523059131, 'execute_at_address', [
            1409719322379134103315153819531084269022823759702923787575976457644523059131, 
            0, 
            100000000, 
            0, 
            0
        ])
