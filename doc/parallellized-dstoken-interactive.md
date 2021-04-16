Find all the Solidity source code, save the filenames in a list **sols**.
> Here we suppose the source code are located in '../../contracts'.
```Python
>>> import os
>>> sols = []
>>> for root, _, files in os.walk('../../contracts'):
>>>     for f in files:
>>>         if f.endswith('.sol'):
>>>             sols.append(os.path.join(root, f))
```

Use solcx's compile_files function to compile the source code, output ABI information.
```Python
>>> from solcx import compile_files
>>> compiled_sols = compile_files(sols, output_values = ['abi'])
>>> ds_token = compiled_sols['../../contracts/token.sol:DSToken']
```

Initilize ammolite's Cli object, create a ds_token_contract object with it. The ds_token_contract object will be used to manipulate the DSToken contract in the following steps. Bind the ds_token_contract to the deployment address of DSToken.
> Here we use the deploy.py script to deploy the DSToken contract. The command line we used is 'python deploy.py ../../contracts/ http://192.168.1.111:8080 ab3884806d0351e807b2e17a26ed38238deacfa53cc3c552a27bd7d62fbfb987', which may be differ in your environment.
```Python
>>> from ammolite import (Cli, HTTPProvider, Account)
>>> cli = Cli(HTTPProvider('http://192.168.1.111:8080'))
>>> ds_token_contract = cli.eth.contract(
>>>     abi = ds_token['abi'],
>>>     address = '842d4bfdb1904503ac152483527f338cd5d9bcba',
>>> )
```

To continue the test, initialize three accounts, one of which is the owner of DSToken, who has the authority to call the **mint** function. The other two are common users.
> The owner's private key should be the same as the one used in the call of deploy.py script above.
```Python
>>> owner = Account('ab3884806d0351e807b2e17a26ed38238deacfa53cc3c552a27bd7d62fbfb987')
>>> common_user1 = Account('a2ffe69115c1f2f145297a4607e188775a1e56907ca882b7c6def550f218fa84')
>>> common_user2 = Account('d9815a0fa4f31172530f17a6ae64bf5f00a3a651f3d6476146d2c62ae5527dc4')
```

Use the owner's account to sign a mint transaction, give common_user1 100 tokens. Send the signed transaction to the network with **sendTransactionss**.
```Python
>>> raw_tx, tx_hash = owner.sign(ds_token_contract.functions.mint(
>>>     common_user1.address(),
>>>     100
>>> ).buildTransaction({
>>>     'gas': 10000000000,
>>>     'gasPrice': 1,
>>> }))
>>> cli.sendTransactions({tx_hash: raw_tx})
```

Wait a few seconds (usually 3 to 5 seconds) until the transaction was processed by the network, use the transaction hash to query the receipt. We will see that the transaction had been processed successfully (status = 1), and logs had been produced.
```Python
>>> receipts = cli.getTransactionReceipts([tx_hash])
>>> receipts
[{'status': 1, 'contractAddress': '0000000000000000000000000000000000000000', 'gasUsed': 32136, 'logs': [{'address': '842d4bfdb1904503ac152483527f338cd5d9bcba', 'topics': ['0f6798a560793a54c3bcfe86a93cde1e73087d944c0ea20544137d4121396885', '000000000000000000000000230dccc4660dcbecb8a6aea1c713ee7a04b35cad'], 'data': '0000000000000000000000000000000000000000000000000000000000000064', 'blockNumber': 1593, 'transactionHash': '0000000000000000000000000000000000000000000000000000000000000000', 'transactionIndex': 0, 'blockHash': '0000000000000000000000000000000000000000000000000000000000000000', 'logIndex': 0}], 'executing logs': '', 'spawned transactionHash': 'c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470', 'height': 1593}]
```

Use ds_token_contract object to parse the logs in the receipt, we will see that a **Mint** event was included, with a **guy** parameter indicating the user address the token given to, and a **wad** parameter indicating the amount of tokens (64 in hex is 100 in decimal). Check the address of common_user1, we can see it is the same as the address in **guy**, which means the transaction was done correctly.
```Python
>>> ds_token_contract.processReceipt(receipts[0])
{'Mint': {'guy': '000000000000000000000000230dccc4660dcbecb8a6aea1c713ee7a04b35cad', 'wad': '0000000000000000000000000000000000000000000000000000000000000064'}}
>>> common_user1.address()
'0x230dccc4660dcbecb8a6aea1c713ee7a04b35cad'
```

Use common_user1's account to sign a transfer transaction, give common_user2 50 tokens. Send the signed transaction to the network.
```Python
>>> raw_tx, tx_hash = common_user1.sign(ds_token_contract.functions.transfer(
>>>     common_user2.address(), 
>>>     50
>>> ).buildTransaction({
>>>     'gas': 10000000000,
>>>     'gasPrice': 1
>>> }))
>>> cli.sendTransactions({tx_hash: raw_tx})
```

Wait a few seconds until the transaction was processed, use the transaction hash to query the receipt. We will see the transaction had been processed successfully (statue = 1), and logs had been produced.
```Python
>>> receipts = cli.getTransactionReceipts([tx_hash])
>>> receipts
[{'status': 1, 'contractAddress': '0000000000000000000000000000000000000000', 'gasUsed': 32755, 'logs': [{'address': '842d4bfdb1904503ac152483527f338cd5d9bcba', 'topics': ['ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef', '000000000000000000000000230dccc4660dcbecb8a6aea1c713ee7a04b35cad', '0000000000000000000000008aa62d370585e28fd2333325d3dbaef6112279ce'], 'data': '0000000000000000000000000000000000000000000000000000000000000032', 'blockNumber': 1828, 'transactionHash': '0000000000000000000000000000000000000000000000000000000000000000', 'transactionIndex': 0, 'blockHash': '0000000000000000000000000000000000000000000000000000000000000000', 'logIndex': 0}], 'executing logs': '', 'spawned transactionHash': '0000000000000000000000000000000000000000000000000000000000000000', 'height': 1828}]
```

Use ds_token_contract object to parse the logs in the receipt, we will see that a **Transfer** event was included, with a **src** parameter indicating the sender's address (equals to common_user1's address), a **dst** parameter indicating the receiver's address (equals to common_user2's address), a **wad** parameter indicating the amount of tokens transferred (32 in hex equals to 50 in decimal).
```Python
>>> ds_token_contract.processReceipt(receipts[0])
{'Transfer': {'src': '000000000000000000000000230dccc4660dcbecb8a6aea1c713ee7a04b35cad', 'dst': '0000000000000000000000008aa62d370585e28fd2333325d3dbaef6112279ce', 'wad': '0000000000000000000000000000000000000000000000000000000000000032'}}
>>> common_user2.address()
'0x8aa62d370585e28fd2333325d3dbaef6112279ce'
```