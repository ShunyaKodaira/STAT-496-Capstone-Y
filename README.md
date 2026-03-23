## Project Overview

This repository contains a statistics capstone project investigating how large language models (LLMs) behave in structured decision-making environments. The central objective of this study is to evaluate whether non-substantive changes in policy presentation — such as formatting differences — can influence model decision outcomes.

Using insurance claim screening as a motivating application, this project experimentally examines the stability, fairness, and consistency of LLM-generated decisions under controlled variations in prompt structure.

Rather than assuming LLM outputs are stable or deterministic, this work treats model behavior as an empirical object of study.

---

## Motivation

LLMs are increasingly integrated into decision-support systems across domains such as healthcare administration, insurance adjudication, and automated risk assessment. However, concerns remain regarding:
-	Decision instability
-	Procedural fairness
-	Sensitivity to prompt design
-	Reliability in high-stakes contexts

This project explores whether variations in how policies are presented — rather than what policies state — can lead to systematic differences in model decision behavior.

Understanding these effects is essential for responsible deployment of LLM-based decision systems.

---

## Experiment Design

The experiment evaluates three model scales of Google’s Gemma 3 family:
-	Gemma 3 4B-it
-	Gemma 3 12B-it
-	Gemma 3 27B-it

Each model evaluates the same synthetic insurance claims dataset under seven policy presentation conditions:

-	Placebo (no policy)
-	Prose
-	Bullet-point
-	Decision tree
-	Bias-emphasis
-	Minimal
-	Verbose

Models are required to return a structured categorical output:
-	APPROVE
-	DENY
-	NEED_MORE_INFO

The full experiment consists of:

**2,100 total evaluations**
(3 models × 7 policy formats × 100 claims)

This controlled design allows isolation of formatting effects while holding policy content constant.

---

## Analysis Approach

Model outputs are analyzed using statistical methods including:
- Logistic regression (policy effects on approval probability)
- Multinomial outcome modeling
- Decision stability metrics across prompt conditions
- Contingency analysis (policy–decision dependence)
- Adjusted fairness analysis controlling for claim attributes

Key research questions include:
- Does policy formatting influence decision outcomes?
- Does model scale improve decision stability?
- Which claim features drive model decisions?
- Do formatting changes introduce demographic bias?
  
---

## Technical Stack

- **Python**: LLM interaction and experimental automation
- **R**: Statistical modeling and data analysis
- **LLM**: Google Gemma 3 (4B-it, 12B-it, 27B-it)

The workflow separates inference generation from statistical evaluation to ensure reproducibility.

---

## Dataset

- medical claims.csv contains a **synthetic insurance claims dataset**
- Designed to mimic real administrative claim structures
- Includes variables such as:
  - Demographics
  - Diagnosis / injury description
  - Severity
  - Network status
  - Documentation completeness
  - Claim amount

All records are fictitious and used solely for experimental analysis.

---

## Prompt Structure

A shared prompt template (universal_prompt.txt) is used across all conditions.

Each prompt includes:
- POLICY section (varies by experimental condition)
- CLAIM section populated from dataset

Output restriction to categorical labels ensures:
- Reduced response variability
- Improved statistical interpretability
- Consistent downstream modeling

---

## Key Findings

Major findings of the study include:
- Policy formatting significantly affects approval outcomes
- Larger models exhibit greater decision stability, but not perfectly
- Administrative completeness signals dominate decision behavior
- No significant adjusted demographic bias detected
- Mid-scale models may exhibit unpredictable prompt sensitivity

These results suggest that LLM decision systems require structured validation prior to deployment.

---

## Repository Contents

- test.py – LLM evaluation pipeline
- medical claims.csv – Synthetic dataset
- policies/ – Policy formatting variants
- universal_prompt.txt – Shared prompt template
- outputs/ – Model decision results
- Insurance Claims Analysis.R - Statistical modeling scripts
- Final Report.pdf - Final capstone report
- video2726191015.mp4 - Recorded presentation

---

## Research Implications

This work contributes to ongoing discussions regarding:

- Prompt sensitivity in LLM decision pipelines
- Reliability of AI-assisted administrative decision systems
- Procedural fairness in automated screening environments
- Model validation requirements for high-stakes applications

---

## Sources and Citations
The project is informed by research and reporting on AI deployment in insurance systems:
- CBS News investigation on AI claim denials (https://www.cbsnews.com/news/unitedhealth-lawsuit-ai-deny-claims-medicare-advantage-health-insurance-denials/)
- The Guardian reporting on insurer AI usage (https://www.theguardian.com/us-news/2025/jan/25/health-insurers-ai)
- PROSA prompt sensitivity framework (https://arxiv.org/abs/2410.12405)
- Gemma model documentation (https://deepmind.google/models/gemma/gemma-3/)

Full citations are provided in the accompanying paper.
