# 1. DSToken

## 2. Deployment

```shell
$ cd ~/ds_token
$ ./deploy.sh http://192.168.1.111:8080
```

## 3. Test DSToken's mint function

```shell
$ ./send_mint_txs.sh http://192.168.1.111:8080
```

## 4. Test DSToken's transfer function

```shell
$ ./send_token_transfer_txs.sh http://192.168.1.111:8080
```

> PLease replace http://192.168.1.111:8080 with the frontend service ip of your node cluster