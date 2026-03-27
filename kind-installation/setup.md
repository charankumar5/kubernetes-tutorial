# Kubernetes (kind) Cluster Setup on Bare Metal

This guide walks through setting up a local Kubernetes cluster using `kind` (Kubernetes in Docker) on a bare metal machine. It includes installing required tools, creating the cluster, and deploying networking.

---

## Why These Tools and Versions?

* **kind v0.31.0**
  Used to run Kubernetes clusters locally using containers. A specific version ensures consistency and avoids unexpected breaking changes.

* **Kubernetes v1.29.4 (kindest/node image)**
  The cluster is created using a fixed Kubernetes version to guarantee compatibility with configuration and networking components.

* **kubectl v1.35**
  CLI tool used to interact with the Kubernetes cluster. Installed from the official repository to ensure a stable and supported version.

* **Calico v3.27.2**
  Provides networking for the cluster (pod-to-pod communication). A fixed version ensures predictable behavior and compatibility with the cluster.

---

## Prerequisites

* Linux machine (AMD64 / x86_64)
* `sudo` privileges
* Internet access

---

## 1. Install kind

Download and install `kind`:

```bash id="ocd8l7"
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### Validate installation

```bash id="vn0ph3"
kind --version
```

---

## 2. Install kubectl

Update packages and install dependencies:

```bash id="bbckfk"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
```

Add Kubernetes package repository:

```bash id="0sb6qm"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

```bash id="p1d09t"
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
```

Install `kubectl`:

```bash id="3m2gdw"
sudo apt-get update
sudo apt-get install -y kubectl
```

### Validate installation

```bash id="w606j5"
kubectl version --client
```

> Note: `kubectl cluster-info` will work only after the cluster is created.

---

## 3. Create kind Cluster

Create a cluster using a configuration file:

```bash id="eo4c7c"
kind create cluster \
  --image kindest/node:v1.29.4@sha256:3abb816a5b1061fb15c6e9e60856ec40d56b7b52bcea5f5f1350bc6e2320b6f8 \
  --name ngvoice-cluster \
  --config kind-config.yaml
```

Set the kubectl context:

```bash id="1rvj9v"
kubectl config use-context kind-ngvoice-cluster
```

Verify cluster nodes:

```bash id="71qqz7"
kubectl get nodes
```

---

## 4. Install Calico Network Plugin

Calico is required to enable networking inside the cluster (communication between pods and nodes).

Install the Calico operator:

```bash id="0ysc62"
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/tigera-operator.yaml
```

Install Calico custom resources:

```bash id="4j3s96"
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/custom-resources.yaml
```

Verify Calico pods:

```bash id="7cjgxx"
kubectl get pods -n calico-system -o wide
```

Verify nodes:

```bash id="l4u1r1"
kubectl get nodes -o wide
```

---

## 5. (Optional) Label Nodes

Label nodes to pin workloads (e.g., MySQL pods) to specific nodes:

```bash id="5s84ro"
kubectl label node ngvoice-cluster-worker  database-location=node-1
kubectl label node ngvoice-cluster-worker2 database-location=node-2
```

Verify labels:

```bash id="hzse2p"
kubectl get nodes --show-labels | grep database-location
```

---

## 6. (Optional) Apply Labels in EKS

For testing in an EKS cluster, apply labels to the appropriate nodes:

```bash id="aarijs"
kubectl label node ip-10-0-1-75.eu-central-1.compute.internal  database-location=node-1
kubectl label node ip-10-0-2-212.eu-central-1.compute.internal database-location=node-2
```

---

## Summary

This setup installs and configures:

* `kind` for running a local Kubernetes cluster
* `kubectl` for managing the cluster
* A Kubernetes cluster using a fixed version
* Calico for cluster networking

Using fixed versions across all components ensures consistency, reproducibility, and reduces the risk of compatibility issues.

---
