import json
import yaml
import shutil
from datetime import datetime

# --- Load classify.json ---
with open('classify.json', 'r') as f:
    classify_data = json.load(f)

# --- Load mask_config.yaml ---
with open('mask_config.yaml', 'r') as f:
    mask_config = yaml.safe_load(f)

# --- Backup existing mask_config.yaml ---
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
shutil.copy('mask_config.yaml', f"mask_config_backup_{timestamp}.yaml")

# --- Build a lookup of existing rules ---
existing_masked = set()
for table in mask_config.get('tables', []):
    tname = table['name']
    for col in table.get('columns', []):
        existing_masked.add((tname, col['name']))

# --- Process classify.json and add new columns if needed ---
new_columns_added = False

for classified_table in classify_data.get('tables', []):
    t_schema = classified_table.get('schema', 'dbo')
    t_name = classified_table['name']

    # Find or create matching table node
    target_table = None
    for t in mask_config['tables']:
        if t['schema'] == t_schema and t['name'] == t_name:
            target_table = t
            break
    if not target_table:
        target_table = {
            'schema': t_schema,
            'name': t_name,
            'columns': []
        }
        mask_config['tables'].append(target_table)

    for col in classified_table.get('columns', []):
        cname = col.get('name')
        ctype = col.get('type')  # Skip non‑PII
        if not ctype:
            continue
        if (t_name, cname) not in existing_masked:
            target_table['columns'].append({
                'name': cname,
                'dataset': ctype
            })
            print("Added masking rule: {t_name}.{cname} -> {ctype}")
            new_columns_added = True

# --- Write updated mask_config.yaml back with pretty indentation ---
if new_columns_added:
    with open('mask_config.yaml', 'w') as f:
        yaml.dump(
            mask_config,
            f,
            sort_keys=False,
            default_flow_style=False,
            indent=2
        )
    print("mask_config.yaml updated successfully.")
else:
    print("No new masking rules needed. Configuration already complete.")

