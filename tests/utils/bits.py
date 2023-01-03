def to_uint(a):
    a = int(a)
    return (a & ((1 << 128) - 1), a >> 128)

def combine_ints(high, low):
    return (high << 128) | low    