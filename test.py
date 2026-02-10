import csv
from pathlib import Path
from google import genai
import time
import pandas as pd

# ---------- Files ----------
CLAIMS_CSV = Path("medical claims.csv")
PROMPT_TXT = Path("universal_prompt_medical.txt")
POLICY_DIR = Path("policies")
OUTPUT_CSV = Path("outputs/results.csv")

# ---------- Model settings ----------
MODEL = "gemma-3-4b-it"

def load_policies():
    """Load all .txt files in policies/ as (policy_id, policy_text)."""
    policies = []
    for p in sorted(POLICY_DIR.glob("*.txt")):
        policies.append((p.stem, p.read_text(encoding="utf-8").strip()))
    if not policies:
        # If you truly want 'no policies' only, we can still proceed
        policies = [("policy00_placebo", "")]
    return policies

def build_prompt(template: str, policy_text: str, row: dict) -> str:
    """Fill placeholders in universal_prompt.txt using a claim row."""
    return template.format(
        policy_text=policy_text,
        claim_id=row["claim_id"],
        patient_name=row["patient_name"],
        age=row["age"],
        gender=row["gender"],
        relationship=row["relationship"],
        diagnosis=row["diagnosis"],
        service_type=row["service_type"],
        severity=row["severity"],
        preexisting=row["preexisting"],
        in_network=row["in_network"],
        pa_required=row["pa_required"],
        pa_obtained=row["pa_obtained"],
        docs_complete=row["docs_complete"],
        itemized_bill=row["itemized_bill"],
        provider_notes=row["provider_notes"],
        claim_amount=row["claim_amount"],
    )

def main():
    # 1) Ensure output folder exists
    OUTPUT_CSV.parent.mkdir(parents=True, exist_ok=True)

    # 2) Load API key
    api_key = "your_key_here"
    if not api_key:
        raise RuntimeError(
            "GOOGLE_API_KEY is not set. In Terminal run:\n"
            "export GOOGLE_API_KEY='your_key_here'"
        )

    # 3) Load files
    template = PROMPT_TXT.read_text(encoding="utf-8")
    policies = load_policies()
    df = pd.read_csv(CLAIMS_CSV)

    # Optional: limit rows for testing
    # df = df.head(5)

    # 4) Create client
    client = genai.Client(api_key=api_key)

    # 5) Prepare CSV writer
    write_header = not OUTPUT_CSV.exists()
    with open(OUTPUT_CSV, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["claim_id", "policy_id", "model", "decision"]
        )
        if write_header:
            writer.writeheader()

        # 6) Loop over policies and claims
        for policy_id, policy_text in policies:
            for _, row in df.iterrows():
                row_dict = row.to_dict()
                prompt = build_prompt(template, policy_text, row_dict)

                # Pause for 2 seconds
                # Prevents exceeding API rate limit
                time.sleep(2)
                
                try:
                    response = client.models.generate_content(
                        model=MODEL,
                        contents=prompt
                    )

                    raw = (response.text or "").strip().upper()

                    if "APPROVE" in raw:
                        decision = "APPROVE"
                    elif "DENY" in raw:
                        decision = "DENY"
                    elif "NEED" in raw:
                        decision = "NEED_MORE_INFO"
                    else:
                        decision = "ERROR"

                except Exception as e:
                    decision = f"ERROR"

                writer.writerow({
                    "claim_id": row_dict["claim_id"],
                    "policy_id": policy_id,
                    "model": MODEL,
                    "decision": decision
                })

                print(f"Saved: {row_dict['claim_id']} × {policy_id} → {decision}")

    print(f"\nDone. Wrote outputs to: {OUTPUT_CSV}")

if __name__ == "__main__":
    main()
