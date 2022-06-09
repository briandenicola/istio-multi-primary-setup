# Introduction 

This repo is to automate the setup of a Multi-primary Istio Mesh of two AKS clusters

_The code in this repo is non-funcational at the moment. Fails when starting pod with istio injected:_
```
Error: Failed to parse and verify signed certificate chain from issuer
Details:
  Failed to verify the issued certificate chain against the current mesh roots: x509:\
  Certificate has expired or is not yet valid: current time 2022-06-09T01:15:13Z is before 2022-06-09T01:15:17Z
Identities: spiffe://cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account
```

## Backlog Status
- [x] Cluster Creation 
- [x] Cluster Addons 
- [x] Certificate Issuer Configuration
- [x] Istio CSR Configuration
- [x] Istio Configuration
- [ ] Istio Validation 
- [x] Istio Remote Secret Configuration 
- [ ] End to end Validation

# Prerequisites
1. Azure Subscription
1. Terraform 
1. kubectl
1. istioctl
1. [Hashicorp Vault](./Vault.md)
1. [Environmental Setup](./Environment.md)
1. Certificate Authority 

# Cluster Setup
## Deploy South Central Cluster
```bash
export ARM_USE_MSI=true 
export ARM_TENANT_ID=${AAD_TENANT_GUID}
export ARM_SUBSCRIPTION_ID=${AAD_SUBSCRIPTION_GUID}
export CORE_SUBSCRIPTION_ID=${AAD_CORE_SUBSCRIPTION_GUID}
export CLUSTER_RG=DevSub02_K8S_a212scus_RG
export CLUSTER_NAME=a212scus
export GITHUB_ACCOUNT=${YOUR GITHUB REPO}
export GITHUB_REPO=istio-multi-primary-setup
export GITHUB_TOKEN=${CREATE PAT TOKEN IN YOUR GITHUB REPO}

az login --identity 
az account set -s ${ARM_SUBSCRIPTION_ID}

cd ./infrastructure
terraform init -backend=true \
  -backend-config="tenant_id=${ARM_TENANT_ID}" \
  -backend-config="subscription_id=${CORE_SUBSCRIPTION_ID}" \
  -backend-config="key=${CLUSTER_NAME}.terraform.tfstate"
terraform plan -out="${CLUSTER_NAME}.plan" \
  -var "cluster_name=${CLUSTER_NAME}" \
  -var "resource_group_name=${CLUSTER_RG}" \
  -var-file="istio-southcentral.tfvars"
terraform apply -auto-approve ${CLUSTER_NAME}.plan
```

## Apply Kustomize to cluster - South Central
```bash
cd cluster-manifests

az aks get-credentials -g ${CLUSTER_RG} -n ${CLUSTER_NAME} --overwrite-existing
kubelogin convert-kubeconfig -l msi
flux bootstrap github --owner=${GITHUB_ACCOUNT} --repository=${GITHUB_REPO} --path=./cluster-manifests/central --branch=main  --personal=true --private=false
```

## Deploy Central Cluster
```bash
export ARM_USE_MSI=true 
export ARM_TENANT_ID=${AAD_TENANT_GUID}
export ARM_SUBSCRIPTION_ID=${AAD_SUBSCRIPTION_GUID}
export CORE_SUBSCRIPTION_ID=${AAD_CORE_SUBSCRIPTION_GUID}
export CLUSTER_RG=DevSub02_K8S_g6258cus_RG
export CLUSTER_NAME=g6258cus
export GITHUB_ACCOUNT=${YOUR GITHUB REPO}
export GITHUB_REPO=istio-multi-primary-setup
export GITHUB_TOKEN=${CREATE PAT TOKEN IN YOUR GITHUB REPO}

az login --identity 

cd ./infrastructure
terraform init -backend=true \
  -backend-config="tenant_id=${ARM_TENANT_ID}" \
  -backend-config="subscription_id=${CORE_SUBSCRIPTION_ID}" \
  -backend-config="key=${CLUSTER_NAME}.terraform.tfstate" \
  -reconfigure
terraform plan -out="${CLUSTER_NAME}.plan" \
  -var "cluster_name=${CLUSTER_NAME}" \
  -var "resource_group_name=${CLUSTER_RG}" \
  -var-file="istio-central.tfvars"
terraform apply -auto-approve ${CLUSTER_NAME}.plan
```

## Apply Kustomize to cluster - Central
```bash
cd cluster-manifests

az aks get-credentials -g ${CLUSTER_RG} -n ${CLUSTER_NAME} --overwrite-existing
kubelogin convert-kubeconfig -l msi
flux bootstrap github --owner=${GITHUB_ACCOUNT} --repository=${GITHUB_REPO} --path=./cluster-manifests/central --branch=main  --personal=true --private=false
```

## Setup Istio Remote Secrets
```bash
export PRIMARY_CLUSTER_NAME=a212scus
export PRIMARY_CLUSTER_RG=DevSub02_K8S_a212scus_RG
export SECONDARY_CLUSTER_NAME=g6258cus
export SECONDARY_CLUSTER_RG=DevSub02_K8S_g6258cus_RG

istioctl x create-remote-secret --context="${PRIMARY_CLUSTER_NAME}" --name="${PRIMARY_CLUSTER_NAME}" \
  | kubectl --context="${SECONDARY_CLUSTER_NAME}" apply -f - 
istioctl x create-remote-secret --context="${SECONDARY_CLUSTER_NAME}" --name="${SECONDARY_CLUSTER_NAME}" \
  | kubectl --context="${PRIMARY_CLUSTER_NAME}" apply -f - 
```

# Validate
```bash
echo TBD
```

# References:
  * https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/
  * https://istio.io/latest/docs/setup/install/multicluster/multi-primary/
