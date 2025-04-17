[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $true)]
    [string]$ApimServiceName,
    
    [Parameter(Mandatory = $false)]
    [string]$LogAnalyticsWorkspaceName,
    
    [Parameter(Mandatory = $false)]
    [string]$ActionGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$ActionGroupEmails,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "./logs",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Set up error handling
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# Create log directory if it doesn't exist
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
    Write-Verbose "Created log directory: $LogPath"
}

# Set up logging
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $LogPath "apim-monitoring-$timestamp.log"
Start-Transcript -Path $logFile -Append

Write-Host "Starting API Management monitoring configuration" -ForegroundColor Cyan
Write-Host "API Management: $ApimServiceName" -ForegroundColor Cyan

try {
    # Check if API Management exists
    Write-Host "Checking API Management service..." -ForegroundColor Yellow
    $apim = az apim show --name $ApimServiceName --resource-group $ResourceGroup 2>$null
    
    if (-not $apim) {
        Write-Error "API Management service $ApimServiceName not found in resource group $ResourceGroup"
        exit 1
    }
    
    # Get API Management resource ID
    $apimId = az apim show --name $ApimServiceName --resource-group $ResourceGroup --query "id" -o tsv
    
    # Create or get Log Analytics workspace
    if ($LogAnalyticsWorkspaceName) {
        Write-Host "Checking Log Analytics workspace..." -ForegroundColor Yellow
        $workspace = az monitor log-analytics workspace show --resource-group $ResourceGroup --workspace-name $LogAnalyticsWorkspaceName 2>$null
        
        if (-not $workspace) {
            Write-Host "Creating Log Analytics workspace: $LogAnalyticsWorkspaceName..." -ForegroundColor Yellow
            $workspace = az monitor log-analytics workspace create --resource-group $ResourceGroup --workspace-name $LogAnalyticsWorkspaceName
            
            if (-not $workspace) {
                Write-Error "Failed to create Log Analytics workspace"
                exit 1
            }
        }
        
        # Get workspace ID
        $workspaceId = az monitor log-analytics workspace show --resource-group $ResourceGroup --workspace-name $LogAnalyticsWorkspaceName --query "id" -o tsv
        
        # Configure diagnostic settings
        Write-Host "Configuring diagnostic settings..." -ForegroundColor Yellow
        $diagResult = az monitor diagnostic-settings create --resource $apimId --name "apim-diagnostics" --workspace $workspaceId --logs '[{"category":"GatewayLogs","enabled":true},{"category":"WebSocketConnectionLogs","enabled":true}]' --metrics '[{"category":"AllMetrics","enabled":true}]'
        
        if ($diagResult) {
            Write-Host "Diagnostic settings configured successfully" -ForegroundColor Green
        } else {
            Write-Error "Failed to configure diagnostic settings"
        }
    }
    
    # Create action group for alerts
    if ($ActionGroupName -and $ActionGroupEmails) {
        Write-Host "Creating action group: $ActionGroupName..." -ForegroundColor Yellow
        
        # Parse email addresses
        $emails = $ActionGroupEmails -split ','
        $emailActions = @()
        
        for ($i = 0; $i -lt $emails.Count; $i++) {
            $emailActions += "--action email$i $emails[$i] $emails[$i]"
        }
        
        $actionGroupResult = az monitor action-group create --resource-group $ResourceGroup --name $ActionGroupName --short-name "APIM" $emailActions
        
        if ($actionGroupResult) {
            Write-Host "Action group created successfully" -ForegroundColor Green
            
            # Get action group ID
            $actionGroupId = az monitor action-group show --resource-group $ResourceGroup --name $ActionGroupName --query "id" -o tsv
            
            # Create alerts
            Write-Host "Creating alerts..." -ForegroundColor Yellow
            
            # 1. Capacity alert
            Write-Host "Creating capacity alert..." -ForegroundColor Yellow
            $capacityAlertResult = az monitor metrics alert create --name "APIM-HighCapacity" --resource-group $ResourceGroup --scopes $apimId --condition "avg Capacity > 80" --window-size 5m --evaluation-frequency 1m --action $actionGroupId --description "Alert when API Management capacity exceeds 80%"
            
            if ($capacityAlertResult) {
                Write-Host "Capacity alert created successfully" -ForegroundColor Green
            } else {
                Write-Error "Failed to create capacity alert"
            }
            
            # 2. Failed requests alert
            Write-Host "Creating failed requests alert..." -ForegroundColor Yellow
            $failedRequestsAlertResult = az monitor metrics alert create --name "APIM-FailedRequests" --resource-group $ResourceGroup --scopes $apimId --condition "count FailedRequests > 10" --window-size 5m --evaluation-frequency 1m --action $actionGroupId --description "Alert when API Management has more than 10 failed requests in 5 minutes"
            
            if ($failedRequestsAlertResult) {
                Write-Host "Failed requests alert created successfully" -ForegroundColor Green
            } else {
                Write-Error "Failed to create failed requests alert"
            }
            
            # 3. Duration alert
            Write-Host "Creating duration alert..." -ForegroundColor Yellow
            $durationAlertResult = az monitor metrics alert create --name "APIM-HighDuration" --resource-group $ResourceGroup --scopes $apimId --condition "avg Duration > 1000" --window-size 5m --evaluation-frequency 1m --action $actionGroupId --description "Alert when API Management average request duration exceeds 1000ms"
            
            if ($durationAlertResult) {
                Write-Host "Duration alert created successfully" -ForegroundColor Green
            } else {
                Write-Error "Failed to create duration alert"
            }
        } else {
            Write-Error "Failed to create action group"
        }
    }
    
    # Create custom dashboard
    Write-Host "Creating custom dashboard..." -ForegroundColor Yellow
    
    $dashboardName = "APIM-Dashboard-$ApimServiceName"
    $dashboardDisplayName = "API Management Dashboard - $ApimServiceName"
    
    $dashboardJson = @"
{
    "properties": {
        "lenses": {
            "0": {
                "order": 0,
                "parts": {
                    "0": {
                        "position": {
                            "x": 0,
                            "y": 0,
                            "colSpan": 6,
                            "rowSpan": 4
                        },
                        "metadata": {
                            "inputs": [
                                {
                                    "name": "resourceTypeMode",
                                    "isOptional": true,
                                    "value": "workspace"
                                },
                                {
                                    "name": "ComponentId",
                                    "isOptional": true,
                                    "value": {
                                        "SubscriptionId": "$(az account show --query id -o tsv)",
                                        "ResourceGroup": "$ResourceGroup",
                                        "Name": "$LogAnalyticsWorkspaceName",
                                        "ResourceId": "$workspaceId"
                                    }
                                },
                                {
                                    "name": "Query",
                                    "isOptional": true,
                                    "value": "AzureDiagnostics\n| where ResourceProvider == \"MICROSOFT.APIMANAGEMENT\"\n| where Category == \"GatewayLogs\"\n| summarize count() by ResultCode, bin(TimeGenerated, 1h)\n| render columnchart"
                                },
                                {
                                    "name": "TimeRange",
                                    "isOptional": true,
                                    "value": "P1D"
                                },
                                {
                                    "name": "Dimensions",
                                    "isOptional": true,
                                    "value": {
                                        "xAxis": {
                                            "name": "TimeGenerated",
                                            "type": "datetime"
                                        },
                                        "yAxis": [
                                            {
                                                "name": "count_",
                                                "type": "long"
                                            }
                                        ],
                                        "splitBy": [
                                            {
                                                "name": "ResultCode",
                                                "type": "string"
                                            }
                                        ],
                                        "aggregation": "Sum"
                                    }
                                },
                                {
                                    "name": "Version",
                                    "isOptional": true,
                                    "value": "1.0"
                                },
                                {
                                    "name": "DashboardId",
                                    "isOptional": true,
                                    "value": "$dashboardName"
                                },
                                {
                                    "name": "PartId",
                                    "isOptional": true,
                                    "value": "part-0"
                                },
                                {
                                    "name": "PartTitle",
                                    "isOptional": true,
                                    "value": "API Requests by Status Code"
                                },
                                {
                                    "name": "PartSubTitle",
                                    "isOptional": true,
                                    "value": "$ApimServiceName"
                                },
                                {
                                    "name": "resourceTypeMode",
                                    "isOptional": true,
                                    "value": "workspace"
                                }
                            ],
                            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
                            "settings": {}
                        }
                    },
                    "1": {
                        "position": {
                            "x": 6,
                            "y": 0,
                            "colSpan": 6,
                            "rowSpan": 4
                        },
                        "metadata": {
                            "inputs": [
                                {
                                    "name": "options",
                                    "isOptional": true,
                                    "value": {
                                        "chart": {
                                            "metrics": [
                                                {
                                                    "resourceMetadata": {
                                                        "id": "$apimId"
                                                    },
                                                    "name": "TotalRequests",
                                                    "aggregationType": 1,
                                                    "namespace": "microsoft.apimanagement/service",
                                                    "metricVisualization": {
                                                        "displayName": "Total Gateway Requests"
                                                    }
                                                },
                                                {
                                                    "resourceMetadata": {
                                                        "id": "$apimId"
                                                    },
                                                    "name": "SuccessfulRequests",
                                                    "aggregationType": 1,
                                                    "namespace": "microsoft.apimanagement/service",
                                                    "metricVisualization": {
                                                        "displayName": "Successful Gateway Requests"
                                                    }
                                                },
                                                {
                                                    "resourceMetadata": {
                                                        "id": "$apimId"
                                                    },
                                                    "name": "FailedRequests",
                                                    "aggregationType": 1,
                                                    "namespace": "microsoft.apimanagement/service",
                                                    "metricVisualization": {
                                                        "displayName": "Failed Gateway Requests"
                                                    }
                                                }
                                            ],
                                            "title": "Gateway Requests",
                                            "timespan": {
                                                "relative": {
                                                    "duration": 86400000
                                                },
                                                "showUTCTime": false,
                                                "grain": 1
                                            }
                                        }
                                    }
                                },
                                {
                                    "name": "sharedTimeRange",
                                    "isOptional": true,
                                    "value": {
                                        "relative": {
                                            "duration": 86400000
                                        },
                                        "showUTCTime": false,
                                        "grain": 1
                                    }
                                }
                            ],
                            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
                            "settings": {}
                        }
                    },
                    "2": {
                        "position": {
                            "x": 0,
                            "y": 4,
                            "colSpan": 6,
                            "rowSpan": 4
                        },
                        "metadata": {
                            "inputs": [
                                {
                                    "name": "options",
                                    "isOptional": true,
                                    "value": {
                                        "chart": {
                                            "metrics": [
                                                {
                                                    "resourceMetadata": {
                                                        "id": "$apimId"
                                                    },
                                                    "name": "Duration",
                                                    "aggregationType": 4,
                                                    "namespace": "microsoft.apimanagement/service",
                                                    "metricVisualization": {
                                                        "displayName": "Gateway Request Duration"
                                                    }
                                                }
                                            ],
                                            "title": "Average Gateway Request Duration",
                                            "timespan": {
                                                "relative": {
                                                    "duration": 86400000
                                                },
                                                "showUTCTime": false,
                                                "grain": 1
                                            }
                                        }
                                    }
                                },
                                {
                                    "name": "sharedTimeRange",
                                    "isOptional": true,
                                    "value": {
                                        "relative": {
                                            "duration": 86400000
                                        },
                                        "showUTCTime": false,
                                        "grain": 1
                                    }
                                }
                            ],
                            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
                            "settings": {}
                        }
                    },
                    "3": {
                        "position": {
                            "x": 6,
                            "y": 4,
                            "colSpan": 6,
                            "rowSpan": 4
                        },
                        "metadata": {
                            "inputs": [
                                {
                                    "name": "options",
                                    "isOptional": true,
                                    "value": {
                                        "chart": {
                                            "metrics": [
                                                {
                                                    "resourceMetadata": {
                                                        "id": "$apimId"
                                                    },
                                                    "name": "Capacity",
                                                    "aggregationType": 4,
                                                    "namespace": "microsoft.apimanagement/service",
                                                    "metricVisualization": {
                                                        "displayName": "Capacity"
                                                    }
                                                }
                                            ],
                                            "title": "Average Capacity",
                                            "timespan": {
                                                "relative": {
                                                    "duration": 86400000
                                                },
                                                "showUTCTime": false,
                                                "grain": 1
                                            }
                                        }
                                    }
                                },
                                {
                                    "name": "sharedTimeRange",
                                    "isOptional": true,
                                    "value": {
                                        "relative": {
                                            "duration": 86400000
                                        },
                                        "showUTCTime": false,
                                        "grain": 1
                                    }
                                }
                            ],
                            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
                            "settings": {}
                        }
                    }
                }
            }
        },
        "metadata": {
            "model": {
                "timeRange": {
                    "value": {
                        "relative": {
                            "duration": 24,
                            "timeUnit": 1
                        }
                    },
                    "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
                }
            }
        }
    },
    "name": "$dashboardName",
    "type": "Microsoft.Portal/dashboards",
    "location": "$(az account show --query 'location' -o tsv)",
    "tags": {
        "hidden-title": "$dashboardDisplayName"
    }
}
"@
    
    # Save dashboard to temporary file
    $dashboardFile = Join-Path $env:TEMP "apim-dashboard.json"
    $dashboardJson | Out-File -FilePath $dashboardFile -Encoding utf8
    
    # Create dashboard
    $dashboardResult = az deployment group create --resource-group $ResourceGroup --template-file $dashboardFile
    
    if ($dashboardResult) {
        Write-Host "Dashboard created successfully" -ForegroundColor Green
    } else {
        Write-Warning "Failed to create dashboard"
    }
    
    # Remove temporary file
    Remove-Item -Path $dashboardFile -Force
    
    Write-Host "API Management monitoring configuration completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "API Management monitoring configuration failed: $_"
    exit 1
}
finally {
    # Stop transcript logging
    Stop-Transcript
}
