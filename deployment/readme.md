# 📘 Kubernetes ReplicaSet & Deployment Tutorial

This guide demonstrates how **selectors determine which Pods a controller manages**, using **Deployment** and **ReplicaSet** manifests. It includes real outputs and lessons for DevOps aspirants.

---

## 🧩 Concepts Covered

* Pods, ReplicaSet (RS), Deployment
* `spec.selector` and `template.labels` relationship
* Ownership of existing Pods
* Conflict between multiple controllers
* Practical commands and outputs

---

## 1️⃣ Deployment Manifest

```yaml id="deploy-manifest"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    env: dev  # Custom label
spec:
  replicas: 2
  selector:
    matchLabels:
      env: dev
  template:
    metadata:
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

### Apply the Deployment

```bash id="deploy-apply"
kubectl apply -f deployment.yaml
```

### Check Deployment & ReplicaSet

```bash id="deploy-rs-check"
kubectl get deploy
kubectl get rs
kubectl get pods
```

**Expected output:**

```
# Deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2/2     2            2           2m

# ReplicaSet (created by Deployment)
NAME                              DESIRED   CURRENT   READY   AGE
nginx-deployment-7bdd655ff6       2         2         2       2m

# Pods
NAME                                        READY   STATUS    RESTARTS   AGE
nginx-deployment-7bdd655ff6-cdstz          1/1     Running   0          2m
nginx-deployment-7bdd655ff6-p4qxk          1/1     Running   0          2m
```

✅ Deployment creates a ReplicaSet and **2 Pods with labels `env: dev`**.

---

## 2️⃣ ReplicaSet Manifest (initial, conflicting selector)

```yaml id="rs-conflict"
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
  labels:
    env: dev  # Conflict: same as Deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      env: dev  # Conflicts with Deployment's selector
  template:
    metadata:
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

### Apply the ReplicaSet

```bash id="rs-apply"
kubectl apply -f rs.yaml
```

**Observed behavior:**

```
kubectl get rs
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-7bdd655ff6   2         2         2       3m
nginx-rs                      0         0         0       10s
```

**Explanation:**

* RS sees **existing Pods with `env: dev`** (owned by Deployment)
* RS cannot create extra Pods → shows `0/0`
* Deployment continues managing its 2 Pods

> ⚠️ Only **one controller can manage a Pod**. Overlapping selectors cause conflicts.

---

## 3️⃣ ReplicaSet Manifest (resolved, unique selector)

```yaml id="rs-unique"
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
  labels:
    env: test  # Unique label
spec:
  replicas: 3
  selector:
    matchLabels:
      env: test  # Unique selector
  template:
    metadata:
      labels:
        env: test
        type: frontend
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
```

### Apply the ReplicaSet

```bash id="rs-unique-apply"
kubectl apply -f rs-unique.yaml
```

### Check Pods & RS

```bash id="rs-unique-check"
kubectl get pods
kubectl get rs
```

**Expected output:**

```
# Pods
NAME                                        READY   STATUS    RESTARTS   AGE
nginx-deployment-7bdd655ff6-cdstz          1/1     Running   0          4m
nginx-deployment-7bdd655ff6-p4qxk          1/1     Running   0          4m
nginx-rs-5hlk7                              1/1     Running   0          10s
nginx-rs-dqjs2                              1/1     Running   0          10s
nginx-rs-lnlgx                              1/1     Running   0          10s

# RS
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-7bdd655ff6   2         2         2       4m
nginx-rs                      3         3         3       10s
```

**Explanation:**

* RS now has **unique selector `env: test`**
* RS creates its **3 Pods**
* Deployment still manages its **2 Pods**
* No conflict → both controllers coexist

---

## 4️⃣ Lessons Learned

1. **Selectors determine Pod ownership**

   * `spec.selector.matchLabels` links controller → Pods
   * Only one controller can “own” a Pod at a time

2. **Controllers adopt existing Pods**

   * RS or Deployment will manage any Pods matching their selector

3. **Avoid overlapping selectors**

   * Prevents controllers from fighting and deleting each other’s Pods

