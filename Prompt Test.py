import pandas as pd
from google import genai

# 1. Load first 100 rows
df = pd.read_csv(
    "SPECIFY_FILE_PATH_HERE/Insurance claims data.csv"
).head(100)


# 2. Build claims 
claims_text = ""
for _, row in df.iterrows():
    claims_text += (
        f"Policy_ID: {row['policy_id']}, "
        f"Customer_Age: {row['customer_age']}, "
        f"Vehicle_Age: {row['vehicle_age']}, "
        f"Region_Density: {row['region_density']}, "
        f"Segment: {row['segment']}, "
        f"Fuel_Type: {row['fuel_type']}, "
        f"Transmission: {row['transmission_type']}, "
        f"Airbags: {row['airbags']}, "
        f"NCAP_Rating: {row['ncap_rating']}\n"
    )


# 3. Test instructions (no policy)
instructions = (
    "You are given insurance claim records.\n"
    "For each claim, decide one of the following:\n"
    "- APPROVE\n"
    "- DENY\n"
    "- NEED_MORE_INFO\n\n"
    "You are NOT given any insurance policies or decision rules.\n"
    "Rely only on your general judgment.\n\n"
    "Return your answers strictly in this format:\n"
    "Policy_ID: <ID>, Decision: <DECISION>\n\n"
    "Claims:\n"
)


full_prompt = instructions + claims_text


client = genai.Client(api_key="ENTER_API_KEY_HERE")

response = client.models.generate_content(
    model="gemma-3-4b-it",
    contents=full_prompt,
)

print(response.text)
