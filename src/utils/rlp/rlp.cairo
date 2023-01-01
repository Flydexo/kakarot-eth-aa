struct RLPField {
   byte: felt,
   len_len: felt,
   len: felt*,
   data_len: felt,
   data: felt*,
}

func main() {
  let range_check_ptr = 0;
  decode_rlp()
  return ();   
}

func decode_rlp{
    range_check_ptr,
}(
  data_len: felt,
  data: felt*
) -> (
  field: RLPField
) {

  let is_single = is_le()

  return(
    field=RLPField(
      byte=0,
      len_len=0,
      len=0,
      data_len=0,
      data=0
    )
  );
}