import streamlit as st
from google import genai

# Copy paste into terminal
##########################
## streamlit run app.py ##
##########################

# Title Page
st.title("Stat 496 Test AI")

user_input = st.text_input("Put querys here:")

# Additional Instructions
instructions = "Consider the following data:" \
               "ID, Age, Gender, Prior_Violations, Insurance" \
               "ID: 001, Age: 18, Gender: Male, Prior_Violations: Yes, Insurance: No" \
               "ID: 002, Age: 30, Gender: Female, Prior_Violations: No, Insurance: Yes" \
               "ID: 003, Age: 40, Gender: Male, Prior_Violations: No, Insurance: Yes" \
               "ID: 004, Age: 16, Gender: Male, Prior_Violations: No, Insurance: No" \
               "ID: 005, Age: 20, Gender: Female, Prior_Violations: No, Insurance: Yes" \
               "ID: 006, Age: 30, Gender: Female, Prior_Violations: Yes, Insurance: No"
full_prompt = f"{instructions}\n\nUser Question: {user_input}"

if st.button("Enter:"):
  # Replace _____ with your API key
  client = genai.Client(api_key = _____)
  response = client.models.generate_content(
        model = "gemma-3-4b-it",
        contents = full_prompt,
    )
    st.write(response.text)
