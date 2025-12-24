# Model Benchmark Report

**Date:** December 23, 2025

**Hardware context:** Apple M3 Max, 64GB RAM

## Experiment Setup

**Input Text:**
> "hey just wanted to follow up on this since i’m still a bit unsure about the direction here — i skimmed the doc and the meeting notes, but i might be missing some context. i’m not trying to slow things down, just want to make sure we’re aligned on ownership, scope, and what actually needs to ship before the deadline"

**Input Size:** 316 characters (approx. 60 words)

**System Prompt:**
```
You are a professional writing assistant. Polish the following text by:
1. Correcting any grammar, spelling, or punctuation errors
2. Rewriting it in a professional business tone
3. Maintaining the original meaning and structure

Return ONLY the polished text without any explanations, quotes, or meta-commentary.

Text to polish:
{{INPUT}}
```

## Executive Summary

Model selection involves a tradeoff between speed and output quality.

*   **Recommendation:** **`llama3.2:3b`** or **`gemma2:2b`**.
*   **Performance:** Both models achieve **1.5s** latency (Warm Start) and **3s** latency (Cold Start).
*   **Quality:** Both strictly adhere to prompt instructions and produce high-quality professional rewrites.

## Benchmark Results

### 1. Latency (Warm Start)
*Models already loaded in memory.*

| Model | Ollama Latency | Turnaround Time | Notes |
| :--- | :--- | :--- | :--- |
| **gemma3:1b** | 852ms | 1121ms | ❌ Fails instruction (includes double quotes) |
| **llama3.2:1b** | 1224ms | 1593ms | ❌ Fails instruction (includes meta-commentary) |
| **llama3.2:3b** | **1080ms** | **1351ms** | ✅ Good quality & instruction following |
| **gemma2:2b** | **1343ms** | **1613ms** | ✅ Good quality & instruction following |
| **qwen3:1.7b** | 5340ms | 5618ms | Too slow (5s+) |
| **qwen3:4b** | 12375ms | 12741ms | Too slow (12s+) |

### 2. Latency (Cold Start)
*Models not loaded in memory.*

| Model | Ollama Latency | Turnaround Time |
| :--- | :--- | :--- |
| **gemma2:2b** | 2955ms | 3300ms |
| **llama3.2:3b** | 3183ms | 3453ms |

### 3. Latency Optimization
*Testing `/no_think` on Qwen models.*

| Model | Variant | Latency (vs Baseline) | Impact |
| :--- | :--- | :--- | :--- |
| **qwen3:1.7b** | `/no_think` | 4487ms (-853ms) | ~16% faster, still too slow |
| **qwen3:4b** | `/no_think` | 9932ms (-2443ms) | ~20% faster, still too slow |

## Quality Assessment

### Recommended Models

#### **llama3.2:3b**
*   **Size:** 2.0GB
*   **Context:** 128K

**Output text:**
> "I wanted to follow up on this matter as I am still unclear about the direction moving forward. Upon reviewing the documentation and meeting notes, I may have missed some context. My intention is not to cause a delay, but rather to ensure we are aligned on key aspects such as ownership, scope, and what must be delivered by the deadline."

**Verdict:** Professional, concise, retains exact meaning.

#### **gemma2:2b**
*   **Size:** 1.6GB
*   **Context:** 8K

**Output text:**
> "I wanted to follow up on this since I am still unsure about the direction. After reviewing the document and meeting notes, I may be missing some context. My goal is not to slow down progress; rather, I want to ensure we are aligned on ownership, scope, and what needs to be shipped by the deadline."

**Verdict:** Slightly more direct, high quality.

### Rejected Models

*   **llama3.2:1b**: Fast but often includes conversational prefix ("Here is the polished text:"), breaking the contract to return only the text.
*   **gemma3:1b**: Fast but wraps output in double quotes, breaking the contract to return only the text.
*   **qwen3:1.7b**: High latency (~5s), not viable for real-time interaction despite acceptable quality.
*   **qwen3:4b**: Very high latency (~12s), unacceptable user experience.
