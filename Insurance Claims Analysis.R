# ============================================================
# STAT 496 Capstone — Insurance Claims LLM Experiment
# Analysis script
#
# Core questions:
# (1) Does policy FORMAT change decision distributions?
# (2) Is there evidence of demographic bias (gender) after controlling for claim factors?
# (3) Does any gender effect differ by policy FORMAT (interaction)?
# (4) Do results differ across MODEL sizes (4B vs 12B vs 27B)?
# (Optional) How unstable are decisions across formats (flip rate)?
# ============================================================

# Required libraries
library(dplyr)
library(nnet)
library(purrr)
library(broom)

# -------------------------------------
# 1) Load data and standardize columns
# -------------------------------------
# Note: Might need to either put the datasets in the same folder as this R file,
# or put pathnames instead in the parentheses
claims <- read.csv("medical claims.csv", stringsAsFactors = FALSE)
results_4bit <- read.csv("results_4bit.csv", stringsAsFactors = FALSE)
results_12bit <- read.csv("results_12bit.csv", stringsAsFactors = FALSE)
results_27bit <- read.csv("results_27bit.csv", stringsAsFactors = FALSE)

results_all <- bind_rows(
  results_4bit,
  results_12bit,
  results_27bit
)

# Merge once
full_data <- results_all %>%
  left_join(claims, by="claim_id")

# (Optional: per model)
full_data_4bit <- results_4bit %>%
  left_join(claims, by = "claim_id")

full_data_12bit <- results_12bit %>%
  left_join(claims, by = "claim_id")

full_data_27bit <- results_27bit %>%
  left_join(claims, by = "claim_id")

# -------------------------------------
# 2) Type cleaning (factors vs numeric)
# -------------------------------------
# Keep these numeric
numeric_cols <- c("age", "claim_amount")

analysis_data <- full_data %>%
  mutate(
    across(any_of(numeric_cols), as.numeric),
    across(where(is.character), as.factor)
  )

# (Optional: per model)
analysis_data_4bit <- full_data_4bit %>%
  select(-model) %>%
  mutate(across(where(is.character), as.factor))

analysis_data_12bit <- full_data_12bit %>%
  select(-model) %>%
  mutate(across(where(is.character), as.factor))

analysis_data_27bit <- full_data_27bit %>%
  select(-model) %>%
  mutate(across(where(is.character), as.factor))

# Quick sanity checks: Inspect distributions (counts)
  # Decision counts (overall):
  table(analysis_data$decision)

  # Decision counts by model:
  table(analysis_data$model, analysis_data$decision)

  # Decision counts by policy (all models pooled):
  table(analysis_data$policy_id, analysis_data$decision)

# Extra sanity checks (probability)
  # Decision counts percentage (overall):
  prop.table(table(analysis_data$decision))
  
  # Decision counts percentage by model:
  prop.table(table(analysis_data$model, analysis_data$decision))
  
  # Decision counts percentage by policy (all models pooled):
  prop.table(table(analysis_data$policy_id, analysis_data$decision))

# Extra sanity checks 2: Inspect distributions per prompt per model
table(analysis_data_4bit$policy_id, analysis_data_4bit$decision)
table(analysis_data_12bit$policy_id, analysis_data_12bit$decision)
table(analysis_data_27bit$policy_id, analysis_data_27bit$decision)

# ---------------------------------------------------------
# 3) Helper: chi-square policy × decision per model
# ---------------------------------------------------------
# Test if decision depends on policy
  # H0: Decision independent of policy format
  # H1: Decision depends on policy format
chisq_policy_by_model <- function(df) {
  tab <- table(df$policy_id, df$decision)
  out <- suppressWarnings(chisq.test(tab))
  tibble(
    statistic = unname(out$statistic),
    df = unname(out$parameter),
    p_value = out$p.value
  )
}

# Chi-square test: policy_id × decision (per model)
chisq_by_model <- analysis_data %>%
  group_by(model) %>%
  group_modify(~ chisq_policy_by_model(.x)) %>%
  ungroup()

print(chisq_by_model)

# ---------------------------------------------------------
# 4) Main effect: does policy affect APPROVE rate?
#    (Binary logistic regression; easy to interpret)
# ---------------------------------------------------------
analysis_data <- analysis_data %>%
  mutate(approve = as.integer(decision == "APPROVE"))

glm_policy_only <- glm(
  approve ~ policy_id,
  family = binomial,
  data = analysis_data
)

# Logistic model: approve ~ policy_id (all models pooled)
summary(glm_policy_only)

# Odds ratios (APPROVE) by policy_id (vs baseline policy level):
policy_or <- tidy(glm_policy_only, conf.int = TRUE, exponentiate = TRUE) %>%
  filter(term != "(Intercept)") %>%
  arrange(desc(estimate))

print(policy_or)

