#!/bin/bash

# Build script for Lambda functions
# This script packages each Lambda function into a zip file

set -e

LAMBDA_DIR="backend/lambda"
BUILD_DIR="backend/lambda-build"

# Create build directory
mkdir -p "$BUILD_DIR"

# Install dependencies
echo "Installing Lambda dependencies..."
cd "$LAMBDA_DIR"
npm install
cd ../..

# Package each Lambda function
for lambda in getNotes getNote createNote updateNote deleteNote; do
    echo "Packaging $lambda..."
    
    # Create temporary directory for this Lambda
    TEMP_DIR="$BUILD_DIR/$lambda"
    mkdir -p "$TEMP_DIR"
    
    # Copy Lambda function code
    cp "$LAMBDA_DIR/$lambda/index.js" "$TEMP_DIR/"
    
    # Copy node_modules (only if needed)
    if [ -d "$LAMBDA_DIR/node_modules" ]; then
        cp -r "$LAMBDA_DIR/node_modules" "$TEMP_DIR/"
    fi
    
    # Create zip file
    cd "$TEMP_DIR"
    zip -r "../$lambda.zip" .
    cd ../../..
    
    # Move zip to Lambda directory
    mv "$BUILD_DIR/$lambda.zip" "$LAMBDA_DIR/$lambda/"
    
    echo "✓ $lambda packaged successfully"
done

# Cleanup
rm -rf "$BUILD_DIR"

echo "All Lambda functions packaged successfully!"

