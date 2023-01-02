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

# @pytest.mark.asyncio
# async def test_address_compute():
#     starknet = await Starknet.empty()
#     (deployer, account, private_key, evm_address) = await setup_test_env(starknet)

#     call_info = await deployer.compute_starknet_address(evm_address=evm_address).call()
    
#     assert call_info.result.contract_address == account.contract_address

#     call_info = await account.get_eth_address().call()  

#     assert call_info.result.eth_address == evm_address

# @pytest.mark.asyncio
# async def test_eth_aa_signature():
#     starknet = await Starknet.empty()
#     (deployer, account, private_key, evm_address) = await setup_test_env(starknet)
#     evm_account = web3.Account.from_key(keys.PrivateKey(private_key_bytes=private_key))
#     raw_tx = evm_account.sign_transaction(dict(
#         nonce=1,
#         chainId=9000,
#         maxFeePerGas=1000,
#         maxPriorityFeePerGas=667667,
#         gas=999999999,
#         to=bytes.fromhex('95222290dd7278aa3ddd389cc1e1d165cc4bafe5'),
#         value=10000000000000000,
#         data=b''
#     ))
#     signer = keys.PrivateKey(private_key_bytes=private_key)
#     sig = signer.sign_msg_hash(raw_tx.hash)
#     call_info = await account.is_valid_signature([*to_uint(web3.Web3.toInt(raw_tx.hash))], [sig.v, *to_uint(sig.r), *to_uint(sig.s)]).call()
#     assert call_info.result.is_valid == True
#     with pytest.raises(StarkException):
#         await account.is_valid_signature([*to_uint(web3.Web3.toInt(os.urandom(32)))], [sig.v, *to_uint(sig.r), *to_uint(sig.s)]).call()


@pytest.mark.asyncio
async def test_execute():
    starknet = await Starknet.empty()

    (deployer, account, private_key, evm_address) = await setup_test_env(starknet)
    eth_account = MockEthSigner(private_key)

    evm_eoa = web3.Account.from_key(keys.PrivateKey(private_key_bytes=private_key))
    raw_tx = evm_eoa.sign_transaction(dict(
        nonce=1,
        chainId=9000,
        maxFeePerGas=1000,
        maxPriorityFeePerGas=667667,
        gas=999999999,
        to=bytes.fromhex('95222290dd7278aa3ddd389cc1e1d165cc4bafe5'),
        value=10000000000000000,
        data=b''
    ))

    print(raw_tx.rawTransaction.hex())

    tx: Tr = await eth_account.send_transaction(account, 1409719322379134103315153819531084269022823759702923787575976457644523059131, 'execute_at_address', raw_tx.rawTransaction)

    print(tx.validate_info.calldata)

    assert tx != None

    with pytest.raises(StarkException):
        evm_eoa = web3.Account.from_key(keys.PrivateKey(private_key_bytes=os.urandom(32)))
        raw_tx = evm_eoa.sign_transaction(dict(
            nonce=1,
            chainId=9000,
            maxFeePerGas=1000,
            maxPriorityFeePerGas=667667,
            gas=999999999,
            to=bytes.fromhex('95222290dd7278aa3ddd389cc1e1d165cc4bafe5'),
            value=10000000000000000,
            data=b''
        ))

        await eth_account.send_transaction(account, 1409719322379134103315153819531084269022823759702923787575976457644523059131, 'execute_at_address', raw_tx.rawTransaction)
