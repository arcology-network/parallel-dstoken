import sys, os, time
sys.path.append('../../..')
from solcx import compile_files
from ammolite import (Cli, HTTPProvider, Account)
from rich.console import Console

sol_dir = sys.argv[1]
frontend = sys.argv[2]
owner_key = sys.argv[3]

sols = []
for root, _, files in os.walk(sol_dir):
    for f in files:
        if f.endswith('.sol'):
            sols.append(os.path.join(root, f))

compiled_sols = compile_files(sols, output_values = ['abi', 'bin'])
ds_token = compiled_sols[sol_dir + 'token.sol:DSToken']

cli = Cli(HTTPProvider(frontend))
ds_token_contract = cli.eth.contract(
    abi = ds_token['abi'],
    bytecode = ds_token['bin'],
)

contract_owner = Account(owner_key)

console = Console()
with console.status('[bold green]Working on tasks...') as status:
    raw_tx, tx_hash = contract_owner.sign(ds_token_contract.constructor(b'DST').buildTransaction({
        'nonce': 1,
        'gas': 10000000000,
        'gasPrice': 1,
    }))
    print(tx_hash.hex())
    cli.sendTransactions({tx_hash: raw_tx})

    while True:
        time.sleep(1)
        receipts = cli.getTransactionReceipts([tx_hash])
        #print(receipts)
        if receipts is None or len(receipts) != 1:
            continue
        if receipts[0]['status'] != 1:
            console.log('Deploy DSToken failed.')
            exit(1)
        print(receipts)
        console.log('Deploy DSToken at {}.'.format(receipts[0]['contractAddress']))
        break