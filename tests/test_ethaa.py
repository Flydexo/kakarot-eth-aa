import os
import pytest
import web3
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.models import StarknetChainId
from starknet_py.contract import Contract
from eth_account.account import Account, SignedMessage


DEPLOYER_CONTRACT_FILE = open(os.path.join(os.path.dirname(__file__), "../build/deployer.json")).read()

ACCOUNT_CONTRACT_FILE = open(os.path.join(os.path.dirname(__file__), "../build/account.json")).read()

tempAccount: Account = web3.eth.Account().create()
evm_address = web3.Web3().toInt(hexstr=tempAccount.address) 
client = GatewayClient("http://localhost:5050")
account = AccountClient(
    client=client,
    address="0x30123acdf2ab9e571c13c215ef6eaa2732712b266215aad5d011502631040b8",
    key_pair=KeyPair(private_key=0xea901e5d5d54bcb285a2080bd531210, public_key=0x6318899c7de77565d0a80079ce16aac2c509a2e8b8e5fa29ccbc8578673ec50),
    chain=StarknetChainId.TESTNET,
    supported_tx_version=1,
)
aa_contract: Contract = None

@pytest.mark.asyncio
async def test_address_compute():
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

    (eth_address,) = await aa_contract.functions["get_eth_address"].call()

    assert eth_address == evm_address

@pytest.mark.asyncio
async def test_eth_aa_signature():
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
    assert aa_contract != None
    example_hash = 59079360568167363077893441303287612859385802189347658889697837346291416284
    sig: SignedMessage = tempAccount.signHash(example_hash.to_bytes(32, 'big'))
    print(sig)
    (isValid,) = await aa_contract.functions["is_valid_signature"].call(web3.Web3.toInt(sig.messageHash), [sig.v, *uint256_to_field(sig.r), *uint256_to_field(sig.s)])
    print(isValid)
    assert isValid == True
    (isValid,) = await aa_contract.functions["is_valid_signature"].call(web3.Web3.toInt(hexstr="0x477455445"), [sig.v, *uint256_to_field(sig.r), *uint256_to_field(sig.s)])
    print(isValid)
    assert isValid == False

@pytest.mark.asyncio
async def test_eth_execute():
    assert True == True
# async def test_eth_aa_signature():

#     starknet = await Starknet.empty()

#     account_class = await starknet.declare(source=ACCOUNT_CONTRACT_FILE);

#     contract = await starknet.deploy(
#         source=DEPLOYER_CONTRACT_FILE,
#         constructor_calldata=[account_class.class_hash],
#     )

#     eth_aa_deploy_tx = (await contract.create_account(evm_address=evm_address).execute());

#     eth_aa = StarknetContract(
#         starknet.state, 
#         get_abi(get_contract_class(source=ACCOUNT_CONTRACT_FILE)), 
#         eth_aa_deploy_tx.call_info.internal_calls[0].contract_address, 
#         eth_aa_deploy_tx
#     );

#     evm_tx = tempAccount.sign_transaction(dict(
#         nonce=0,
#         maxFeePerGas=2000000000,
#         maxPriorityFeePerGas=1000000000,
#         gas=100000,
#         to='0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
#         value=0,
#         data=b'',
#     ))


#     evm_signature = tempAccount.sig

    # tx = await starknet.state.execute_tx(
        
    # tx = InternalInvokeFunction.create_wrapped_with_account(eth_aa.contract_address, 1409719322379134103315153819531084269022823759702923787575976457644523059131, [
    #     0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, # address (uniswap v2 on ethereum),
    #     0, # value
    #     2000000000 * 100000, # gas_limit
    #     0,
        
    # ], 0xB18CF02D874A8ACA5B6480CE1D57FA9C6C58015FD68F6B6B6DF59F63BBA85D, 2000000000, 0, [evm_tx.v, *uint256_to_field(evm_tx.r), *uint256_to_field(evm_tx.s)])

    # print(tx)

    # r = await eth_aa.isValidSignature(evm_tx.hash, [evm_tx.v, *uint256_to_field(evm_tx.r), *uint256_to_field(evm_tx.s)]).call()

    # print(r)

    # tx = await starknet.state.execute_tx(InternalInvokeFunction(
    #     contract_address=1409719322379134103315153819531084269022823759702923787575976457644523059131,
    #     entry_point_selector=0xB18CF02D874A8ACA5B6480CE1D57FA9C6C58015FD68F6B6B6DF59F63BBA85D,
    #     max_fee=2000000000,
    #     version=1,
    #     entry_point_type=EntryPointType.EXTERNAL,
    #     calldata=[
    #         0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, # address (uniswap v2 on ethereum),
    #         0, # value
    #         2000000000 * 100000, # gas_limit
    #         0,
    #         0
    #     ],
    #     nonce=0,
    #     signature=[evm_tx.v, evm_tx.r, evm_tx.s],
    #     hash_value=web3.Web3.toInt(hexstr=evm_tx.hash.hex()),
    # ))

    # print(tx)

#     assert True == False

def uint256_to_field(u256: int) -> [int, int]:
    b = '{0:0256b}'.format(u256)
    print(b)
    print(b[0:128], b[128:257])
    return [int(b[0:128], 2),int(b[128:257], 2)]
