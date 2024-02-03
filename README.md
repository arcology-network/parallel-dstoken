# Parallellized dstoken

- [Parallellized dstoken](#parallellized-dstoken)
  - [1. Introduction](#1-introduction)
    - [1.1. Quick Start](#11-quick-start)
    - [1.2. Goal](#12-goal)
    - [1.3. Why ds-token](#13-why-ds-token)
  - [2. Benefits](#2-benefits)
  - [3. Changes](#3-changes)
  - [4. Performance](#4-performance)

## 1. Introduction

The original ds-token implementation is available at https://github.com/dapphub/ds-token. It is A simple and sufficient ERC20 implementation under GPL-3.0 License.The original implementation is pretty self explanatory. 

In many cases, transactions calling different contracts belong to different application can run in parallel easily, and it is what majority of blockchain scaling solutions like sharding and sidechains are trying to achieve. Another even more challenging scenario is where multiple transactions are calling the same contract. 

### 1.1. Quick Start

If you are only interested in trying Arcology testnet out without diving into specific technical details, then [please check this document](./parallel-dstoken-test-scripts.md) out for an easier start.

### 1.2. Goal

The main goal of the this ERC20 showcase is to demonstrate how Arcology's [concurent library](https://github.com/arcology-network/concurrentlib)
 can help handle **large volumes of concurrent user calls to the same contract**.

### 1.3. Why ds-token

The ds-token is chosen because it is simple enough for smart contract developers to easily understand what it is trying to do. On top of that, it is also complex enough to cover some of challenges developers may face in their daily work when considering possible code parallelization.

## 2. Benefits

The new implementation allows processing of concurrent calls to the same functions of the contract. For example, the `mint` and the`burn` function can be called by multiple users at the same time without any problem.

## 3. Changes

Some modifications to the original implementation have been made with tools available in our concurrency library to make parallelization possible. arcology-concurrent-programming-guide/) for details. The following changes have been made to the original implementation:

- Replace the global variables `totalSupply` and `allowance` with a commutative `uint256` from the `concurrentlib`.

- The `mint` and `burn` operate on the `totalSupply` by call `add` and `sub` on the `totalSupply`, instead of directly modifying it.

## 4. Performance 

<!-- ## 5. Tests

- [Interactive](/doc/parallellized-dstoken-interactive.md)
- [Benchmarking](/doc/parallellized-dstoken-benchmarking.md) -->
