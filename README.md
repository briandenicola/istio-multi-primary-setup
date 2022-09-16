# Introduction 

This repo is to automate the setup of a Multi-primary Istio Mesh of two AKS clusters using Hashicorp Vault or using [Self Signed](https://github.com/briandenicola/istio-multi-primary-setup/tree/self-signed) Certificates

# Prerequisites
1. Azure Subscription
1. Terraform 
1. kubectl
1. istioctl
1. [Hashicorp Vault](./Vault.md)
1. Certificate Authority 

# Cluster Setup
## Deploy South Central Cluster
```bash
  az login
  terraform -chdir=./infrastructure workspace new southcentral
  terraform -chdir=./infrastructure init
  terraform -chdir=./infrastructure apply -var "location=southcentralus" -auto-approve
```

## Deploy Central Cluster
```bash
  az login

  terraform -chdir=./infrastructure workspace new central
  terraform -chdir=./infrastructure init
  terraform -chdir=./infrastructure apply -var "location=centralus" -auto-approve
```

## Peer Networks
```bash
  bash ./scripts/setup-env.sh
  bash ./scripts/peer.sh
```

## Boostrap Istio - Central
```bash
  bash ./scripts/setup-env.sh

  az aks get-credentials -g ${CENTRAL_CLUSTER_RG} -n ${CENTRAL_CLUSTER_NAME} --overwrite-existing
  kubelogin convert-kubeconfig -l azurecli
  watch kubectl apply -f ./scripts/istio-operator.yaml
  kubectl kustomize --enable-helm ./cluster-mantifests/central | kubectl apply -f -
```

## Boostrap Istio - South Central
```bash
  bash ./scripts/setup-env.sh

  az aks get-credentials -g ${SOUTH_CENTRAL_CLUSTER_RG} -n ${SOUTH_CENTRAL_CLUSTER_NAME} --overwrite-existing
  kubelogin convert-kubeconfig -l azurecli
  watch kubectl apply -f ./scripts/istio-operator.yaml
  kubectl kustomize --enable-helm ./cluster-mantifests/southcentral | kubectl apply -f -
```

## Setup Istio Remote Secrets
```bash
  bash ./scripts/setup-env.sh

  istioctl x create-remote-secret --context="${CENTRAL_CLUSTER_NAME}" --name="${CENTRAL_CLUSTER_NAME}" \
    | kubectl --context="${SOUTH_CENTRAL_CLUSTER_NAME}" apply -f - 
  istioctl x create-remote-secret --context="${SOUTH_CENTRAL_CLUSTER_NAME}" --name="${SOUTH_CENTRAL_CLUSTER_NAME}" \
    | kubectl --context="${CENTRAL_CLUSTER_NAME}" apply -f - 
```

# Validate
```bash
  echo TBD
```

# References:
  * https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/
  * https://istio.io/latest/docs/setup/install/multicluster/multi-primary/
