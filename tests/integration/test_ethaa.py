import os
import pytest
import web3
import pytest
import starknet_py
from starknet_py.net.client_models import Call
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.models import StarknetChainId
from starknet_py.contract import Contract
from eth_account.account import Account, SignedMessage
from starkware.starknet.business_logic.transaction.objects import InvokeFunction
from eth_keys import keys
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), "../"))
import utils.setup
from utils.signer import EthSigner
from starkware.starknet.definitions.general_config import StarknetGeneralConfig


DEPLOYER_CONTRACT_FILE = open(os.path.join(os.path.dirname(__file__), "../../build/deployer.json")).read()

ACCOUNT_CONTRACT_FILE = open(os.path.join(os.path.dirname(__file__), "../../build/account.json")).read()

def to_uint(a):
    a = int(a)
    return (a & ((1 << 128) - 1), a >> 128)

client: GatewayClient = GatewayClient("http://localhost:5050")
account = AccountClient(
    client=client,
    address="0x647454a5ae3bbcc5730ce28d8f1d8573326289cbd81e00ff4a03ee34f083e7d",
    key_pair=KeyPair(private_key=0xcad114bffec487b2eb84740d17b07a90, public_key=0x3fd7f82434697a79bc57941340b28390a5da85c22fd7c0cd22c25377b59717e),
    chain=StarknetChainId.TESTNET,
    supported_tx_version=1,
)

@pytest.mark.asyncio
async def test_address_compute():
    tempAccount: Account = web3.eth.Account().from_key(os.urandom(32))
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

    await deployment.wait_for_acceptance();

    contract = deployment.deployed_contract

    (computed_contract_address,) = await contract.functions["compute_starknet_address"].call(evm_address)

    invocation = await contract.functions["create_account"].invoke(
        evm_address=evm_address,
        max_fee=int(1e16)
    )

    await invocation.wait_for_acceptance()

    aa_contract = await Contract.from_address(client=client, address=computed_contract_address)

    (eth_address,) = await aa_contract.functions["get_eth_address"].call()

    assert eth_address == evm_address

@pytest.mark.asyncio
async def test_eth_aa_signature():
    (private_key, temp_account, evm_address, deployer, aa_contract) = await utils.setup.setup(client, account, ACCOUNT_CONTRACT_FILE, DEPLOYER_CONTRACT_FILE)
    example_hash = 0x23564
    signer = keys.PrivateKey(private_key_bytes=private_key)
    sig = signer.sign_msg_hash(example_hash.to_bytes(32, 'big'))
    (isValid,) = await aa_contract.functions["is_valid_signature"].call(example_hash, [sig.v, *to_uint(sig.r), *to_uint(sig.s)])
    assert isValid == True
    with pytest.raises(starknet_py.net.client_errors.ClientError):
        (isValid,) = await aa_contract.functions["is_valid_signature"].call(0x477455445, [sig.v, *to_uint(sig.r), *to_uint(sig.s)])



@pytest.mark.asyncio
async def test_eth_execute():
    (private_key, temp_account, evm_address, deployer, aa_contract) = await utils.setup.setup(client, account, ACCOUNT_CONTRACT_FILE, DEPLOYER_CONTRACT_FILE)