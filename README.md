# Parallellized dstoken

## 1. Introduction

The original ds-token implementation is available at https://github.com/dapphub/ds-token , which is A simple and sufficient ERC20 implementation under GPL-3.0 License.The original implementaion is pretty self explantory so we are not going to explain it in detail.

## 2. Why ds-token

We chose ds-token because it is simple enough for smart contract developers to easily understand what it is trying to do. On top of that, it is also complex enough to cover some of challenges developers may face in their daily work when considering possible code parallelization.

The main purpose of the modification is to demonstrate how out concurrency library can help parallelize a standard ERC20 implemention to handle large volumes of concurrent user calls.

## 3. What is the Difference

The key to the effective parallelization is to avoid conflicts whereever possible. Conflicts happen when some shared states are accessed by multiple transactions simultaneously. We made some minor modifications to the original implementation with tools availalbe in our concurreny library to make parallelization possible. In general, we substituted the majority of global variables with local ones. We also used the deferred functions to handle the ones that couldn't be easily replaced. Please check out our [concurrent programming guide]() for details.

The changes are:

- Substituted two global variables: balanceOf, allowance with a ConcurrentHashMap
- Moved totalSupply to a deferred function

## 4. Performance Gain

The new implementation allows parallel processing of concurrent calls to the same contract/interface.
Given enough resources, the system can process all the transactions simultaneouly without causing any conflict of rollback at all.

## 5. Tests

- [Interactive](/doc/parallellized-dstoken-interactive.md)
- [Benchmarking](/doc/parallellized-dstoken-benchmarking.md)
