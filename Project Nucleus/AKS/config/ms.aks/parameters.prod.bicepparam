using '../../main.bicep'

param environment = 'prod'
param aksClusterName = 'aks-nucleus-prod'
param kubernetesVersion = '1.27.7'
param defaultNodePoolVmSize = 'Standard_D4s_v3'
param defaultNodePoolCount = 3
param defaultNodePoolEnableAutoScaling = true
param defaultNodePoolMinCount = 3
param defaultNodePoolMaxCount = 10
param tags = {
  Environment: 'Production'
  Project: 'Nucleus-AKS'
}
param enableMonitoring = true
param enableAzurePolicy = true
param enableRBAC = true
param enablePrivateCluster = true
param subnetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-nucleus-aks-prod/providers/Microsoft.Network/virtualNetworks/vnet-nucleus-prod/subnets/snet-aks-prod'
param networkPlugin = 'azure'
param networkPolicy = 'azure'
param enableManagedIdentity = true
param nodeGroups = [
  {
    name: 'userpool'
    vmSize: 'Standard_D8s_v3'
    count: 3
    minCount: 3
    maxCount: 10
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
    vmSize: 'Standard_D16s_v3'
    count: 2
    minCount: 2
    maxCount: 5
    enableAutoScaling: true
    mode: 'User'
    osDiskSizeGB: 512
    osType: 'Linux'
    labels: {
      workloadType: 'database'
    }
    taints: [
      'workloadType=database:NoSchedule'
    ]
  }
  {
    name: 'gpupool'
    vmSize: 'Standard_NC6s_v3'
    count: 1
    minCount: 1
    maxCount: 3
    enableAutoScaling: true
    mode: 'User'
    osDiskSizeGB: 256
    osType: 'Linux'
    labels: {
      workloadType: 'gpu'
      accelerator: 'nvidia'
    }
    taints: [
      'workloadType=gpu:NoSchedule'
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
        replicaCount: 3
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
        persistence: {
          enabled: true
          size: '10Gi'
        }
      }
      prometheus: {
        prometheusSpec: {
          retention: '15d'
          resources: {
            requests: {
              memory: '2Gi'
            }
          }
        }
      }
    }
  }
  {
    name: 'cert-manager'
    namespace: 'cert-manager'
    type: 'helm'
    repository: 'https://charts.jetstack.io'
    chart: 'cert-manager'
    version: 'v1.13.2'
    values: {
      installCRDs: true
    }
  }
]
