%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.cairo_secp.signature import verify_eth_signature_uint256
from starkware.starknet.common.syscalls import get_tx_info
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.cairo_keccak.keccak import keccak, finalize_keccak
from utils.rlp.rlp import RLP
from starkware.cairo.common.math_cmp import is_le

namespace KETHAA {

    // Constants
    const KAKAROT = 1409719322379134103315153819531084269022823759702923787575976457644523059131; // kakarot contract address (temporary)
    const EXECUTE_AT_ADDRESS_SELECTOR = 175332271055223547208505378209204736960926292802627036960758298143252682610; // keccak250(ascii('execute_at_address'))
    const AA_VERSION = 0x11F2231B9D464344B81D536A50553D6281A9FA0FA37EF9AC2B9E076729AEFAA; // pedersen("KAKAROT_AA_V0.0.1")
    const TX_FIELDS = 12; // number of elements in an evm tx see EIP 1559

    const CHAIN_ID_IDX = 0; 
    const NONCE_IDX = 1; 
    const MAX_PRIORITY_FEE_PER_GAS_IDX = 2; 
    const MAX_FEE_PER_GAS_IDX = 3; 
    const GAS_LIMIT_IDX = 4; 
    const DESTINATION_IDX = 5; 
    const AMOUNT_IDX = 6; 
    const PAYLOAD_IDX = 7; 
    const ACCESS_LIST_IDX = 8; 
    const V_IDX = 9; 
    const R_IDX = 10; 
    const S_IDX = 11; 


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

    struct EVMTX {
        type: felt,
        chain_id: felt,
        nonce: felt,
        max_priority_fee_per_gas: felt,
        max_fee_per_gas: felt,
        gas_limit: felt,
        destination: felt,
        amount: felt,
        payload_len: felt,
        payload: felt*,
        sig_v: felt,
        r: Uint256*,
        s: Uint256*,
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
    }(_call: Call) -> () {
        with_attr error_message("Invalid Kakarot Transaction") {

            assert _call.to = KAKAROT;
            assert _call.selector = EXECUTE_AT_ADDRESS_SELECTOR;

            return ();
        } 
    }

    func are_valid_calls{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(eth_address: felt, call_array_len: felt, call_array: CallArray*, calldata_len: felt, calldata: felt*) -> () {
        alloc_locals;
        if(call_array_len == 0) {
            return ();
        }

        local _call: Call = Call(
            to=[call_array].to,
            selector=[call_array].selector,
            calldata_len=[call_array].data_len,
            calldata=calldata + [call_array].data_offset
        );

        is_valid_kakarot_transaction(_call);
        is_valid_eth_tx(eth_address, _call.calldata_len, _call.calldata);

        return are_valid_calls(eth_address=eth_address, call_array_len=call_array_len-1,call_array=call_array + CallArray.SIZE,calldata_len=calldata_len,calldata=calldata);
    }


    func is_valid_eth_tx{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        eth_address: felt,
        calldata_len: felt,
        calldata: felt*
    ) -> (is_valid:felt) {
        alloc_locals;
        let tx_type = [calldata];
        let rlp_data = calldata + 1; // remove the tx type
        let (local fields: RLP.Field*) = alloc();
        RLP.decode_rlp(calldata_len-1, rlp_data, fields); // decode array
        RLP.decode_rlp([fields].data_len, [fields].data, fields+RLP.Field.SIZE); // decode fields in array
        let fields = fields+RLP.Field.SIZE; // only fields in the array
        if(tx_type == 2) { 
            assert 1 = 0;
            return (is_valid=0);
            // // only eip1559 for the moment
            // let (keccak_ptr: felt*) = alloc();
            // let keccak_ptr_start = keccak_ptr;
            // // tx hash is keccak256(0x02 || rlp([chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, destination, amount, data, access_list]))
            // // split into words of 64 bits
            // // change the rlp length because we removed the sig
            // // 1. remove the sig from the data
            // let list_data = [fields].data;
            // let (local rlp: felt*) = alloc();
            // let (rlp_len: felt) = RLP.encode_rlp_list([fields].data_len-67, list_data, rlp);
            // let (words: felt*) = alloc();
            // let (words_len: felt) = RLP.bytes_to_words(
            //     data_len=calldata_len,
            //     data=calldata,
            //     words_len=0,
            //     words=words
            // );
            // if(fields[V_IDX].data_len == 0) {
            //    [ap] = 0,ap++;
            // }else{
            //    [ap] = 1,ap++; 
            // }
            // let v = [ap-1];
            // let (high,low) = RLP.bytes_to_uint256(data_len=32, data=fields[R_IDX].data);
            // let r = Uint256(low=low,high=high);
            // let (high,low) = RLP.bytes_to_uint256(data_len=32, data=fields[S_IDX].data);
            // let s = Uint256(low=low,high=high);
            // let (res: Uint256) = keccak{keccak_ptr=keccak_ptr}(inputs=words, n_bytes=calldata_len-67);
            // finalize_keccak(keccak_ptr_start=keccak_ptr_start,keccak_ptr_end=keccak_ptr);
            // return is_valid_eth_signature(res, v, r, s, eth_address);
        }else{
            assert 1 = 0;
            return (is_valid=0);
        }
    }


    func is_valid_eth_signature{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        hash: Uint256,
        v: felt,
        r: Uint256,
        s: Uint256,
        eth_address: felt,
    ) -> (is_valid:felt) {
        let (keccak_ptr: felt*) = alloc();

        with keccak_ptr {
            verify_eth_signature_uint256(
                msg_hash=hash, r=r, s=s, v=v, eth_address=eth_address
            );
        }
        return (is_valid=1);
    }
}