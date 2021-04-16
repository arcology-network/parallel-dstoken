import sys, math
sys.path.append('../../../../..')

from ammolite import (Cli, HTTPProvider, Account)
from utils import (wait_for_receipts, compile_contracts)

frontend = sys.argv[1]
ds_token_address = sys.argv[2]
num_ktxs = int(sys.argv[3])
accounts_file = sys.argv[4]
output = sys.argv[5]

cli = Cli(HTTPProvider(frontend))
compiled_sols = compile_contracts('../../contracts')
ds_token = compiled_sols['../../contracts/token.sol:DSToken']
ds_token_contract = cli.eth.contract(
    abi = ds_token['abi'],
    address = ds_token_address
)

private_keys = []
addresses = []
with open(accounts_file, 'r') as f:
    for line in f:
        line = line.rstrip('\n')
        segments = line.split(',')
        private_keys.append(segments[0])
        addresses.append(segments[1])

lines = []
num_per_batch = 2000

def make_one_batch(i):
    for j in range(int(num_per_batch / 2)):
        acc = Account(private_keys[int(i * num_per_batch + j)])
        raw_tx, tx_hash = acc.sign(ds_token_contract.functions.transfer(
            addresses[int(i * num_per_batch + num_per_batch / 2 + j)],
            1,
        ).buildTransaction({
            'gas': 10000000000,
            'gasPrice': 1,
        }))
        lines.append('{},{}\n'.format(raw_tx.hex(), tx_hash.hex()))
print(num_ktxs)
for i in range(num_ktxs):
    print(i)
    make_one_batch(i)

with open(output, 'w') as f:
    for l in lines:
        f.write(l)