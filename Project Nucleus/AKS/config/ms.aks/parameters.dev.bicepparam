using '../../main.bicep'

param environment = 'dev'
param aksClusterName = 'aks-nucleus-dev'
param kubernetesVersion = '1.27.7'
param defaultNodePoolVmSize = 'Standard_D2s_v3'
param defaultNodePoolCount = 2
param defaultNodePoolEnableAutoScaling = true
param defaultNodePoolMinCount = 1
param defaultNodePoolMaxCount = 3
param tags = {
  Environment: 'Development'
  Project: 'Nucleus-AKS'
}
param enableMonitoring = true
param enableAzurePolicy = true
param enableRBAC = true
param enablePrivateCluster = false
param networkPlugin = 'azure'
param networkPolicy = 'azure'
param enableManagedIdentity = true
param nodeGroups = [
  {
    name: 'userpool'
    vmSize: 'Standard_D4s_v3'
    count: 1
    minCount: 1
    maxCount: 3
    enableAutoScaling: true
    mode: 'User'
    osDiskSizeGB: 128
    osType: 'Linux'
    labels: {
      workloadType: 'user-apps'
    }
    taints: []
  }
]
param workloads = [
  {
    name: 'nginx-ingress'
    namespace: 'ingress-basic'
    type: 'helm'
    repository: 'https://kubernetes.github.io/ingress-nginx'
    chart: 'ingress-nginx'
    version: '4.7.1'
    values: {
      controller: {
        replicaCount: 1
        service: {
          annotations: {
            'service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path': '/healthz'
          }
        }
      }
    }
  }
]
