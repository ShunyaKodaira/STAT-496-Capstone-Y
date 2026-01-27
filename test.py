from google import genai

client = genai.Client(api_key="YOUR_API_KEY")

response = client.models.generate_content(
    model="gemma-3-4b-it",
    contents="Roses are red...",
)

print(response.text)