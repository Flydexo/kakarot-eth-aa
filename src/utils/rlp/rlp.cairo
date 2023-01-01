%builtins range_check bitwise

from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc

struct RLPField {
   data_len: felt,
   data: felt*,
   is_list: felt, // when is TRUE the data must be RLP decoded
}

func main{
     range_check_ptr,
     bitwise_ptr
}() {
  alloc_locals;
  let (buffer: felt*) = alloc();
  assert buffer[0] = 15;
  assert buffer[1] = 121;
  // string dog
  assert buffer[2] = 0x83;
  assert buffer[3] = 'd';
  assert buffer[4] = 'o';
  assert buffer[5] = 'g';
  // long string lorem ipsum
  %{
    string = "Lorem ipsum dolor sit amet, consectetur adipisicing elit"
    strAscii = [ord(c) for c in string]
    data_len = len(strAscii)
    dlen = data_len.to_bytes(1, 'big')
    xi = ids.buffer + 6
    memory[xi] = 184 + 1
    memory[xi+1] = dlen[0]   
    xi = xi + 2
    for i in range(0,data_len):
        memory[xi+i] = strAscii[i]
    # list containing the 12 first elemenets of the fibonnaci sequence
    xi = xi + data_len
    memory[xi] = 192 + 12 # prefix for list
    xi = xi + 1
    memory[xi] = 0
    memory[xi+1] = 1
    for i in range(2,12):
        memory[xi+i] = (memory[xi+i-2] + memory[xi+i-1])
    xi = xi + 12
    # list containing the 96 first pi decimals
    decimals = [1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9, 3, 2, 3, 8, 4, 6, 2, 6, 4, 3, 3, 8, 3, 2, 7, 9, 5, 0, 2, 8, 8, 4, 1, 9, 7, 1, 6, 9, 3, 9, 9, 3, 7, 5, 1, 0, 5, 8, 2, 0, 9, 7, 4, 9, 4, 4, 5, 9, 2, 3, 0, 7, 8, 1, 6, 4, 0, 6, 2, 8, 6, 2, 0, 8, 9, 9, 8, 6, 2, 8, 0, 3, 4, 8, 2, 5, 3, 4, 2, 1, 1, 7]
    data_len = len(decimals)
    dlen = data_len.to_bytes(1, 'big')
    memory[xi] = 248 + 1
    memory[xi+1] = dlen[0]
    xi = xi + 2
    for i in range(0,len(decimals)):
        memory[xi+i] = decimals[i]
  %}
  let (local fields: RLPField*) = alloc();
  decode_rlp(6+1+1+56+12+99, buffer, fields);
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
          %{ print(ids.byte) %}
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
          %{
            string = ""
            for i in range(0,ids.string_len):
                string += chr(memory[ids.buffer_ptr+i])
            print(string)
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
          local len_len = byte - 184;
          let (dlen) = get_data_len(len=0,len_len=len_len);
          %{
            string = ""
            for i in range(0,ids.dlen):
                string += chr(memory[ids.buffer_ptr+i])
            print(string)
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
              for i in range(0,ids.list_len):
                  print(memory[ids.buffer_ptr+i])
              print("end list display", "next byte: ", memory[ids.buffer_ptr+12])
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
           local list_len_len = byte - 248;
           let (dlen) = get_data_len(len=0,len_len=list_len_len);
           %{
              print('found longer list: ', ids.dlen)
              for i in range(0,ids.dlen):
                  print(memory[ids.buffer_ptr+i])
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