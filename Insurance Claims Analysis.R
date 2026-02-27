library(dplyr)
library(nnet)

# Might need to either put the datasets in the same folder as this R file,
# or put pathnames instead in the parentheses
claims <- read.csv("medical claims.csv")
results_4bit <- read.csv("results_4bit.csv")
results_12bit <- read.csv("results_12bit.csv")
results_27bit <- read.csv("results_27bit.csv")

claims <- read.csv('/Users/ichaeyun/Library/Mobile Documents/com~apple~CloudDocs/UW Courses/UW 2025-26 Courses/UW 2026 Winter/STAT 496/Project/medical claims.csv')
results_4bit <- read.csv('/Users/ichaeyun/Library/Mobile Documents/com~apple~CloudDocs/UW Courses/UW 2025-26 Courses/UW 2026 Winter/STAT 496/Project/outputs/results_4bit.csv')
results_12bit <- read.csv('/Users/ichaeyun/Library/Mobile Documents/com~apple~CloudDocs/UW Courses/UW 2025-26 Courses/UW 2026 Winter/STAT 496/Project/outputs/results_12bit.csv')
results_27bit <- read.csv('/Users/ichaeyun/Library/Mobile Documents/com~apple~CloudDocs/UW Courses/UW 2025-26 Courses/UW 2026 Winter/STAT 496/Project/outputs/results_27bit.csv')

# Merge data
results_all <- bind_rows(
  results_4bit,
  results_12bit,
  results_27bit
)

# For all modeels
full_data <- results_all %>%
  left_join(claims, by="claim_id")

analysis_data <- full_data %>%
  mutate(across(where(is.character), as.factor))

# 4B
full_data_4bit <- results_4bit %>%
  left_join(claims, by = "claim_id")

analysis_data_4bit <- full_data_4bit %>%
  select(-model) %>%
  mutate(across(where(is.character), as.factor))

# 12B
full_data_12bit <- results_12bit %>%
  left_join(claims, by = "claim_id")

analysis_data_12bit <- full_data_12bit %>%
  select(-model) %>%
  mutate(across(where(is.character), as.factor))

# 27B
full_data_27bit <- results_27bit %>%
  left_join(claims, by = "claim_id")

analysis_data_27bit <- full_data_27bit %>%
  select(-model) %>%
  mutate(across(where(is.character), as.factor))

# Inspect distributions
table(analysis_data$model, analysis_data$decision)
prop.table(table(analysis_data$model, analysis_data$decision))

# Inspect distributions per prompt per model
table(analysis_data_4bit$policy_id, analysis_data_4bit$decision)
prop.table(table(analysis_data_4bit$policy_id, analysis_data_4bit$decision))

table(analysis_data_12bit$policy_id, analysis_data_12bit$decision)
prop.table(table(analysis_data_12bit$policy_id, analysis_data_12bit$decision))

table(analysis_data_27bit$policy_id, analysis_data_27bit$decision)
prop.table(table(analysis_data_27bit$policy_id, analysis_data_27bit$decision))

# Test If Decision Distribution Depends on Policy
  # H0: Decision independent of policy format
  # H1: Decision depends on policy format
chisq.test(table(analysis_data_4bit$policy_id, analysis_data_4bit$decision))
chisq.test(table(analysis_data_12bit$policy_id, analysis_data_12bit$decision))
chisq.test(table(analysis_data_27bit$policy_id, analysis_data_27bit$decision))

# Test for Demographic Bias (Raw) (Gender version)
chisq.test(table(analysis_data_4bit$gender, analysis_data_4bit$decision))

# Logistic Regression (Adjusted Bias Test) (Gender version)
glm_no_interaction <- glm(
  I(decision == "APPROVE") ~ gender + age + severity + preexisting +
    docs_complete + claim_amount + policy_id,
  family = binomial,
  data = analysis_data_4bit
)

# If gender coefficient significant -> evidence of differential approval odds
summary(glm_no_interaction)
exp(coef(glm_no_interaction))

# Does Bias Change By Prompt? (Gender version)
glm_interaction_gender <- glm(
  I(decision == "APPROVE") ~ gender * policy_id +
    age + severity + preexisting + docs_complete + claim_amount,
  family = binomial,
  data = analysis_data_4bit
)

anova(glm_no_interaction, glm_interaction_gender, test="Chisq")

# Does Bias in Gender Change By Model?
glm_model <- glm(
  I(decision == "APPROVE") ~ gender + age + severity +
    preexisting + docs_complete + claim_amount +
    policy_id + model,
  family = binomial,
  data = analysis_data
)

glm_model_interaction <- glm(
  I(decision == "APPROVE") ~ gender * model +
    policy_id + age + severity + preexisting +
    docs_complete + claim_amount,
  family = binomial,
  data = analysis_data
)

anova(glm_model, glm_model_interaction, test="Chisq")

# Stability Analysis
  # How many different decisions did it receive?
instability_model <- analysis_data %>%
  group_by(claim_id, model) %>%
  summarise(n_unique = n_distinct(decision)) %>%
  mutate(flipped = ifelse(n_unique > 1, 1, 0))

# If high -> formatting creates instability.
instability_model %>%
  group_by(model) %>%
  summarise(flip_rate = mean(flipped))

# Which types of claims are sensitive to formatting?
instability_data <- analysis_data %>%
  left_join(claims, by="claim_id")

glm_flip <- glm(
  flipped ~ gender + severity + age + model,
  family = binomial,
  data = instability_data
)

summary(glm_flip)

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
