library(dplyr)
library(nnet)

# Might need to either put the datasets in the same folder as this R file,
# or put pathnames instead in the parentheses
claims <- read.csv("medical claims.csv")
results <- read.csv("results.csv")

# Merge data
full_data <- results %>%
  left_join(claims, by = "claim_id")

analysis_data <- full_data %>%
  select(-model) %>%
  mutate(
    decision = factor(decision),
    policy_id = factor(policy_id),
    gender = factor(gender),
    relationship = factor(relationship),
    diagnosis = factor(diagnosis),
    service_type = factor(service_type),
    severity = factor(severity),
    preexisting = factor(preexisting),
    in_network = factor(in_network),
    pa_required = factor(pa_required),
    pa_obtained = factor(pa_obtained),
    docs_complete = factor(docs_complete),
    itemized_bill = factor(itemized_bill),
    provider_notes = factor(provider_notes)
  )

# Inspect distributions
table(analysis_data$decision)
prop.table(table(analysis_data$decision))

table(analysis_data$policy_id, analysis_data$decision)

# Dataset per policy
policy0_data <- analysis_data %>%
  filter(policy_id == "policy00_placebo") %>%
  select(-claim_id, -policy_id)

policy1_data <- analysis_data %>%
  filter(policy_id == "policy01_prose") %>%
  select(-claim_id, -policy_id)

policy2_data <- analysis_data %>%
  filter(policy_id == "policy02_bullets") %>%
  select(-claim_id, -policy_id)

policy3_data <- analysis_data %>%
  filter(policy_id == "policy03_decision_tree") %>%
  select(-claim_id, -policy_id)

policy4_data <- analysis_data %>%
  filter(policy_id == "policy04_bias_emphasis") %>%
  select(-claim_id, -policy_id)

policy5_data <- analysis_data %>%
  filter(policy_id == "policy05_minimal") %>%
  select(-claim_id, -policy_id)

policy6_data <- analysis_data %>%
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
model <- multinom(decision ~ . - claim_id, data = analysis_data)

# Interaction Model (note: max 7 features)
model_interaction <- multinom(
  decision ~ (age + gender + severity + preexisting +
                in_network + docs_complete + claim_amount) * policy_id,
  data = analysis_data
)

# Likelihood Ratio Test
model_no_interaction <- multinom(
  decision ~ age + gender + severity + preexisting +
    in_network + docs_complete + claim_amount +
    policy_id,
  data = analysis_data
)

anova(model_no_interaction, model_interaction, test = "Chisq")

# Quantify Fairness (Adjusted, Not Raw)
glm_gender <- glm(
  I(decision == "APPROVE") ~ gender + age + severity +
    preexisting + docs_complete + policy_id,
  family = binomial,
  data = analysis_data
)

summary(glm_gender)
exp(coef(glm_gender))

# Stability / Sensitivity Analysis - How many different decisions did it receive?
instability <- full_data %>%
  group_by(claim_id) %>%
  summarise(n_unique = n_distinct(decision))

instability <- instability %>%
  mutate(flipped = ifelse(n_unique > 1, 1, 0))

instability_data <- instability %>%
  left_join(claims, by = "claim_id")

# Which claims are most sensitive to formatting?
glm_instability <- glm(
  flipped ~ age + severity + preexisting + claim_amount,
  family = binomial,
  data = instability_data
)

# Fairness/Disparity Metrics
approval_gender <- full_data %>%
  group_by(policy_id, gender) %>%
  summarise(approval_rate = mean(decision == "APPROVE"))