# -------------------------------------------------------------
# 5) Adjusted bias test (gender), controlling for claim factors
#    + policy main effect
# -------------------------------------------------------------
# Raw version (before adjusting)
chisq.test(table(analysis_data$gender, analysis_data$decision))
chisq.test(table(analysis_data_4bit$gender, analysis_data_4bit$decision))
chisq.test(table(analysis_data_12bit$gender, analysis_data_12bit$decision))
chisq.test(table(analysis_data_27bit$gender, analysis_data_27bit$decision))

# Choose a small set of medically-relevant covariates to control
# (keep this stable across all analyses)
covars <- c("age", "severity", "preexisting",
            "docs_complete", "claim_amount")

# Build formula programmatically (prevents manual typing errors)
f_bias <- as.formula(
  paste("approve ~ gender + policy_id +", paste(covars, collapse = " + "))
)

# Adjusted version
glm_bias <- glm(
  f_bias,
  family = binomial,
  data = analysis_data
)

# Adjusted bias model: approve ~ gender + policy_id + covars (pooled)
# (If gender coefficient significant -> evidence of differential approval odds)
summary(glm_bias)

# (Optional: per model)
analysis_data_4bit <- analysis_data_4bit %>%
  mutate(approve = as.integer(decision == "APPROVE"))

analysis_data_12bit <- analysis_data_12bit %>%
  mutate(approve = as.integer(decision == "APPROVE"))

analysis_data_27bit <- analysis_data_27bit %>%
  mutate(approve = as.integer(decision == "APPROVE"))

glm_bias_4b <- glm(
  f_bias,
  family = binomial,
  data = analysis_data_4bit
)

glm_bias_12b <- glm(
  f_bias,
  family = binomial,
  data = analysis_data_12bit
)

glm_bias_27b <- glm(
  f_bias,
  family = binomial,
  data = analysis_data_27bit
)

summary(glm_bias_4b)
summary(glm_bias_12b)
summary(glm_bias_27b)

# Gender odds ratio (Male vs baseline gender level):
bias_or <- tidy(glm_bias, conf.int = TRUE, exponentiate = TRUE) %>%
  filter(term %in% c("genderMale"))

print(bias_or)

# (Optional: per model)
bias_or_4b <- tidy(glm_bias_4b, conf.int = TRUE, exponentiate = TRUE) %>%
  filter(term %in% c("genderMale"))
bias_or_12b <- tidy(glm_bias_12b, conf.int = TRUE, exponentiate = TRUE) %>%
  filter(term %in% c("genderMale"))
bias_or_27b <- tidy(glm_bias_27b, conf.int = TRUE, exponentiate = TRUE) %>%
  filter(term %in% c("genderMale"))

print(bias_or_4b)
print(bias_or_12b)
print(bias_or_27b)

# ------------------------------------------------------------
# 6) Does gender effect differ by policy format? (Interaction)
# ------------------------------------------------------------
f_int <- as.formula(
  paste("approve ~ gender * policy_id +", paste(covars, collapse = " + "))
)

glm_bias_int <- glm(
  f_int,
  family = binomial,
  data = analysis_data
)

# Interaction model: approve ~ gender*policy_id + covars (pooled)
summary(glm_bias_int)

#Likelihood ratio test: (no interaction) vs (gender*policy interaction)
anova(glm_bias, glm_bias_int, test = "Chisq")

# (Optional: per model)
glm_bias_int_4b <- glm(
  f_int,
  family = binomial,
  data = analysis_data_4bit
)

glm_bias_int_12b <- glm(
  f_int,
  family = binomial,
  data = analysis_data_12bit
)

glm_bias_int_27b <- glm(
  f_int,
  family = binomial,
  data = analysis_data_27bit
)

anova(glm_bias_4b, glm_bias_int_4b, test = "Chisq")
anova(glm_bias_12b, glm_bias_int_12b, test = "Chisq")
anova(glm_bias_27b, glm_bias_int_27b, test = "Chisq")

# ----------------------------------------------------------------
# 7) Cross-model comparison:
#    Do models differ overall?
#    Does policy effect differ by model?
#    What about bias in gender by Model?
# ----------------------------------------------------------------
f_main <- as.formula(
  paste("approve ~ policy_id + model + gender + ", paste(covars, collapse = " + "))
)

f_main_int <- as.formula(
  paste("approve ~ policy_id * model + gender +", paste(covars, collapse = " + "))
)

f_gender_int <- as.formula(
  paste("approve ~ gender * model + policy_id +", paste(covars, collapse = " + "))
)

glm_model_main <- glm(
  f_main,
  family = binomial,
  data = analysis_data
)

glm_policy_model_int <- glm(
  f_main_int,
  family = binomial,
  data = analysis_data
)

glm_gender_model_int <- glm(
  f_gender_int,
  family = binomial,
  data = analysis_data
)

# Model main effects + policy main effects (pooled)
summary(glm_model_main)

# Does policy effect differ by model size? LRT: policy*model interaction
anova(glm_model_main, glm_policy_model_int, test = "Chisq")

# Does bias in gender change by model? LRT: gender*model interaction
anova(glm_model_main, glm_gender_model_int, test="Chisq")

