# 1. DSToken

## 2. Deployment

```shell
$ cd ~/ds_token
$ ./deploy.sh http://192.168.1.111:8080
```

## 3. Test DSToken's mint function

```shell
$ bash sendtxs.sh /data/ds_token_mint_5m/ http://192.168.1.111:8080
```

## 4. Test DSToken's transfer function

```shell
$ bash sendtxs.sh /data/ds_token_transfer_2.5m/ http://192.168.1.111:8080
```

> PLease replace http://192.168.1.111:8080 with the frontend service ip of your node cluster
