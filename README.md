## Project Overview

This repository contains a statistics capstone project exploring how large language models (LLMs) behave in structured decision-making tasks. The core goal of the project is to examine whether changes in how decision rules are written or formatted—rather than changes in their substantive content—can influence an LLM’s outputs.

The project focuses on insurance claim screening as a motivating application, inspired by real-world concerns around fairness and bias in automated decision systems. Rather than assuming model outputs are stable, this work treats LLM behavior as something that can be experimentally probed and evaluated under controlled conditions.

---

## Motivation

Large language models are increasingly used in decision-support contexts, yet small design choices—such as how rules are written—may introduce unintended instability or bias. This project aims to better understand those effects and contribute to more thoughtful and responsible use of LLMs in applied settings.

---

## Experiment Design

We assume access to a dataset of insurance claims, where each record contains claimant attributes such as age, gender, injury description, and prior history. For each claim, an LLM is prompted to make a screening decision (approve, deny, or request additional information). This decision is stored as a new outcome variable.

The experiment consists of multiple conditions:

- **Baseline (Placebo):** The LLM receives no explicit insurance policies and must rely solely on its internal reasoning.
- **Policy Conditions:** The LLM is provided with different versions of insurance policies that vary in presentation (e.g., reordered rules, bullet points vs. prose, simplified vs. detailed language) while keeping the underlying policy intent consistent.

For each condition, regression models are fit using the LLM’s decisions as the response variable and claimant attributes as predictors. By comparing coefficient estimates across conditions, we analyze:
1. Which claimant attributes appear to influence the LLM’s decisions, and  
2. Whether changes in policy formatting alter these relationships or overall decision patterns.

This approach prioritizes interpretability and controlled comparison over predictive performance.

---

## Technical Stack

- **Python**: Interfacing with the LLM via API (Gemma 3 through the Gemini API)
- **R**: Data cleaning, regression modeling, and result analysis
- **LLM**: Google Gemma 3 (primarily 4B-it)

The pipeline is intentionally modular, separating model interaction from statistical analysis.

---

## Data

- claims.csv contains a **synthetic insurance claims dataset** created for testing purposes.
- The structure of the dataset is inspired by real-world insurance claim forms.
- Variables include claimant demographics, diagnosis or injury type, service type, severity, network status, documentation completeness, and claim amount.
- All records are fictitious and used solely to study LLM behavior.

---

## Prompt Structure

A single prompt template (universal_prompt.txt) is used across all experiments.

Each prompt consists of:
- A POLICY section (which may be empty in the placebo condition), and
- A CLAIM section populated with variables from claims.csv.

The LLM is instructed to return only one decision label:
- APPROVE
- DENY
- NEED_MORE_INFO

Restricting outputs to a single categorical decision avoids noise from free-form explanations and simplifies downstream statistical analysis.

---

## First-Pass Experiment (Current Implementation)

As an initial step, we implement a small-scale, first-pass experiment to verify that:
1.	An LLM can be prompted with structured insurance claim information,
2.	The model produces non-trivial and varied decision outputs, and
3.	The experiment can be automated and scaled in later iterations.

In the current implementation:
- The placebo condition uses an empty policy file (policy00_placebo.txt).
- Each claim is evaluated independently by the LLM.
- Model decisions are saved to outputs/results.csv.

Preliminary results show a mix of approvals, denials, and requests for additional information, indicating that the model is not producing uniform or degenerate outputs. This confirms that the experimental setup is suitable for further analysis and expansion.

---

## Repository Contents

- test.py – Python script that runs claims through the LLM and records decisions
- claims.csv – Synthetic insurance claims dataset
- universal_prompt.txt – Shared prompt template
- policies/ – Policy text files (currently includes placebo condition)
- outputs/results.csv – Saved outputs from the first-pass experiment

---

## Project Status and Next Steps

This repository reflects an early, exploratory stage of the project. The current focus is on validating experimental feasibility, output variability, and automation.

Planned next steps include:
- Adding multiple policy formats for comparison,
- Expanding the dataset size,
- Systematically varying protected attributes for fairness analysis,
- Conducting regression analysis in R to compare decision patterns across conditions.

---

## Sources and Citations
Our project is inspired by and developed from the following sources:
- https://www.cbsnews.com/news/unitedhealth-lawsuit-ai-deny-claims-medicare-advantage-health-insurance-denials/
- https://www.theguardian.com/us-news/2025/jan/25/health-insurers-ai
