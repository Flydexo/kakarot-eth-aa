// SPDX-License-Identifier: MIT
// Fork from OpenZeppelin Contracts for Cairo v0.6.0 (account/presets/EthAccount.cairo)

%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import (
    get_tx_info,
    TxInfo
)
from starkware.starknet.common.eth_utils import assert_eth_address_range

// Openzeppelin Eth default Account Abstraction
from openzeppelin.account.library import Account, AccountCallArray, Call

// Constants
const KAKAROT = 1409719322379134103315153819531084269022823759702923787575976457644523059131; // kakarot contract address (temporary)
const EXECUTE_AT_ADDRESS_SELECTOR = 0xB18CF02D874A8ACA5B6480CE1D57FA9C6C58015FD68F6B6B6DF59F63BBA85D; // keccak250(ascii('execute_at_address'))
const AA_VERSION = 0x11F2231B9D464344B81D536A50553D6281A9FA0FA37EF9AC2B9E076729AEFAA; // pedersen("KAKAROT_AA_V0.0.1")

// Constructor
// @param ethAddress The Ethereum address which will control the account
@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(ethAddress: felt) {
    Account.initializer(ethAddress);
    return ();
}

// @dev the transaction is considered as valid if: the tx receiver is the Kakarot contract, the function to execute is `execute_at_address`
// @dev TODO: checks that the user fees in tx < account_balance
// @dev TODO: checks that starknet tx fees < signed max_fees
// @dev TODO: checks that tx.value < account_balance - fees
func is_valid_kakarot_transaction{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr,
}(call_array_len: felt, call_array: AccountCallArray*, calldata_len: felt, calldata: felt*) -> () {
    with_attr error_message("Invalid Kakarot Transaction") {
        if (call_array_len == 0) {
            return ();
        }

        assert [call_array].to = KAKAROT;
        assert [call_array].selector = EXECUTE_AT_ADDRESS_SELECTOR;

        return is_valid_kakarot_transaction(call_array_len-1, call_array + AccountCallArray.SIZE, calldata_len, calldata);
    } 
}

// Account specific methods

// @notice validates a transaction
// @dev the transaction is considered as valid if is signed with the correct address and is a valid kakarot transaction
// @param call_array_len The length of the call_array
// @param call_array An array containing all the calls of the transaction see: https://docs.openzeppelin.com/contracts-cairo/0.6.0/accounts#call_and_accountcallarray_format
// @param calldata_len The length of the Calldata array
// @param calldata The calldata 
@external
func __validate__{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr,
}(
    call_array_len: felt,
    call_array: AccountCallArray*,
    calldata_len: felt,
    calldata: felt*
) {
    let (tx_info) = get_tx_info();
    Account.is_valid_eth_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature);
    is_valid_kakarot_transaction(call_array_len, call_array, calldata_len, calldata);
    return ();
}

// @notice validates this account class for declaration
// @dev For our usecase no checks are necessary 
@external
func __validate_declare__{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr
} (
    class_hash: felt,
) {
    return ();
}

// @notice validates this account for deploy
// @dev checks if the ethereum address is valid and the salt is valid
// @param class_hash The hash of the Account Contract Class
// @param contract_address_salt The salt used to deploy the contract
// @param ethAddress The ethereum address which will be controlling the account
@external
func __validate_deploy__{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr
} (
    class_hash: felt,
    contract_address_salt: felt,
    ethAddress: felt
) {
    assert contract_address_salt = AA_VERSION;
    assert_eth_address_range(ethAddress);
    return ();
}

// @notice executes the Kakarot transaction
// @dev this is executed only is the __validate__ function succeeded
// @param call_array_len The length of the call_array
// @param call_array An array containing all the calls of the transaction see: https://docs.openzeppelin.com/contracts-cairo/0.6.0/accounts#call_and_accountcallarray_format
// @param calldata_len The length of the Calldata array
// @param calldata The calldata 
// @return response_len The length of the response array
// @return response The response from the kakarot contract
@external
func __execute__{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr,
}(
    call_array_len: felt,
    call_array: AccountCallArray*,
    calldata_len: felt,
    calldata: felt*
) -> (
    response_len: felt,
    response: felt*
) {
    let (response_len, response) = Account.execute(
        call_array_len, call_array, calldata_len, calldata
    );
    return (response_len, response);
}

// @return ethAddress The Ethereum address controlling this account 
@view
func getEthAddress{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
} () -> (ethAddress: felt) {
    let (ethAddress: felt) = Account.get_public_key();
    return (ethAddress=ethAddress);
}

// @dev returns true if the interfaceId is supported
// @dev TODO: check what interfaces the contract should support and maybe create one for a kakarot account
// @param interfaceId The interface Id to verify if supported
@view
func supportsInterface{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
} (interfaceId: felt) -> (success: felt) {
    return (success=0);
}

// @notice checks if the signature is valid
// @dev returns true if the signature is signed by the account controller
// @param hash The hash which was signed
// @param signature_len The length of the signature array
// @param signature The array of the ethereum signature (as v, r, s)
@view
func isValidSignature{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr,
}(
    hash: felt,
    signature_len: felt,
    signature: felt*
) -> (isValid: felt) {
    let (isValid) = Account.is_valid_eth_signature(hash, signature_len, signature);
    return (isValid=isValid);
}

// @dev TODO: implement NONCE