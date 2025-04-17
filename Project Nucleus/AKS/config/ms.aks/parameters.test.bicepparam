using '../../main.bicep'

param environment = 'test'
param aksClusterName = 'aks-nucleus-test'
param kubernetesVersion = '1.27.7'
param defaultNodePoolVmSize = 'Standard_D2s_v3'
param defaultNodePoolCount = 3
param defaultNodePoolEnableAutoScaling = true
param defaultNodePoolMinCount = 2
param defaultNodePoolMaxCount = 5
param tags = {
  Environment: 'Test'
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
    count: 2
    minCount: 2
    maxCount: 5
    enableAutoScaling: true
    mode: 'User'
    osDiskSizeGB: 128
    osType: 'Linux'
    labels: {
      workloadType: 'user-apps'
    }
    taints: []
  }
  {
    name: 'dbpool'
    vmSize: 'Standard_D8s_v3'
    count: 1
    minCount: 1
    maxCount: 3
    enableAutoScaling: true
    mode: 'User'
    osDiskSizeGB: 256
    osType: 'Linux'
    labels: {
      workloadType: 'database'
    }
    taints: [
      'workloadType=database:NoSchedule'
    ]
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
        replicaCount: 2
        service: {
          annotations: {
            'service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path': '/healthz'
          }
        }
      }
    }
  }
  {
    name: 'prometheus'
    namespace: 'monitoring'
    type: 'helm'
    repository: 'https://prometheus-community.github.io/helm-charts'
    chart: 'kube-prometheus-stack'
    version: '51.2.0'
    values: {
      grafana: {
        enabled: true
        adminPassword: 'P@ssw0rd123!'
      }
    }
  }
]
