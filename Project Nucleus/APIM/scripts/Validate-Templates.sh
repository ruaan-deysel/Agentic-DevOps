#!/bin/bash

# Simple validation script for Bicep templates and parameter files
# This script doesn't require PowerShell or Azure CLI

echo "Starting template validation..."
echo "-------------------------------"

# Check if main.bicep exists
if [ -f "main.bicep" ]; then
    echo "✅ main.bicep file exists"
else
    echo "❌ main.bicep file not found"
    exit 1
fi

# Check parameter files
for env in dev test prod; do
    param_file="config/ms.apim/parameters.$env.bicepparam"
    if [ -f "$param_file" ]; then
        echo "✅ $param_file exists"
        
        # Check if the parameter file references the correct main.bicep path
        if grep -q "using '../../main.bicep'" "$param_file"; then
            echo "  ✅ $param_file has correct reference to main.bicep"
        else
            echo "  ❌ $param_file has incorrect reference to main.bicep"
        fi
        
        # Check if the parameter file has DXC as publisher name
        if grep -q "param publisherName = 'DXC'" "$param_file"; then
            echo "  ✅ $param_file has DXC as publisher name"
        else
            echo "  ❌ $param_file has incorrect publisher name"
        fi
        
        # Check if the parameter file has DXC email domain
        if grep -q "param publisherEmail = '.*@dxc.com'" "$param_file"; then
            echo "  ✅ $param_file has DXC email domain"
        else
            echo "  ❌ $param_file has incorrect email domain"
        fi
        
        # Check if the parameter file has required parameters
        if grep -q "param environment = '$env'" "$param_file"; then
            echo "  ✅ $param_file has correct environment parameter"
        else
            echo "  ❌ $param_file has incorrect environment parameter"
        fi
        
        if grep -q "param apimServiceName = " "$param_file"; then
            echo "  ✅ $param_file has apimServiceName parameter"
        else
            echo "  ❌ $param_file is missing apimServiceName parameter"
        fi
        
        if grep -q "param sku = " "$param_file"; then
            echo "  ✅ $param_file has sku parameter"
        else
            echo "  ❌ $param_file is missing sku parameter"
        fi
        
        # Check if prod environment has Premium SKU
        if [ "$env" == "prod" ]; then
            if grep -q "param sku = 'Premium'" "$param_file"; then
                echo "  ✅ Production environment uses Premium SKU"
            else
                echo "  ❌ Production environment does not use Premium SKU"
            fi
            
            # Check if prod environment has subnet resource ID
            if grep -q "param subnetResourceId = " "$param_file"; then
                echo "  ✅ Production environment has subnet resource ID"
            else
                echo "  ❌ Production environment is missing subnet resource ID"
            fi
        fi
        
        # Check if diagnostic settings are enabled
        if grep -q "param enableGatewayLogs = true" "$param_file"; then
            echo "  ✅ $param_file has gateway logs enabled"
        else
            echo "  ❌ $param_file does not have gateway logs enabled"
        fi
        
        if grep -q "param enableResourceLogs = true" "$param_file"; then
            echo "  ✅ $param_file has resource logs enabled"
        else
            echo "  ❌ $param_file does not have resource logs enabled"
        fi
        
    else
        echo "❌ $param_file not found"
    fi
    
    echo ""
done

# Check main.bicep for DXC references
if grep -q "param publisherName string = 'DXC'" "main.bicep"; then
    echo "✅ main.bicep has DXC as default publisher name"
else
    echo "❌ main.bicep has incorrect default publisher name"
fi

if grep -q "param publisherEmail string = '.*@dxc.com'" "main.bicep"; then
    echo "✅ main.bicep has DXC email domain as default"
else
    echo "❌ main.bicep has incorrect default email domain"
fi

echo ""
echo "Validation completed!"
