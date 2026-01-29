## Project Overview

This repository contains a statistics capstone project exploring how large language models (LLMs) behave in structured decision-making tasks. The core goal of the project is to examine whether changes in how decision rules are written or formatted—rather than changes in their substantive content—can influence an LLM’s outputs.

The project focuses on insurance claim screening as a motivating application, inspired by real-world concerns around fairness and bias in automated decision systems. Rather than assuming model outputs are stable, this work treats LLM behavior as something that can be experimentally probed and evaluated under controlled conditions.

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

## Project Status

This project is currently a work in progress. The repository reflects ongoing experiment design, tooling setup, and iteration. Results and analysis will be added as the project progresses.

---

## Motivation

Large language models are increasingly used in decision-support contexts, yet small design choices—such as how rules are written—may introduce unintended instability or bias. This project aims to better understand those effects and contribute to more thoughtful and responsible use of LLMs in applied settings.
