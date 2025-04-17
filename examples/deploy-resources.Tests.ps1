BeforeAll {
    # Import the script to test
    . $PSScriptRoot/deploy-resources.ps1
}

Describe "Deploy-Resources Script Tests" {
    Context "Parameter Validation" {
        It "Should have a mandatory ResourceGroupName parameter" {
            (Get-Command -Name $PSScriptRoot/deploy-resources.ps1).Parameters['ResourceGroupName'].Attributes.Mandatory | Should -Be $true
        }

        It "Should have an optional Location parameter with default value" {
            (Get-Command -Name $PSScriptRoot/deploy-resources.ps1).Parameters['Location'].Attributes.Mandatory | Should -Be $false
        }

        It "Should have an optional StorageAccountName parameter" {
            (Get-Command -Name $PSScriptRoot/deploy-resources.ps1).Parameters['StorageAccountName'].Attributes.Mandatory | Should -Be $false
        }

        It "Should have an optional TemplateFile parameter with default value" {
            (Get-Command -Name $PSScriptRoot/deploy-resources.ps1).Parameters['TemplateFile'].Attributes.Mandatory | Should -Be $false
        }
    }

    Context "Azure Connection" {
        BeforeAll {
            # Mock Azure PowerShell cmdlets
            Mock Get-AzContext { return [PSCustomObject]@{ Account = "test@example.com"; Subscription = "Test Subscription" } }
            Mock Connect-AzAccount { return $true }
        }

        It "Should check if already connected to Azure" {
            # Call the script with parameters
            & $PSScriptRoot/deploy-resources.ps1 -ResourceGroupName "test-rg" -WhatIf
            
            # Verify the mock was called
            Should -Invoke Get-AzContext -Times 1 -Exactly
        }

        It "Should not connect to Azure if already connected" {
            # Call the script with parameters
            & $PSScriptRoot/deploy-resources.ps1 -ResourceGroupName "test-rg" -WhatIf
            
            # Verify the mock was not called
            Should -Invoke Connect-AzAccount -Times 0 -Exactly
        }
    }

    Context "Resource Group Management" {
        BeforeAll {
            # Mock Azure PowerShell cmdlets
            Mock Get-AzContext { return [PSCustomObject]@{ Account = "test@example.com"; Subscription = "Test Subscription" } }
            Mock Get-AzResourceGroup { return $null }
            Mock New-AzResourceGroup { return [PSCustomObject]@{ ResourceGroupName = "test-rg"; Location = "eastus" } }
        }

        It "Should create a resource group if it doesn't exist" {
            # Call the script with parameters
            & $PSScriptRoot/deploy-resources.ps1 -ResourceGroupName "test-rg" -WhatIf
            
            # Verify the mocks were called
            Should -Invoke Get-AzResourceGroup -Times 1 -Exactly
            Should -Invoke New-AzResourceGroup -Times 1 -Exactly
        }
    }

    Context "Bicep Deployment" {
        BeforeAll {
            # Mock Azure PowerShell cmdlets
            Mock Get-AzContext { return [PSCustomObject]@{ Account = "test@example.com"; Subscription = "Test Subscription" } }
            Mock Get-AzResourceGroup { return [PSCustomObject]@{ ResourceGroupName = "test-rg"; Location = "eastus" } }
            Mock New-AzResourceGroupDeployment { 
                return [PSCustomObject]@{ 
                    ProvisioningState = "Succeeded"
                    Outputs = @{
                        storageAccountName = @{ Value = "teststorage" }
                        storageAccountId = @{ Value = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/teststorage" }
                    }
                } 
            }
        }

        It "Should deploy the Bicep template" {
            # Call the script with parameters
            & $PSScriptRoot/deploy-resources.ps1 -ResourceGroupName "test-rg" -StorageAccountName "teststorage" -WhatIf
            
            # Verify the mock was called
            Should -Invoke New-AzResourceGroupDeployment -Times 1 -Exactly
        }
    }
}
