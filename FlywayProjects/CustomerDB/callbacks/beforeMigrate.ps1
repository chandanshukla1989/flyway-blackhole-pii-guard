param (
  [string]$Server = "localhost",
  [string]$SaPassword = "Password@2025",
  [string]$ScratchDB = "FlywayScratch",
  [string]$FailOnDrift = "false"  # "true" to fail, "false" to allow and fix in afterMigrate
)

Write-Host "Running beforeMigrate: Masking validation pipeline started..."

# Step 1 – Apply migration to Scratch DB
#flyway -url="jdbc:sqlserver://$Server;databaseName=$ScratchDB;encrypt=false" `
#  -user=sa `
#  -password=$SaPassword `
#  -locations=filesystem:migrations `
#  migrate


#flyway -url="jdbc:sqlserver://localhost;databaseName=FlywayScratch;encrypt=false" -user=sa -password=Password@2025 -locations=filesystem:migrations migrate
# Comment callback line
(Get-Content flyway.conf) -replace '^(flyway\.callbackLocations=)', '# $1' | Set-Content flyway.conf

# Run Flyway migrate for scratch
flyway -url="jdbc:sqlserver://localhost;databaseName=FlywayScratch;encrypt=false" `
  -user=sa `
  -password=Password@2025 `
  -locations=filesystem:migrations `
  migrate

# Uncomment callback line
(Get-Content flyway.conf) -replace '^# (flyway\.callbackLocations=)', '$1' | Set-Content flyway.conf


# Step 2 – Run Redgate classification
& "C:\Program Files\Red Gate\Test Data Manager\rganonymize.exe" classify `
  --database-engine SqlServer `
  --connection-string "Server=$Server;Database=$ScratchDB;User Id=sa;Password=$SaPassword;Encrypt=False" `
  --classification-file classify.json `
  --output Json `
  --output-all-columns

# Step 3 – Run masking validation
python check_masking_rules.py

if ($LASTEXITCODE -ne 0) {
  Write-Host "Masking drift detected -- some PII columns are not covered."
  if ($FailOnDrift -eq "true") {
    Write-Host "Aborting migration due to unapproved masking drift."
    exit 1
  }
  else {
    Write-Host "Proceeding with migration (drift will be handled in afterMigrate)."
  }
} else {
  Write-Host "All masking rules validated successfully."
}

