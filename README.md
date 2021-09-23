# Parallellized dstoken

- [Parallellized dstoken](#parallellized-dstoken)
  - [1. Introduction](#1-introduction)
  - [2.  Background](#2--background)
  - [3. Why ds-token](#3-why-ds-token)
  - [4. What is the Difference](#4-what-is-the-difference)
  - [5. Performance Gain](#5-performance-gain)
  - [6. Tests](#6-tests)

## 1. Introduction

The original ds-token implementation is available at https://github.com/dapphub/ds-token , which is A simple and sufficient ERC20 implementation under GPL-3.0 License.The original implementaion is pretty self explantory so we are not going to explain it in detail.  If you are only interested in trying Arcology testnet out without diving into specific technical details, then [please check this document](./test-scripts.md) out for an easier start.

## 2.  Background

The inter-contract parallelization is relatively straighfoward and intuitive. In many cases, transactions calling different contracts belong to different application can run in parallel easily, and it is what majority of blockchain scaling solutions like sharding and sidechains are trying to achieve.

However, there is another even more challenging scenario in which mulitple transactions are calling the same contract. It is very common for popular applications to have huge incoming user calls. To the best of our knowledge, there is no solution available elsewhere today.

The main purpose of the this ERC20 showcase is to demonstrate how our concurrency framework  takes one step further to help handle **large volumes of concurrent user calls to the same contract**.

## 3. Why ds-token

We chose ds-token mainly because it is simple enough for smart contract developers to easily understand what it is trying to do. On top of that, it is also complex enough to cover some of challenges developers may face in their daily work when considering possible code parallelization.

## 4. What is the Difference

The key to the effective parallelization is to avoid conflicts whereever possible. Conflicts happen when some shared states are accessed by multiple transactions simultaneously.

We made the minor modifications to the original implementation with tools availalbe in our concurreny library to make parallelization possible. In general, we substituted the majority of global variables with local ones. We also used the deferred functions to handle the ones that couldn't be easily replaced. Please check out the [concurrent programming guide]() for details.

The changes are:

- Substituted two global variables: balanceOf, allowance with a ConcurrentHashMap
- Moved totalSupply to a deferred function

## 5. Performance Gain

The new implementation allows parallel processing of concurrent calls to the same contract/interface. Given enough resources, the system can process all the transactions simultaneouly without causing any conflict of rollback at all.

## 6. Tests

- [Interactive](/doc/parallellized-dstoken-interactive.md)
- [Benchmarking](/doc/parallellized-dstoken-benchmarking.md)
