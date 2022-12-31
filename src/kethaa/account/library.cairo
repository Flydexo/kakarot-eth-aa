%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.cairo_secp.signature import verify_eth_signature_uint256
from starkware.starknet.common.syscalls import get_tx_info
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import split_felt

namespace KETHAA {

    // Constants
    const KAKAROT = 1409719322379134103315153819531084269022823759702923787575976457644523059131; // kakarot contract address (temporary)
    const EXECUTE_AT_ADDRESS_SELECTOR = 0xB18CF02D874A8ACA5B6480CE1D57FA9C6C58015FD68F6B6B6DF59F63BBA85D; // keccak250(ascii('execute_at_address'))
    const AA_VERSION = 0x11F2231B9D464344B81D536A50553D6281A9FA0FA37EF9AC2B9E076729AEFAA; // pedersen("KAKAROT_AA_V0.0.1")

    struct Call {
        to: felt,
        selector: felt,
        calldata_len: felt,
        calldata: felt*,
    }

    // Tmp struct introduced while we wait for Cairo to support passing `[Call]` to __execute__
    struct CallArray {
        to: felt,
        selector: felt,
        data_offset: felt,
        data_len: felt,
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
    }(call_array_len: felt, call_array: CallArray*) -> () {
        with_attr error_message("Invalid Kakarot Transaction") {
            if (call_array_len == 0) {
                return ();
            }

            assert [call_array].to = KAKAROT;
            assert [call_array].selector = EXECUTE_AT_ADDRESS_SELECTOR;

            return is_valid_kakarot_transaction(call_array_len-1, call_array + CallArray.SIZE);
        } 
    }


    func is_valid_eth_tx{
        syscall_ptr: felt*,
        range_check_ptr, 
        bitwise_ptr: BitwiseBuiltin*, 
    }(
        eth_address: felt,
    ) -> (is_valid:felt) {
        let (tx) = get_tx_info();
        return is_valid_eth_signature(tx.transaction_hash, 1, tx.signature, eth_address);
    }


    func is_valid_eth_signature{
        syscall_ptr: felt*,
        range_check_ptr, 
        bitwise_ptr: BitwiseBuiltin*, 
    }(
        hash: felt,
        signature_len: felt,
        signature: felt*,
        eth_address: felt,
    ) -> (is_valid:felt) {
        let (keccak_ptr: felt*) = alloc();
        let v: felt = signature[0];
        let r: Uint256 = Uint256(low=signature[1], high=signature[2]);
        let s: Uint256 = Uint256(low=signature[3], high=signature[4]);
        let (high, low) = split_felt(hash);
        let msg_hash: Uint256 = Uint256(low=low, high=high);

        with keccak_ptr {
            verify_eth_signature_uint256(
                msg_hash=msg_hash, r=r, s=s, v=v, eth_address=eth_address
            );
        }
        return (is_valid=1);
    }
}