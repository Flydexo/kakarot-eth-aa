// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.pow import pow
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem

namespace RLP {
  struct Field {
    data_len: felt,
    data: felt*,
    is_list: felt, // when is TRUE the data must be RLP decoded
  }

  func clone{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr,
  }(
    data_len: felt,
    data: felt*,
    clone: felt*
  ) -> () {
    if(data_len == 0) {
      return ();
    }
    assert [clone] = [data];
    return clone(data_len-1,data+1,clone+1);
  }

  func hex_string_to_felt{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr,
  }(
    data_len: felt,
    data: felt*,
    n: felt
  ) -> (n:felt) {
    if(data_len == 0) {
      return (n=n);
    }
    let e: felt = data_len - 1;
    let byte: felt = [data];
    let (res) = pow(256, e);
    return hex_string_to_felt(data_len=data_len-1,data=data+1,n=n+byte*res);
  }

  func decode_fields{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr,
  }(
    fields_len: felt,
    fields: Field*,
    sub_fields: Field*
  ) -> () {
    if(fields_len == 0) {
      return ();
    }
    let field = [fields];
    if(field.is_list == 1) {
      decode_rlp(field.data_len, field.data,sub_fields);
      return decode_fields(fields_len=fields_len-1,fields=fields+Field.SIZE, sub_fields=sub_fields);
    }else{
      return decode_fields(fields_len=fields_len-1,fields=fields+Field.SIZE, sub_fields=sub_fields);
    }
  }

  func read_word{
       syscall_ptr: felt*,
       pedersen_ptr: HashBuiltin*,
       bitwise_ptr: BitwiseBuiltin*,
       range_check_ptr
  }(
    data_len: felt,
    data: felt*,
    word: felt
  ) -> (word:felt) {
    if(data_len == 0) {
      return (word=word);
    }
    let (byte: felt) = read_byte{buffer_ptr=data}();
    return read_word(data_len=data_len-1,data=data,word=word+byte);
  }

  func bytes_to_words{
       syscall_ptr: felt*,
       pedersen_ptr: HashBuiltin*,
       bitwise_ptr: BitwiseBuiltin*,
       range_check_ptr
  }(
    data_len: felt,
    data: felt*,
    words_len: felt,
    words: felt*
  ) -> (words_len:felt) {
   if(data_len == 0) {
     return (words_len=words_len);
   }
   let is_le_7 = is_le(data_len, 7);
   if(is_le_7 == 1) {
      let (word: felt) = read_word(data_len=8-data_len,data=data,word=0);
      assert [words] = word;
      return bytes_to_words(data_len=0,data=data+8-data_len,words_len=words_len+1,words=words+1);
   }else{
      let (word: felt) = read_word(data_len=8,data=data,word=0);
      assert [words] = word;
      return bytes_to_words(data_len=data_len-8,data=data+64,words_len=words_len+1,words=words+1);     
   }
  }

  func bytes_to_uint256{
       syscall_ptr: felt*,
       pedersen_ptr: HashBuiltin*,
       bitwise_ptr: BitwiseBuiltin*,
       range_check_ptr
  }(
    data_len: felt,
    data: felt*,
  ) -> (high: felt, low: felt) {
   alloc_locals;
   let (word: felt) = read_word(data_len=16,data=data,word=0);
   local high = word;
   let (word: felt) = read_word(data_len=16,data=data+16,word=0);
   local low = word;
   return (high=high, low=low);
  }

  func read_byte{ 
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr,
      buffer_ptr: felt*
  }() -> (byte:felt) {
      tempvar byte = [buffer_ptr];
      let buffer_ptr = buffer_ptr + 1;
      return (byte=byte);
  }

  func get_data_len{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr,
      buffer_ptr: felt*
  }(
    len: felt,
    len_len: felt
  ) -> (dlen:felt) {
    if(len_len == 0) {
      return(dlen=len);
    }
    let (byte) = read_byte();
    return get_data_len(len=len+byte,len_len=len_len-1);
  }

