#!/bin/bash

# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind


# validate installation
kind --version


# Install kubectl
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupgcd 
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list 
sudo apt-get update
sudo apt-get install -y kubectl

# validate installation
kubectl version --client
#kubectl cluster-info  # only works after kind cluster is created


# create a kind cluster using config file
kind create cluster --image kindest/node:v1.29.4@sha256:3abb816a5b1061fb15c6e9e60856ec40d56b7b52bcea5f5f1350bc6e2320b6f8 --name test-cluster --config kind-config.yaml
kind create cluster --name test-cluster --config networkpolicies/kind-installation/kind-config.yaml
kind create cluster --name test-cluster --config kind-config.yaml
kubectl config use-context kind-test-cluster
kubectl get nodes


# # Install Calico CNI plugin while setting network policies with Calico
# # Install the operator
# use calico to install on kind
# url: https://docs.tigera.io/calico/latest/getting-started/kubernetes/kind
# use manifest type to install and don't use operator type:
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.4/manifests/calico.yaml
# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/tigera-operator.yaml
# # # Install the custom resources
# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/custom-resources.yaml
kubectl get pods -n calico-system -o wide
kubectl get nodes -o wide

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.4/manifests/operator-crds.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.4/manifests/tigera-operator.yaml
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.31.4/manifests/custom-resources.yaml
kubectl create -f custom-resources.yaml

# # Label nodes so MySQL pods can be pinned to specific ones (Requirement 7)
# kubectl label node local-cluster-worker  database-location=node-1
# kubectl label node local-cluster-worker2 database-location=node-2
# kubectl get nodes --show-labels | grep database-location

