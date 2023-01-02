%builtins range_check bitwise

from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.pow import pow

struct RLPField {
   data_len: felt,
   data: felt*,
   is_list: felt, // when is TRUE the data must be RLP decoded
}

func hex_string_to_felt{
     range_check_ptr,
     bitwise_ptr
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
  %{ print(memory[ids.data]) %}
  let (res) = pow(256, e);
  return hex_string_to_felt(data_len=data_len-1,data=data+1,n=n+byte*res);
}

func decode_fields{
     range_check_ptr,
     bitwise_ptr
}(
  fields_len: felt,
  fields: RLPField*,
  sub_fields: RLPField*
) -> () {
  if(fields_len == 0) {
    return ();
  }
  %{ print(ids.fields) %}
  let field = [fields];
  if(field.is_list == 1) {
    decode_rlp(field.data_len, field.data,sub_fields);
    return decode_fields(fields_len=fields_len-1,fields=fields+RLPField.SIZE, sub_fields=sub_fields);
  }else{
    return decode_fields(fields_len=fields_len-1,fields=fields+RLPField.SIZE, sub_fields=sub_fields);
  }
}

func main{
     range_check_ptr,
     bitwise_ptr
}() {
  alloc_locals;
  let (buffer: felt*) = alloc();
  %{
    raw_tx = bytes.fromhex("f87282232801830a30138203e8843b9ac9ff9495222290dd7278aa3ddd389cc1e1d165cc4bafe5872386f26fc1000080c080a0d2b66ce7eb22e11b8ebc1edf149c4e4cad930115e905783512c4e16d1dff5659a07c404243474462a3ee0384e22bf19d2bf94f62f8ce3e6df10e553f86948faebd")
    for i in range(0, len(raw_tx)):
        memory[ids.buffer+i] = raw_tx[i]
    print(len(raw_tx))
  %} 
  let (fields: RLPField*) = alloc();
  decode_rlp(116, buffer, fields);
  let (sub_fields: RLPField*) = alloc();
  decode_fields(1, fields, sub_fields);
  return ();   
}

func read_byte{ 
     range_check_ptr,
     bitwise_ptr,
     buffer_ptr: felt*
}() -> (byte:felt) {
    tempvar byte = [buffer_ptr];
    let buffer_ptr = buffer_ptr + 1;
    return (byte=byte);
}

func get_data_len{
     range_check_ptr,
     bitwise_ptr,
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
    range_check_ptr,
    bitwise_ptr,
}(
  data_len: felt,
  data: felt*,
  fields: RLPField*
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
          %{ print("found signle:", ids.byte) %}
          assert [fields] = RLPField(
             data_len=0,
             data=buffer_ptr,
             is_list=0
          );
          return decode_rlp(data_len=data_len-1,data=buffer_ptr, fields=fields + RLPField.SIZE);
       }
       let is_le_183 = is_le(byte, 183); // a max 55 bytes long string
       if(is_le_183 == 1) {
          let string_len = byte - 128;
          //let (n: felt) = hex_string_to_felt(
          //    data_len=string_len,
          //    data=buffer_ptr,
          //    n=0
          //);
          %{
            print("found string", ids.string_len)
          %}
          assert [fields] = RLPField(
             data_len=string_len,
             data=buffer_ptr,
             is_list=0
          );
          return decode_rlp(data_len=data_len-1-string_len,data=buffer_ptr+string_len,fields=fields + RLPField.SIZE);
       }
       let is_le_191 = is_le(byte,191); // string longer than 55 bytes
       if (is_le_191 == 1) {
          local len_len = byte - 183;
          let (dlen) = get_data_len(len=0,len_len=len_len);
          //let (n: felt) = hex_string_to_felt(
          //    data_len=dlen,
          //    data=buffer_ptr,
          //    n=0
          //);
          %{
            print("found longer string")
            %}
          assert [fields] = RLPField(
             data_len=dlen,
             data=buffer_ptr,
             is_list=0
          );
          return decode_rlp(data_len=data_len-1-len_len-dlen,data=buffer_ptr+dlen,fields=fields + RLPField.SIZE);
       }
       let is_le_247 = is_le(byte, 247); // list 0-55 bytes long
       if(is_le_247 == 1) {
            local list_len = byte - 192;
            %{
              print("found list:", ids.list_len)
            %}
            assert [fields] = RLPField(
               data_len=list_len,
               data=buffer_ptr,
               is_list=1
            );
            return decode_rlp(data_len=data_len-1-list_len,data=buffer_ptr+list_len,fields=fields + RLPField.SIZE);
       }
       let is_le_255 = is_le(byte, 255); // list > 55 bytes
       if(is_le_255 == 1) {
           local list_len_len = byte - 247;
           let (dlen) = get_data_len(len=0,len_len=list_len_len);
           %{
              print('found longer list: ', ids.dlen)
           %}
           assert [fields] = RLPField(
              data_len=dlen,
              data=buffer_ptr,
              is_list=1
           );
           return decode_rlp(data_len=data_len-1-list_len_len-dlen,data=buffer_ptr+dlen,fields=fields + RLPField.SIZE);
       }
       return ();
  }
}