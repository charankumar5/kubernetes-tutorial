# 📘 Kubernetes ReplicaSet

## 📖 Overview

A **ReplicaSet (RS)** is a Kubernetes resource that ensures a specified number of identical Pods are running at all times.

It provides:

* Self-healing (recreates failed Pods)
* Scaling (increase/decrease replicas)
* Label-based Pod management

👉 ReplicaSet is the **modern replacement for ReplicationController** and is typically managed via a **Deployment** in production.

---

## 🚀 Key Features

* Maintains desired number of Pods (`replicas`)
* Automatically replaces failed or deleted Pods
* Uses **advanced label selectors**
* Supports flexible Pod matching logic

---

## 🧩 Example Manifest

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
  labels:
    env: dev  # Custom labels (key: value) defined by user # another example (app: dev) # key: value are customised and our wish to define.
spec:
  replicas: 3
  selector:
    matchLabels:
      env: dev  # Must match template labels # another example (app: dev) # key: value are customised and our wish to define.
  template:
    metadata:
      name: nginx-rs
      labels:
        env: dev
        type: frontend
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
```

---

## ✅ Notes on Manifest Comments

* ✔️ Labels (`key: value`) are **user-defined** → correct
* ✔️ Selector must match template labels → correct
* ⚠️ `metadata.name` inside `template` is **optional**

  * Kubernetes auto-generates Pod names
  * Usually omitted in real-world manifests

---

## ⚙️ How It Works

1. ReplicaSet is created with `replicas: 3`
2. It checks for Pods matching:

   ```yaml
   env: dev
   ```
3. If fewer than 3 exist → creates new Pods using the template
4. If more than 3 exist → deletes extra Pods

---

## 🔍 Exploring with kubectl

```bash
kubectl explain replicaset
kubectl explain rs.spec
kubectl explain rs.spec.selector
kubectl explain rs.spec.template
```

---

## ⚠️ Critical Rule

> The selector **must match** the template labels.

```yaml
selector:
  matchLabels:
    env: dev

template:
  metadata:
    labels:
      env: dev  # must match
```

❌ Mismatch → ReplicaSet becomes invalid

---

## 🧠 Selector Types in ReplicaSet

### 1. matchLabels (simple)

```yaml
matchLabels:
  env: dev
```

### 2. matchExpressions (advanced)

```yaml
matchExpressions:
  - key: env
    operator: In
    values: ["dev", "staging"]
```

Supported operators:

* `In`
* `NotIn`
* `Exists`
* `DoesNotExist`

---

## 🔁 Lifecycle Example

* Desired replicas: 3
* 1 Pod crashes
* ReplicaSet creates 1 new Pod

👉 Ensures system stability automatically

---

# ⚖️ ReplicaSet vs ReplicationController

## 🧠 Core Difference

> ReplicaSet = ReplicationController + **advanced (set-based) selectors**

---

## 📊 Side-by-Side Comparison

| Feature                  | ReplicaSet (RS)                                                                 | ReplicationController (RC) |
|--------------------------|--------------------------------------------------------------------------------|----------------------------|
| API Version              | `apps/v1`                                                                      | `v1`                       |
| Selector Type            | `matchLabels` + `matchExpressions`                                             | Simple key-value only      |
| Set-based selectors      | ✅ Yes                                                                          | ❌ No                       |
| Equality-based selectors | ✅ Yes                                                                          | ✅ Yes                      |
| Existing Pod Management  | ✅ Manages **existing Pods** matching `spec.selector.matchLabels`               | ✅ Manages existing Pods matching selector |
| Production usage         | ✅ Used (via Deployment)                                                        | ❌ Deprecated/legacy        |
| Managed by Deployment    | ✅ Yes                                                                          | ❌ No                       |

---

## 🔍 Syntax Difference

### RC Selector

```yaml
selector:
  env: dev
```

---

### ReplicaSet Selector

```yaml
selector:
  matchLabels:
    env: dev
```

---

## 🚀 Advanced Example (ONLY possible in ReplicaSet)

```yaml
selector:
  matchExpressions:
    - key: env
      operator: In
      values: ["dev", "staging"]
```

👉 RC cannot express this logic.

---

## 🎯 When to Use What

* Use **ReplicaSet** → indirectly via Deployment
* Avoid **ReplicationController** → legacy only

---

## 🧾 Summary

* ReplicaSet ensures a fixed number of Pods are running
* Uses label selectors to identify Pods
* Supports advanced selection logic (unlike RC)
* Typically managed by Deployments in real-world scenarios

---
