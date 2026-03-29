# 🌐 1. Architecture Overview

We’ll model a simple app:

* **frontend** → talks to backend
* **backend** → talks to database
* **database** → should NOT be publicly reachable

Running in Kubernetes (e.g., Amazon EKS or Azure Kubernetes Service)

---

# 🧱 2. Cluster Layout (Default CNI – Flat Network)

```
Node 1                          Node 2
--------                        --------
frontend-pod (10.0.1.2)         db-pod (10.0.2.3)
backend-pod  (10.0.1.3)
```

---

# 🔌 3. Default Connectivity (No Policies)

Here’s what Kubernetes allows **by default**:

```
frontend ───────────────► backend     ✅
backend  ───────────────► db          ✅
frontend ───────────────► db          ✅ (THIS surprises people)
db       ───────────────► frontend    ✅
```

👉 **Everything can talk to everything**

---

# 🧠 4. Why This Happens

Because of the CNI (like Amazon VPC CNI or Azure CNI):

* Each pod gets an IP
* Routing is set up across nodes
* No firewall rules exist

So Kubernetes behaves like:

```
🌐 One big flat network (like all services on the same LAN)
```

---

# 📦 5. Add Namespaces (Still No Security)

Let’s organize things:

* `frontend` namespace → frontend pod
* `backend` namespace → backend pod
* `db` namespace → database pod

---

## 🔍 What people expect

```
frontend ─────X────► db   ❌ (expected blocked)
```

---

## ✅ What actually happens

```
frontend ───────────────► db   ✅ STILL ALLOWED
```

👉 Namespaces **do NOT isolate networking**

---

# 🚨 6. The Security Problem

In a real app, you usually want:

* frontend → backend ✅
* backend → db ✅
* frontend → db ❌

But default Kubernetes gives you:

```
frontend ───────────────► db   ❌ (unwanted but allowed)
```

---

# 🔐 7. Fixing It with NetworkPolicy

You use a
Kubernetes NetworkPolicy

---

## Step 1: Default Deny (Critical First Step)

Apply a policy that blocks everything:

```
ALL TRAFFIC: DENIED ❌
```

Now:

```
frontend ─────X────► backend
backend  ─────X────► db
```

---

## Step 2: Allow Required Flows

### Allow frontend → backend

```
frontend ───────────────► backend   ✅
```

### Allow backend → db

```
backend ───────────────► db         ✅
```

---

## Final Result

```
frontend ───────────────► backend   ✅
backend  ───────────────► db        ✅

frontend ─────X────► db             ❌
db       ─────X────► frontend       ❌
```

---

# 🧭 8. Before vs After (Best Mental Model)

## ❌ Default (Flat Network)

```
        [ frontend ]
          /   |   \
         /    |    \
        v     v     v
   [ backend ]   [ db ]

ALL CONNECTED ✅
```

---

## ✅ With Network Policies

```
[ frontend ] ─────► [ backend ] ─────► [ db ]

frontend ─────X────► db   ❌ blocked
```

---

# ⚙️ 9. EKS vs AKS in This Architecture

Whether you run this on:

* Amazon EKS with Amazon VPC CNI
* Azure Kubernetes Service with Azure CNI

👉 The behavior is identical:

* Flat network by default
* No isolation
* Policies required for security

---

# 🧾 10. Final Takeaways

✔️ Default CNI = **flat, fully open network**
✔️ Namespaces = **organization only, not security**

❌ Without policies:

* frontend can talk directly to db
* any pod can reach any pod

🔐 With NetworkPolicies:

* You define **exact communication paths**
* You enforce **least privilege networking**

---

Perfect — let’s turn this into a **practical, extended, hands-on lab** you can actually deploy and test.

This guide builds a **frontend → backend → database architecture**, shows the **default flat networking behavior**, and then **secures it using policies**, all in Kubernetes (works the same on Amazon EKS and Azure Kubernetes Service).

---

# 📘 1. What You Will Prove

### Default behavior (before policies)

```text
frontend → backend   ✅
backend  → db        ✅
frontend → db        ✅ (this should NOT happen in secure design)
```

---

### After NetworkPolicies

```text
frontend → backend   ✅
backend  → db        ✅
frontend → db        ❌ BLOCKED
```

---

# 🧱 2. Architecture Overview

We’ll deploy:

* **frontend** → curl client
* **backend** → nginx server
* **db** → nginx server (pretend DB)

Each in separate namespaces.

---

# 📦 3. Full YAML Setup

---

## 3.1 Namespaces

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: frontend
---
apiVersion: v1
kind: Namespace
metadata:
  name: backend
---
apiVersion: v1
kind: Namespace
metadata:
  name: database
```

---

## 3.2 Backend Deployment + Service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: backend
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
```

---

## 3.3 Database Deployment + Service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
  namespace: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: database
spec:
  selector:
    app: db
  ports:
  - port: 80
    targetPort: 80
```

---

## 3.4 Frontend Pod (curl client)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: frontend
  labels:
    app: frontend
spec:
  containers:
  - name: curl
    image: curlimages/curl
    command: ["sleep", "3600"]
```

---

# 🚀 4. Deploy Everything

```bash
kubectl apply -f namespaces.yaml
kubectl apply -f backend.yaml
kubectl apply -f db.yaml
kubectl apply -f frontend.yaml
```

---

# 🧪 5. TEST 1 — Prove Flat Network (Default)

---

## Exec into frontend pod

```bash
kubectl exec -n frontend -it frontend -- sh
```

---

## Test backend access

```bash
curl http://backend.backend.svc.cluster.local
```

✅ Expected: **Works**

---

## Test database access (IMPORTANT)

```bash
curl http://db.database.svc.cluster.local
```

👉 ✅ **This ALSO works (default behavior)**

---

## 🔥 Key Insight

Even though:

* frontend ≠ database namespace

It still works because:

```text
Flat network → no restrictions
```

---

# 🔐 6. Apply Network Policies

Now we secure the system.

---

## 6.1 Default Deny (All Namespaces)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: frontend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: database
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

---

## 🚨 Result now

Everything is blocked:

```text
frontend → backend ❌
backend  → db      ❌
```

---

# 🟢 6.2 Allow Frontend → Backend

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
```

---

# 🟢 6.3 Allow Backend → Database

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-db
  namespace: database
spec:
  podSelector:
    matchLabels:
      app: db
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: backend
```

---

# 🧪 7. TEST 2 — After Policies

---

## From frontend pod

```bash
kubectl exec -n frontend -it frontend -- sh
```

---

### Test backend

```bash
curl http://backend.backend.svc.cluster.local
```

✅ Works

---

### Test database

```bash
curl http://db.database.svc.cluster.local
```

❌ Fails (timeout / connection refused)

---

## From backend pod

```bash
kubectl exec -n backend -it deploy/backend -- sh
```

```bash
curl http://db.database.svc.cluster.local
```

✅ Works

---

# 🎯 8. Final Result

```text
frontend → backend   ✅
backend  → db        ✅
frontend → db        ❌ BLOCKED
```

---

# 🧠 9. What You Learned

### Default CNI Behavior

* Flat network
* No restrictions
* All pods can talk

---

### Namespaces

* Only logical grouping
* No network isolation

---

### NetworkPolicy

* Enables firewall rules
* Default = allow all
* With policy = deny unless allowed

---

# 🧭 10. Pro Tips (Real World)

* Always start with **default deny**
* Then allow only required flows
* Label namespaces explicitly if needed
* Test with `curl` or `wget` from pods

---

# ✅ Final Mental Model

```text
Without policies:
🌐 Everything is open

With policies:
🔐 You control every connection
```

---
