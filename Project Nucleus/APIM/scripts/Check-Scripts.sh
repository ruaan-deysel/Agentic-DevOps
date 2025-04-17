#!/bin/bash

# Check PowerShell scripts for Contoso references
echo "Checking PowerShell scripts for Contoso references..."
echo "---------------------------------------------------"

# Find all PowerShell scripts
ps_scripts=$(find ./scripts -name "*.ps1")

for script in $ps_scripts; do
    echo "Checking $script..."
    
    # Check for Contoso references
    contoso_refs=$(grep -i "contoso" "$script" | wc -l)
    
    if [ "$contoso_refs" -gt 0 ]; then
        echo "  ❌ Found $contoso_refs references to Contoso in $script"
        grep -i "contoso" "$script"
    else
        echo "  ✅ No references to Contoso found in $script"
    fi
    
    echo ""
done

echo "Check completed!"
