import yaml, json, sys

# Load masking rules from mask_config.yaml
with open('mask_config.yaml') as f:
    config = yaml.safe_load(f)
    mask_rules = set()
    for table in config.get('tables', []):
        tname = table['name']
        for col in table.get('columns', []):
            mask_rules.add((tname, col['name']))

# Load classified PII columns from classify.json
with open('classify.json') as f:
    data = json.load(f)
    pii_columns = set()
    for table in data.get('tables', []):
        tname = table['name']
        for col in table.get('columns', []):
            if col.get('type'):
                pii_columns.add((tname, col['name']))

# Compare sets
missing = pii_columns - mask_rules

# Print results
if missing:
    print("Missing masking rules for these PII columns:")
    for t, c in sorted(missing):
        print(f"  - {t}.{c}")
    sys.exit(1)
else:
    print("All PII columns are covered by masking rules.")

