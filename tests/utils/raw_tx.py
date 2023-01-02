import web3
import eth_keys

defaultAccount: web3.eth.Account = web3.eth.Account().create()

tx = defaultAccount.sign_transaction(dict(
    nonce=1,
    chainId=9000,
    maxFeePerGas=1000,
    maxPriorityFeePerGas=667667,
    gas=999999999,
    to=bytes.fromhex('95222290dd7278aa3ddd389cc1e1d165cc4bafe5'),
    value=10000000000000000,
    data=b''
))

print(tx)
