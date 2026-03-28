# Kubernetes ExternalName Service Example

## 1️⃣ What is ExternalName?

* `ExternalName` is a **special type of service** that **maps a service name inside the cluster to an external DNS name**.
* It does **not create a ClusterIP** or proxy traffic — it just returns a CNAME record.
* Useful when you want pods to access an **external service using a stable service name** in the cluster.

---

## 2️⃣ Example: Accessing an external API

Suppose you have an external API at `api.example.com`. You want your pods to access it via a service called `external-api` in your cluster.

```yaml id="externalname_service"
apiVersion: v1
kind: Service
metadata:
  name: external-api
  namespace: default
spec:
  type: ExternalName
  externalName: api.example.com
  ports:
    - protocol: TCP
      port: 80
```

---

## 3️⃣ How it works

* Pods in your cluster can now use `http://external-api:80` instead of hardcoding `api.example.com`.
* DNS resolution inside the cluster returns a **CNAME to the external host**:

```text id="dns_flow"
Pod --> http://external-api:80
     DNS resolves: external-api.default.svc.cluster.local --> api.example.com
     Traffic goes directly to api.example.com
```

---

## 4️⃣ Advantages

1. **Stable service name** in the cluster for external dependencies.
2. **Decouples pod code** from external URLs — just use the Kubernetes service name.
3. No proxy or ClusterIP overhead — lightweight.

---

### Quick comparison with ClusterIP

| Feature        | ClusterIP        | ExternalName         |
| -------------- | ---------------- | -------------------- |
| Internal LB    | ✅ routes to pods | ❌ just DNS mapping   |
| Stable name    | ✅                | ✅                    |
| Routes to pods | ✅                | ❌ external host only |
| Pod restarts   | ✅ handles it     | N/A                  |

---