# -----------------------------------------------------------------------
# 8) Optional: instability across formats (flip rate)
#    For each (claim_id, model), did the decision change across policies?
# -----------------------------------------------------------------------
# How many different decisions did it receive?
instability <- analysis_data %>%
  group_by(model, claim_id) %>%
  summarise(n_unique = n_distinct(decision), .groups = "drop") %>%
  mutate(flipped = as.integer(n_unique > 1))

flip_rates <- instability %>%
  group_by(model) %>%
  summarise(
    flip_rate = mean(flipped),
    n_claims = n(),
    .groups = "drop"
  )

# Instability (flip rate across policies), by model:
  # If high -> formatting creates instability.
print(flip_rates)

# Optional: what claim features predict instability?
# (Uses one row per claim_id per model)
instability_with_claims <- instability %>%
  left_join(claims, by = "claim_id") %>%
  mutate(
    across(any_of(numeric_cols), as.numeric),
    across(where(is.character), as.factor)
  )

f_flip <- as.formula(
  paste("flipped ~ model + gender + ", paste(covars, collapse = " + "))
)

glm_flip <- glm(
  f_flip,
  family = binomial,
  data = instability_with_claims
)

summary(glm_flip)

# ------------------------------------------
# Extra (feel free to play around
# ------------------------------------------

# Fairness Metrics
approval_gender <- analysis_data %>%
  group_by(model, policy_id, gender) %>%
  summarise(approval_rate = mean(decision == "APPROVE"))

# Dataset per policy
policy0_data <- analysis_data_4bit %>%
  filter(policy_id == "policy00_placebo") %>%
  select(-claim_id, -policy_id)

policy1_data <- analysis_data_4bit %>%
  filter(policy_id == "policy01_prose") %>%
  select(-claim_id, -policy_id)

policy2_data <- analysis_data_4bit %>%
  filter(policy_id == "policy02_bullets") %>%
  select(-claim_id, -policy_id)

policy3_data <- analysis_data_4bit %>%
  filter(policy_id == "policy03_decision_tree") %>%
  select(-claim_id, -policy_id)

policy4_data <- analysis_data_4bit %>%
  filter(policy_id == "policy04_bias_emphasis") %>%
  select(-claim_id, -policy_id)

policy5_data <- analysis_data_4bit %>%
  filter(policy_id == "policy05_minimal") %>%
  select(-claim_id, -policy_id)

policy6_data <- analysis_data_4bit %>%
  filter(policy_id == "policy06_verbose") %>%
  select(-claim_id, -policy_id)

# Save predictors
names(policy0_data)
predictors <- setdiff(names(policy0_data), "decision")
paste(predictors, collapse = " + ")

# Multinomial Logistic Regression
# Seperate models by policy
model_policy0 <- multinom(decision ~ ., data = policy0_data)
model_policy1 <- multinom(decision ~ ., data = policy1_data)
model_policy2 <- multinom(decision ~ ., data = policy2_data)
model_policy3 <- multinom(decision ~ ., data = policy3_data)
model_policy4 <- multinom(decision ~ ., data = policy4_data)
model_policy5 <- multinom(decision ~ ., data = policy5_data)
model_policy6 <- multinom(decision ~ ., data = policy6_data)

# Or one giant model
model <- multinom(decision ~ . - claim_id, data = analysis_data_4bit)

# Interaction Model (note: max 7 features)
model_interaction <- multinom(
  decision ~ (age + gender + severity + preexisting +
                in_network + docs_complete + claim_amount) * policy_id,
  data = analysis_data_4bit
)

# Likelihood Ratio Test
model_no_interaction <- multinom(
  decision ~ age + gender + severity + preexisting +
    in_network + docs_complete + claim_amount +
    policy_id,
  data = analysis_data_4bit
)

# ANOVA testing
anova(model_no_interaction, model_interaction, test = "Chisq")


# Stability Rate
stability_metrics <- instability_model %>%
  group_by(model) %>%
  summarise(stability_rate = mean(n_unique == 1),
            total_claims = n())
print(stability_metrics)

# Generalized Linear Models
glm_direction <- glm(I(decision == "APPROVE") ~ policy_id + severity + claim_amount, 
                     family = binomial, 
                     data = analysis_data_4bit)
summary(glm_direction)

# Odds Ratio Table
model_list <- list("4B"  = analysis_data_4bit,
                   "12B" = analysis_data_12bit,
                   "27B" = analysis_data_27bit)

all_odds_ratios <- map_df(model_list, .id = "model_size", function(df) {
  fit <- glm(I(decision == "APPROVE") ~ policy_id + severity + claim_amount, 
             family = binomial, 
             data = df)
  
  tidy(fit, conf.int = TRUE, exponentiate = TRUE) %>%
    select(term, odds_ratio = estimate, p_value = p.value, conf.low, conf.high)
})

all_odds_ratios %>%
  filter(term != "(Intercept)") %>%
  arrange(term, model_size)











