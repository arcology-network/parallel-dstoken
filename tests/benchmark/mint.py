import sys, math
sys.path.append('../../../../..')

from ammolite import (Cli, HTTPProvider, Account)
from utils import (wait_for_receipts, compile_contracts)

frontend = sys.argv[1]
ds_token_address = sys.argv[2]
owner_key = sys.argv[3]
accounts_file = sys.argv[4]
output = sys.argv[5]

cli = Cli(HTTPProvider(frontend))
compiled_sols = compile_contracts('../../contracts')
ds_token = compiled_sols['../../contracts/token.sol:DSToken']
ds_token_contract = cli.eth.contract(
    abi = ds_token['abi'],
    address = ds_token_address
)

owner = Account(owner_key)
addresses = []
with open(accounts_file, 'r') as f:
    for line in f:
        line = line.rstrip('\n')
        segments = line.split(',')
        addresses.append(segments[1])

lines = []
print('len(addresses) = {}'.format(len(addresses)))
num_batches = int(math.ceil(len(addresses)) / 1000)
#num_batches = 1
for i in range(num_batches):
    batch_start = i * 1000
    batch_end = (i + 1) * 1000
    if i == num_batches - 1:
        batch_end = len(addresses)
    print('batch_start = {}, batch_end = {}'.format(batch_start, batch_end))

    for j in range(batch_start, batch_end):
        raw_tx, tx_hash = owner.sign(ds_token_contract.functions.mint(
            addresses[j],
            10000000000,
        ).buildTransaction({
            'gas': 10000000000,
            'gasPrice': 1,
        }))
        lines.append('{},{}'.format(raw_tx.hex(), tx_hash.hex()))

print('len(lines) = {}'.format(len(lines)))
with open(output, 'a') as f:
    for l in lines:
        f.write(l + '\n')