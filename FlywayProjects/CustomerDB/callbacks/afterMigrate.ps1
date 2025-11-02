param (
  [string]$Server = "localhost",
  [string]$SaPassword = "Password@2025",
  [string]$RealDB = "FlywayDev"
)

Write-Host "Running afterMigrate: Updating mask config and applying masking..."

# Step 1 - Auto-update masking config using classify.json from beforeMigrate
Write-Host "Using classify.json from beforeMigrate to update mask_config.yaml..."
python auto_update_mask_config.py

if ($LASTEXITCODE -ne 0) {
  Write-Host "Failed to update masking config. Exiting..."
  exit 1
}

# Step 2 - Apply masking on the real test DB
Write-Host "Running rganonymize masking on FlywayDev..."
& "C:\Program Files\Red Gate\Test Data Manager\rganonymize.exe" mask `
  --database-engine SqlServer `
  --connection-string "Server=$Server;Database=$RealDB;User Id=sa;Password=$SaPassword;Encrypt=False" `
  --masking-file mask_config.yaml

if ($LASTEXITCODE -ne 0) {
  Write-Host "Masking failed. Please review mask_config.yaml."
  exit 1
}

Write-Host "afterMigrate completed successfully. Masking applied to real data."

