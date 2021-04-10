# parallel-dstoken

## Introduction

The original ds-token implementation is available at https://github.com/dapphub/ds-token , which is A simple and sufficient ERC20 implementation under GPL-3.0 License.The original implementaion is pretty self explantory so we are not going to explain it in detail.

## Why ds-token

We choose the ds-token because it is simple enough for smart contract developers to easily understand. On the other hand, it is also complex enough to cover some of challeges developers may be facing in their daily work. The mainly purpose of the modification is to demonstrate how Arcology's concurrency library can help with parallelizing a standard ERC20 implemention to handle concurrent user calls.

## What is the difference

In general, global variables are the major source of conflict, so the goal is to replace global variables with local ones. In case where some shared variables are necessary, Arcology also has corresponding solutions as well. Please check out our [concurrent programming guide]() for details.

The key to effective parallelization is to make avoid conflict whereever possible. conflicts happen when some shared states are modified by multiple transactions simultaneously. We made some minor modifications to the original implementation with tools availalbe in Arcology's concurreny library to make parallelization exeuction possible. These changes are:

- Replaced two global variables: balanceOf, allowance with a ConcurrentHashMap
- Moved totalSupply modification to a defer function

## Performance Gain

The [intro-contract parallelization]() only allows concurrent calls to different contracts. However, it is totally incapable of dealing with concurrent calls to the same contracts or even the same interfaces of the same contracts.

For example, if there are 1K of users calls to the mint interface, the system has to execute them one by one by one even with the inter-contract parallelization enabled. Any parallel execution attempt only results in massive transaction rollbacks.

**In contrast, the new implementation allows parallel processing of concurrent calls to the same contract/interface.**
Given enough resources, the system can process all the transactions simultaneouly without causing any conflict of rollback at all.