4. **Changing labels/selector resolves conflicts**

   * Controllers can coexist if selectors are unique

---


# 🔹 Key Point

**Yes, the manifest syntax for Deployment and ReplicaSet looks very similar**, especially the `spec.template` and `spec.selector`. For example:

### ReplicaSet

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      env: dev
  template:
    metadata:
      labels:
        env: dev
    spec:
      containers:
        - name: nginx
          image: nginx:latest
```

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      env: dev
  template:
    metadata:
      labels:
        env: dev
    spec:
      containers:
        - name: nginx
          image: nginx:latest
```

✅ **Almost identical syntax!**

---

# 🔹 What Deployment adds

Even though the YAML looks almost the same, **Deployment introduces extra features** under the hood:

1. **Rolling updates**

   ```yaml
   strategy:
     type: RollingUpdate
     rollingUpdate:
       maxSurge: 1
       maxUnavailable: 0
   ```

   * Updates Pods gradually instead of deleting all at once

2. **Rollbacks**

   * Tracks ReplicaSets over time
   * Can revert to a previous version

3. **Revision history**

   * Maintains old ReplicaSets for rollback

4. **Pause/Resume updates**

   * You can pause a rollout, make changes, then resume

---

# 🔹 Why the syntax looks the same

* **Deployment manages a ReplicaSet internally**
* The `spec.template` in Deployment is actually passed to the ReplicaSet it creates
* That’s why the YAML looks almost identical

---

# 🔹 Summary

| Aspect                   | ReplicaSet          | Deployment                       |
| ------------------------ | ------------------- | -------------------------------- |
| YAML syntax              | template + selector | template + selector (same as RS) |
| Rolling updates          | ❌ Not supported     | ✅ Supported                      |
| Rollbacks                | ❌ Not supported     | ✅ Supported                      |
| Manages RS automatically | ❌ Standalone        | ✅ Creates & manages ReplicaSets  |

---

**One-line takeaway:**

> **Deployment = ReplicaSet + versioning + rolling updates + rollback**, but the **core manifest (template + selector) looks almost the same**.

---

## 5️⃣ RS vs Deployment Comparison

| Feature                  | ReplicaSet (RS)                                     | Deployment                         |
| ------------------------ | --------------------------------------------------- | ---------------------------------- |
| API Version              | `apps/v1`                                           | `apps/v1`                          |
| Selector Type            | `matchLabels` + `matchExpressions`                  | `matchLabels` + `matchExpressions` |
| Set-based selectors      | ✅ Yes                                               | ✅ Yes                              |
| Equality-based selectors | ✅ Yes                                               | ✅ Yes                              |
| Existing Pod Management  | ✅ Manages Pods matching `spec.selector.matchLabels` | ✅ Manages Pods via RS it controls  |
| Replicas / Scaling       | ✅ Ensures N replicas                                | ✅ Ensures N replicas               |
| Rolling updates          | ❌ No                                                | ✅ Yes                              |
| Rollbacks                | ❌ No                                                | ✅ Yes                              |
| Production usage         | ✅ Used (via Deployment)                             | ✅ Always via Deployment            |
| Managed by Deployment    | ❌ Standalone                                        | ✅ Managed by Deployment logic      |

---

## 6️⃣ Commands Summary for Debugging

```bash id="commands-summary"
# Check Pods, RS, Deployment
kubectl get pods
kubectl get rs
kubectl get deploy

# Inspect labels & selectors
kubectl get pods --show-labels
kubectl describe rs <rs-name>
kubectl describe deploy <deployment-name>

# Explain fields
kubectl explain rs
kubectl explain deploy
kubectl explain rs.spec.selector
kubectl explain deploy.spec.selector
```

---

## ✅ Key Takeaways for DevOps Aspirants

1. **Pods are ephemeral units** → always manage via RS/Deployment
2. **Selector & template labels must match** → prevents errors
3. **Only one controller per Pod** → avoid overlapping selectors
4. **Use Deployment instead of standalone RS in production** → allows updates, rollbacks, and versioning
5. **Understanding manifests deeply** → essential before moving to Services, Ingress, ConfigMaps, Volumes

---

