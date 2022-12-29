// SPDX-License-Identifier: MIT
// Fork from OpenZeppelin Contracts for Cairo v0.6.0 (account/presets/EthAccount.cairo)
// Kakarot

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import (
    get_tx_info,
    TxInfo
)

from openzeppelin.account.library import Account, AccountCallArray, Call

const MAX_ETH_ADDRESS = 2**160; // 1461501637330902918203684832716283019655932542976 
const KAKAROT = 1461501637330902918203684832716283019655932542976; // kakarot contract address
const EXECUTE_AT_ADDRESS_SELECTOR = 0xB18CF02D874A8ACA5B6480CE1D57FA9C6C58015FD68F6B6B6DF59F63BBA85D; // keccak250(ascii('execute_at_address'))
const AA_VERSION = 0x11F2231B9D464344B81D536A50553D6281A9FA0FA37EF9AC2B9E076729AEFAA; // pedersen("KAKAROT_AA_V0.0.1")

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(ethAddress: felt) {
    Account.initializer(ethAddress);
    return ();
}

@view
func getEthAddress{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
} () -> (ethAddress: felt) {
    let (ethAddress: felt) = Account.get_public_key();
    return (ethAddress=ethAddress);
}

@view
func supportsInterface{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
} (interfaceId: felt) -> (success: felt) {
    return (success=0);
}

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
    [range_check_ptr] = ethAddress;
    assert [range_check_ptr + 1] = MAX_ETH_ADDRESS - ethAddress - 1;
    let range_check_ptr = range_check_ptr + 2;
    assert AA_VERSION = contract_address_salt;
    return ();
}

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

        // TODO: checks that the user fees in tx < account_balance
        // TODO: checks that starknet tx fees < signed max_fees

        return is_valid_kakarot_transaction(call_array_len-1, call_array + AccountCallArray.SIZE, calldata_len, calldata);
    } 
}