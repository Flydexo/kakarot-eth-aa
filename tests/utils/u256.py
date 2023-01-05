ex = (27475701854924583547151667436725731610065771367397776418128450007131302297282).to_bytes(32, 'big');
    
high = ex[0:16]
low = ex[16:32]

print(int.from_bytes(high, 'big'), int.from_bytes(low, 'big'))

print(int.from_bytes(high, 'big')*2**128 + int.from_bytes(low, 'big'))