  func decode_rlp{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr,
  }(
    data_len: felt,
    data: felt*,
    fields: Field*
  ) -> () {
    alloc_locals;
    if(data_len == 0) {
      return ();
    }
    let buffer_ptr = data;
    with buffer_ptr{
        let (byte: felt) = read_byte();
        let is_le_127: felt = is_le(byte, 127);
        if(is_le_127 == 1) {
            assert [fields] = Field(
              data_len=0,
              data=buffer_ptr,
              is_list=0
            );
            return decode_rlp(data_len=data_len-1,data=buffer_ptr, fields=fields + Field.SIZE);
        }
        let is_le_183 = is_le(byte, 183); // a max 55 bytes long string
        if(is_le_183 == 1) {
            let string_len = byte - 128;
            assert [fields] = Field(
              data_len=string_len,
              data=buffer_ptr,
              is_list=0
            );
            return decode_rlp(data_len=data_len-1-string_len,data=buffer_ptr+string_len,fields=fields + Field.SIZE);
        }
        let is_le_191 = is_le(byte,191); // string longer than 55 bytes
        if (is_le_191 == 1) {
            local len_len = byte - 183;
            let (dlen) = get_data_len(len=0,len_len=len_len);
            assert [fields] = Field(
              data_len=dlen,
              data=buffer_ptr,
              is_list=0
            );
            return decode_rlp(data_len=data_len-1-len_len-dlen,data=buffer_ptr+dlen,fields=fields + Field.SIZE);
        }
        let is_le_247 = is_le(byte, 247); // list 0-55 bytes long
        if(is_le_247 == 1) {
              local list_len = byte - 192;
              assert [fields] = Field(
                data_len=list_len,
                data=buffer_ptr,
                is_list=1
              );
              return decode_rlp(data_len=data_len-1-list_len,data=buffer_ptr+list_len,fields=fields + Field.SIZE);
        }
        let is_le_255 = is_le(byte, 255); // list > 55 bytes
        if(is_le_255 == 1) {
            local list_len_len = byte - 247;
            let (dlen) = get_data_len(len=0,len_len=list_len_len);
            assert [fields] = Field(
                data_len=dlen,
                data=buffer_ptr,
                is_list=1
            );
            return decode_rlp(data_len=data_len-1-list_len_len-dlen,data=buffer_ptr+dlen,fields=fields + Field.SIZE);
        }
        return ();
    }
  }

  func fill_array{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr,
  }(
    recipient: felt*,
    data_len: felt,
    data: felt*
  ) -> () {
    if(data_len == 0) {
      return ();
    }

    [recipient] = [data];
    return fill_array(recipient+1, data_len-1, data+1);
  }

  func bytes_len{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr,
  }(len: felt) -> (blen: felt){
    // get ready for ugly code
    let fit = is_le(len, 255);
    if(fit == 1) {
      return (byte_len=1);
    }
    let fit = is_le(len, 65535);
    if(fit == 1) {
      return (byte_len=2);
    }
    let fit = is_le(len, 16777215);
    if(fit == 1) {
      return (byte_len=3);
    }
    let fit = is_le(len, 4294967295);
    if(fit == 1) {
      return (byte_len=4);
    }
    let fit = is_le(len, 1099511627775);
    if(fit == 1) {
      return (byte_len=5);
    }
    let fit = is_le(len, 281474976710655);
    if(fit == 1) {
      return (byte_len=6);
    }
    let fit = is_le(len, 72057594037927935);
    if(fit == 1) {
      return (byte_len=7);
    }
    let fit = is_le(len, 18446744073709551615);
    if(fit == 1) {
      return (byte_len=8);
    }
  }

  func to_bytes{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr,
  }(
    bytes: felt*,
    rs_len: felt,
    rs: felt*,
    first: felt,
  ) -> () {
    if(rs_len == 0) {
      return ();
    }
    if(first == 1) {
      let (q,r) = unsigned_div_rem(rs_len, 2);
      if(r == 0) {
        [bytes] = [rs];
        return to_bytes(bytes+1,rs_len-1, rs+1,0);
      }
    }
    [bytes] = [rs]*16 + [rs+1];
    return to_bytes(bytes+1,rs_len-2, rs+2,0);
  }

  func to_base_16{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr,
  }(rs_len: felt, rs: felt*, v: felt) -> (rs_len:felt) {
    let (q, r) = unsigned_div_rem(v, 16);
    let is_le_16 = is_le(r,16);
    assert [rs] = r;
    if(is_le_16 == 1){
      return (rs_len=rs_len+1);
    }
    return to_base_16(rs_len+1, rs+1,q);
  }

  func encode_rlp_list{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr,
  }(
    data_len: felt,
    data: felt*,
    rlp: felt*
  ) -> (rlp_len: felt) {
    alloc_locals;
    let is_le_55 = is_le(data_len, 55);
    if(is_le_55 == 1) {
      rlp[0] = 0xc0 + data_len;
      fill_array(rlp+1, data_len, data);
      return (data_len+1);
    }else{
      let (blen) = bytes_len(data_len); 
      rlp[0] = 0xf7  + blen;
      let (local rs: felt*) = alloc();
      let (rs_len) = to_base_16(0, rs, data_len);
      let (local bytes: felt*) = alloc();
      to_bytes(bytes, rs_len, rs, 1);
      fill_array(rlp+1, blen, bytes);
      fill_array(rlp+2, data_len, data);
      return (data_len+1);
    }
  }
}
