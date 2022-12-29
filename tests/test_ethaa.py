import os
import pytest
import web3

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract_utils import *
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.testing.objects import StarknetCallInfo
from starkware.crypto.signature.fast_pedersen_hash import pedersen_hash

DEPLOYER_CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../src/deployer.cairo")

ACCOUNT_CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../src/eth_account.cairo")

tempAccount = web3.eth.Account().create();
evm_address = web3.Web3().toInt(hexstr=tempAccount.address) 

@pytest.mark.asyncio
async def test_address_compute():
        starknet = await Starknet.empty()

        account_class = await starknet.declare(source=ACCOUNT_CONTRACT_FILE);

        contract = await starknet.deploy(
            source=DEPLOYER_CONTRACT_FILE,
            constructor_calldata=[account_class.class_hash],
        )

        execution_info = await contract.compute_starknet_address(evm_address).call()
        computed_contract_address = execution_info.result.contract_address


        deployed_account_tx = await contract.create_account(evm_address=evm_address).execute();

        assert computed_contract_address == deployed_account_tx.result.account_address

@pytest.mark.asyncio
async def test_eth_aa_deployment():

        starknet = await Starknet.empty()

        account_class = await starknet.declare(source=ACCOUNT_CONTRACT_FILE);

            # Deploy the contract.
        contract = await starknet.deploy(
            source=DEPLOYER_CONTRACT_FILE,
            constructor_calldata=[account_class.class_hash],
        )

        eth_aa_deploy_tx = (await contract.create_account(evm_address=evm_address).execute());

        eth_aa = StarknetContract(
            starknet.state, 
            get_abi(get_contract_class(source=ACCOUNT_CONTRACT_FILE)), 
            eth_aa_deploy_tx.result.account_address, 
            eth_aa_deploy_tx
        );

        output_evm_addres = (await eth_aa.getEthAddress().call()).result.ethAddress;

        assert evm_address == output_evm_addres
        

        