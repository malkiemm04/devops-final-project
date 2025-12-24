# Build script for Lambda functions (Windows PowerShell)
# This script packages each Lambda function into a zip file

$ErrorActionPreference = "Stop"

$LAMBDA_DIR = "backend\lambda"
$BUILD_DIR = "backend\lambda-build"

# Create build directory
if (Test-Path $BUILD_DIR) {
    Remove-Item -Recurse -Force $BUILD_DIR
}
New-Item -ItemType Directory -Path $BUILD_DIR -Force | Out-Null

# Install dependencies
Write-Host "Installing Lambda dependencies..." -ForegroundColor Cyan
Set-Location $LAMBDA_DIR
npm install
Set-Location ..\..

# Package each Lambda function
$lambdas = @("getNotes", "getNote", "createNote", "updateNote", "deleteNote")

foreach ($lambda in $lambdas) {
    Write-Host "Packaging $lambda..." -ForegroundColor Cyan
    
    # Create temporary directory for this Lambda
    $TEMP_DIR = Join-Path $BUILD_DIR $lambda
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
    
    # Copy Lambda function code
    Copy-Item "$LAMBDA_DIR\$lambda\index.js" "$TEMP_DIR\"
    
    # Copy node_modules (only if needed)
    if (Test-Path "$LAMBDA_DIR\node_modules") {
        Copy-Item -Recurse "$LAMBDA_DIR\node_modules" "$TEMP_DIR\"
    }
    
    # Create zip file
    Set-Location $TEMP_DIR
    Compress-Archive -Path * -DestinationPath "..\$lambda.zip" -Force
    Set-Location ..\..\..
    
    # Move zip to Lambda directory
    Move-Item "$BUILD_DIR\$lambda.zip" "$LAMBDA_DIR\$lambda\" -Force
    
    Write-Host "✓ $lambda packaged successfully" -ForegroundColor Green
}

# Cleanup
Remove-Item -Recurse -Force $BUILD_DIR

Write-Host "All Lambda functions packaged successfully!" -ForegroundColor Green

