# Introduction 

This repo is to automate the setup of a Multi-primary Istio Mesh of two AKS clusters

# Prerequisites
1. Azure Subscription
1. Terraform 
1. [Environmental Setup](https://github.com/briandenicola/kubernetes-cluster-setup/blob/master/Deployment.md#required-existing-resources-and-configuration)
1.  Certificate Authority 

# Cluster Setup
## Deploy South Central Cluster
```bash
export ARM_USE_MSI=true 
export ARM_TENANT_ID=${AAD_TENANT_GUID}
export ARM_SUBSCRIPTION_ID=${AAD_SUBSCRIPTION_GUID}
export CORE_SUBSCRIPTION_ID=${AAD_CORE_SUBSCRIPTION_GUID}
export CLUSTER_RG=DevSub02_K8S_a212scus_RG
export CLUSTER_NAME=a212scus
cd ./infrastructure
az login --identity 
terraform init -backend=true -backend-config="tenant_id=${ARM_TENANT_ID}" -backend-config="subscription_id=${CORE_SUBSCRIPTION_ID}" -backend-config="key=${CLUSTER_NAME}.terraform.tfstate"
terraform plan -out="${CLUSTER_NAME}.plan" -var "cluster_name=${CLUSTER_NAME}" -var "resource_group_name=${CLUSTER_RG}" -var-file="istio-southcentral.tfvars"
terraform apply -auto-approve ${CLUSTER_NAME}.plan
```

## Apply Kustomize to cluster - South Central
```bash
az aks get-credentials -g ${CLUSTER_RG} -n ${CLUSTER_NAME} --overwrite-existing
kubelogin convert-kubeconfig -l msi
cd cluster-manifests
kubectl --context="${CLUSTER_NAME}" --apply --kustomize ./southcentral
```

## Deploy Central Cluster
```bash
export ARM_USE_MSI=true 
export ARM_TENANT_ID=${AAD_TENANT_GUID}
export ARM_SUBSCRIPTION_ID=${AAD_SUBSCRIPTION_GUID}
export CORE_SUBSCRIPTION_ID=${AAD_CORE_SUBSCRIPTION_GUID}
export CLUSTER_RG=DevSub02_K8S_g6258cus_RG
export CLUSTER_NAME=g6258cus
cd ./infrastructure
az login --identity 
terraform init -backend=true -backend-config="tenant_id=${ARM_TENANT_ID}" -backend-config="subscription_id=${CORE_SUBSCRIPTION_ID}" -backend-config="key=${CLUSTER_NAME}.terraform.tfstate" -reconfigure
terraform plan -out="${CLUSTER_NAME}.plan" -var "cluster_name=${CLUSTER_NAME}" -var "resource_group_name=${CLUSTER_RG}" -var-file="istio-central.tfvars"
terraform apply -auto-approve ${CLUSTER_NAME}.plan
```

## Apply Kustomize to cluster - South Central
```bash
az aks get-credentials -g ${CLUSTER_RG} -n ${CLUSTER_NAME} --overwrite-existing
kubelogin convert-kubeconfig -l msi
cd cluster-manifests
kubectl --context="${CLUSTER_NAME}" --apply --kustomize ./central
```

## Setup Istio Remote Secrets
```bash
export PRIMARY_SUBSCRIPTION_ID=${AAD_SUBSCRIPTION_GUID}
export PRIMARY_CLUSTER_NAME=a212scus
export PRIMARY_CLUSTER_RG=DevSub02_K8S_a212scus_RG
export SECONDARY_SUBSCRIPTION_ID=${AAD_SUBSCRIPTION_GUID}
export SECONDARY_CLUSTER_NAME=${g6258cus}
export SECONDARY_CLUSTER_RG=${DevSub02_K8S_g6258cus_RG}

bash ./istio-create-remote-secrets.sh
```

# Validate
```bash
echo TBD
```

# References:
  * https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/
  * https://istio.io/latest/docs/setup/install/multicluster/multi-primary/
