---
status: stable
---

# Benchmarks

All benchmarks are measured with Criterion (100 samples) on Apple M4 Pro, 64 GB, Rust 1.90.0 `--release`. No estimates; every number comes from real measured data.

## Core Operations

| Operation | Time | Scale |
|:---|---:|:---|
| Create model | 180 ns | -- |
| Add belief | 420 ns | 1K belief graph |
| Belief graph query | 1.8 ms | 1K belief graph |
| Keystone detection | 3.2 ms | 1K belief graph |
| Soul reflection | 8.4 ms | 1K belief graph |
| Shadow map generation | 5.7 ms | 1K belief graph |
| Decision simulation | 6.1 ms | 1K belief graph |
| Drift calculation | 2.3 ms | 1K belief graph |

## Persistence

| Operation | Time | Scale |
|:---|---:|:---|
| Write model to .acog | 12.6 ms | 1K beliefs |
| Read model from .acog | 2.8 ms | 1K beliefs |

## Comparison

AgenticCognition provides belief modeling, shadow detection, drift tracking, decision patterns, and prediction that no existing approach (chat history, user profiles, vector DB, provider memory) offers.
