import os
import web3
from eth_account.account import Account, SignedMessage
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from typing import Tuple
from eth_keys import keys

async def setup_test_env(starknet: Starknet) -> Tuple[StarknetContract, StarknetContract, bytes, int]: 
    private_key = os.urandom(32)
    tempAccount: Account = web3.eth.Account().from_key(private_key)
    evm_address = web3.Web3().toInt(hexstr=tempAccount.address) 

    account_class = await starknet.declare(source=os.path.join(os.path.dirname(__file__), "../../src/kethaa/account/account.cairo"), cairo_path=[os.path.join(os.path.dirname(__file__), "../../src")]);

    deployer = await starknet.deploy(
        source=os.path.join(os.path.dirname(__file__), "../../src/kethaa/deployer/deployer.cairo"), 
        cairo_path=[os.path.join(os.path.dirname(__file__), "../../src")],
        constructor_calldata=[account_class.class_hash],
    )

    eth_aa_deploy_tx = await deployer.create_account(evm_address=evm_address).execute();

    account = StarknetContract(
        starknet.state, 
        account_class.abi,
        eth_aa_deploy_tx.call_info.internal_calls[0].contract_address, 
        eth_aa_deploy_tx
    );

    return deployer, account, private_key, evm_address