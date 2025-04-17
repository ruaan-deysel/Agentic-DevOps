[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$BicepPath = (Join-Path $PSScriptRoot ".." "main.bicep"),

    [Parameter(Mandatory = $false)]
    [string]$ParametersPath = (Join-Path $PSScriptRoot ".." "config" "ms.apim"),

    [Parameter(Mandatory = $false)]
    [string[]]$Environments = @('dev', 'test', 'prod')
)

# Import Pester module if available, install if not
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Pester module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester

# Check Pester version and run tests accordingly
$pesterVersion = (Get-Module -Name Pester).Version
Write-Host "Detected Pester version: $pesterVersion"

# Define the tests - these will work with any Pester version
Describe "Bicep Template Tests" {
    Context "Bicep File Validation" {
        It "Main Bicep file exists" {
            Test-Path $BicepPath | Should -Be $true
        }

        It "Main Bicep file compiles successfully" {
            $buildOutput = az bicep build --file $BicepPath 2>&1
            $LASTEXITCODE | Should -Be 0
            $buildOutput | Should -Not -Match "ERROR"
        }
    }

    Context "Parameter Files Validation" {
        foreach ($env in $Environments) {
            $paramFile = Join-Path $ParametersPath "parameters.$env.bicepparam"

            It "Parameter file for $env environment exists" {
                Test-Path $paramFile | Should -Be $true
            }

            It "Parameter file for $env environment has correct reference to main.bicep" {
                $content = Get-Content $paramFile -Raw
                $content | Should -Match "using '../../main.bicep'"
            }

            It "Parameter file for $env environment has DXC as publisher name" {
                $content = Get-Content $paramFile -Raw
                $content | Should -Match "param publisherName = 'DXC'"
            }

            It "Parameter file for $env environment has DXC email domain" {
                $content = Get-Content $paramFile -Raw
                $content | Should -Match "param publisherEmail = '.*@dxc\.com'"
            }

            It "Parameter file for $env environment has required parameters" {
                $content = Get-Content $paramFile -Raw
                $content | Should -Match "param environment = '$env'"
                $content | Should -Match "param apimServiceName = "
                $content | Should -Match "param sku = "
            }
        }
    }

    Context "Deployment Validation" {
        foreach ($env in $Environments) {
            $paramFile = Join-Path $ParametersPath "parameters.$env.bicepparam"

            It "Template validates successfully with $env parameters" {
                $validateOutput = az deployment group validate `
                    --resource-group "validation-rg" `
                    --template-file $BicepPath `
                    --parameters @$paramFile `
                    --mode Complete `
                    --what-if-exclude-change-types Ignore NoChange 2>&1

                # We expect this to fail since "validation-rg" doesn't exist, but we're just checking syntax
                # The error should be about the resource group, not the template syntax
                $validateOutput | Should -Not -Match "DeploymentFailed"
                $validateOutput | Should -Not -Match "InvalidTemplate"
            }
        }
    }

    Context "Security and Best Practices" {
        It "API Management uses a secure SKU in production" {
            $prodParamFile = Join-Path $ParametersPath "parameters.prod.bicepparam"
            $content = Get-Content $prodParamFile -Raw
            $content | Should -Match "param sku = 'Premium'"
        }

        It "API Management has diagnostic settings enabled" {
            foreach ($env in $Environments) {
                $paramFile = Join-Path $ParametersPath "parameters.$env.bicepparam"
                $content = Get-Content $paramFile -Raw
                $content | Should -Match "param enableGatewayLogs = true"
                $content | Should -Match "param enableResourceLogs = true"
            }
        }

        It "Production environment has network isolation" {
            $prodParamFile = Join-Path $ParametersPath "parameters.prod.bicepparam"
            $content = Get-Content $prodParamFile -Raw
            $content | Should -Match "param subnetResourceId = "
        }
    }
}

# Define a function to run the tests
function Invoke-BicepTests {
    param (
        [Parameter(Mandatory = $false)]
        [string]$BicepPath = (Join-Path $PSScriptRoot ".." "main.bicep"),

        [Parameter(Mandatory = $false)]
        [string]$ParametersPath = (Join-Path $PSScriptRoot ".." "config" "ms.apim"),

        [Parameter(Mandatory = $false)]
        [string[]]$Environments = @('dev', 'test', 'prod')
    )

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
    Invoke-BicepTests
}
