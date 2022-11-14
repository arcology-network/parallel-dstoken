# 1. DSToken
In your in to Ammolite docker container execute the commands below to run the performance benchmarking. Replace `http://192.168.1.111` with the Arcology node your are connected to.

## 2. Deployment

```shell
$ cd ~/ds_token
$ ./deploy.sh http://192.168.1.111:8080
```

## 3. Benchmark the Mint Function

```python
>python sendtxs.py http://192.168.1.106:8080 data/ds_token_mint/ds_token_mint_5m_1m.out
```

## 4. Benchmark the Transfer Function

```shell
$ bash sendtxs.sh /data/ds_token_transfer_2.5m/ http://192.168.1.111:8080
```

