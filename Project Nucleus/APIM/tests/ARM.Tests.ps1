[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$BicepPath = (Join-Path $PSScriptRoot ".." "main.bicep"),

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path $PSScriptRoot ".." "artifacts" "main.json")
)

# Import Pester module if available, install if not
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Pester module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester

# Check Pester version
$pesterVersion = (Get-Module -Name Pester).Version
Write-Host "Detected Pester version: $pesterVersion"

# Create artifacts directory if it doesn't exist
$artifactsDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $artifactsDir)) {
    New-Item -Path $artifactsDir -ItemType Directory -Force | Out-Null
}

# Compile Bicep to ARM template
Write-Host "Compiling Bicep to ARM template..." -ForegroundColor Yellow
az bicep build --file $BicepPath --outfile $OutputPath

Describe "ARM Template Tests" {
    Context "ARM Template Validation" {
        It "ARM template file exists" {
            Test-Path $OutputPath | Should -Be $true
        }

        It "ARM template is valid JSON" {
            { Get-Content $OutputPath -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        $armTemplate = Get-Content $OutputPath -Raw | ConvertFrom-Json

        It "ARM template has required schema" {
            $armTemplate.'$schema' | Should -Match "deploymentTemplate.json"
        }

        It "ARM template has content version" {
            $armTemplate.contentVersion | Should -Not -BeNullOrEmpty
        }

        It "ARM template has parameters section" {
            $armTemplate.parameters | Should -Not -BeNullOrEmpty
        }

        It "ARM template has resources section" {
            $armTemplate.resources | Should -Not -BeNullOrEmpty
        }

        It "ARM template has outputs section" {
            $armTemplate.outputs | Should -Not -BeNullOrEmpty
        }
    }

    Context "ARM Template Parameters" {
        $armTemplate = Get-Content $OutputPath -Raw | ConvertFrom-Json

        $requiredParameters = @(
            'location',
            'environment',
            'apimServiceName',
            'sku',
            'publisherEmail',
            'publisherName'
        )

        foreach ($param in $requiredParameters) {
            It "ARM template has parameter: $param" {
                $armTemplate.parameters.PSObject.Properties.Name | Should -Contain $param
            }
        }

        It "Publisher name default is DXC" {
            $armTemplate.parameters.publisherName.defaultValue | Should -Be "DXC"
        }

        It "Publisher email default has DXC domain" {
            $armTemplate.parameters.publisherEmail.defaultValue | Should -Match "@dxc\.com$"
        }
    }

    Context "ARM Template Resources" {
        $armTemplate = Get-Content $OutputPath -Raw | ConvertFrom-Json

        It "ARM template has API Management resource" {
            $armTemplate.resources | Where-Object { $_.type -eq "Microsoft.Resources/deployments" -and $_.name -match "apim-" } | Should -Not -BeNullOrEmpty
        }

        It "ARM template uses system-assigned managed identity" {
            $deployments = $armTemplate.resources | Where-Object { $_.type -eq "Microsoft.Resources/deployments" -and $_.name -match "apim-" }
            $deployments | Should -Not -BeNullOrEmpty

            # Extract the nested template
            $nestedTemplate = $deployments[0].properties.template

            # Look for the API Management resource
            $apimResources = $nestedTemplate.resources | Where-Object { $_.type -eq "Microsoft.ApiManagement/service" }
            $apimResources | Should -Not -BeNullOrEmpty

            # Check for identity property
            $apimResources[0].identity.type | Should -Be "SystemAssigned"
        }
    }

    Context "Security and Best Practices" {
        $armTemplate = Get-Content $OutputPath -Raw | ConvertFrom-Json

        It "ARM template has diagnostic settings" {
            $deployments = $armTemplate.resources | Where-Object { $_.type -eq "Microsoft.Resources/deployments" -and $_.name -match "diagnostics" }
            $deployments | Should -Not -BeNullOrEmpty
        }

        It "ARM template supports secure SKUs" {
            # Get parameter definitions
            $skuParameter = $armTemplate.parameters.sku
            $skuParameter | Should -Not -BeNullOrEmpty

            # Check that allowed values include Premium
            if ($skuParameter.allowedValues) {
                $skuParameter.allowedValues | Should -Contain "Premium"
            }
        }
    }
}

# Define a function to run the tests
function Invoke-ARMTests {
    param (
        [Parameter(Mandatory = $false)]
        [string]$BicepPath = (Join-Path $PSScriptRoot ".." "main.bicep"),

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Join-Path $PSScriptRoot ".." "artifacts" "main.json")
    )

    # Create artifacts directory if it doesn't exist
    $artifactsDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $artifactsDir)) {
        New-Item -Path $artifactsDir -ItemType Directory -Force | Out-Null
    }

    # Compile Bicep to ARM template
    Write-Host "Compiling Bicep to ARM template..." -ForegroundColor Yellow
    az bicep build --file $BicepPath --outfile $OutputPath

    # Run the tests based on Pester version
    if ($pesterVersion.Major -lt 5) {
        # For Pester 3.x, just run Invoke-Pester without a configuration
        Invoke-Pester
    } else {
        # For Pester 5.x, use the configuration object
        $config = New-PesterConfiguration
        $config.Run.Path = $PSScriptRoot
        $config.Output.Verbosity = 'Detailed'
        $config.Run.PassThru = $true
        Invoke-Pester -Configuration $config
    }
}

# Only run tests if script is invoked directly (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-ARMTests
}
