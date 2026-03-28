
# Kubernetes Service Types Explained – Example with Nginx Deployment

## 📦 Deployment Overview

We have a simple **Nginx deployment**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    env: dev
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

**Key points:**

* Two replicas (pods) of Nginx will run on your cluster nodes.
* Labels `env: dev` are used to select pods for services.
* Container exposes port 80 internally.

---

## 🟢 ClusterIP Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: clusterip-service
  labels:
    env: dev
spec:
  selector:
    env: dev
  type: ClusterIP
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

### Explanation

* **Type:** `ClusterIP` (default)
* **Purpose:** Internal-only access inside the cluster
* **Selector:** Matches pods with label `env: dev` → connects to Nginx pods
* **Ports:**

  * `port: 80` → the service’s IP inside the cluster
  * `targetPort: 80` → forwards traffic to pod container port 80

### How it works

1. Kubernetes assigns a **virtual IP (ClusterIP)** to the service (e.g., `10.96.120.194`).
2. Any pod in the same cluster can access this service via `http://clusterip-service:80` or the ClusterIP.
3. Kubernetes load-balances traffic across the two Nginx pods automatically.

**Internal traffic example to test:**
* Run the sample pod in your cluster.
* Try to access nginx page with pod IP or ClusterIP IP not node IP

```bash
kubectl run test-pod --rm -it --image=busybox -- /bin/sh
# Inside the pod:
wget -qO- http://clusterip-service:80
wget -qO- http://pod-ip:80
```



✅ The request will go to **either of the two Nginx pods**, load-balanced by Kubernetes.

### Key takeaways

* ClusterIP **cannot be accessed from outside the cluster**.
* Perfect for **service-to-service communication** (microservices).
* Forms the backbone of internal traffic in production.

---

## 🔵 NodePort Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodeport-service
  labels:
    env: dev
spec:
  selector:
    env: dev
  type: NodePort
  ports:
    - nodePort: 30080
      protocol: TCP
      port: 80
      targetPort: 80
```

### Explanation

* **Type:** `NodePort`
* **Purpose:** Expose service externally for local testing or dev environments
* **Selector:** Same label `env: dev` → connects to Nginx pods
* **Ports:**

  * `port: 80` → service port inside cluster
  * `targetPort: 80` → pod container port
  * `nodePort: 30080` → node port accessible from outside the cluster

### How it works

1. Kubernetes allocates the service on port **30080** of all nodes.
2. You can access it from your host machine:

```bash
curl http://<NodeIP>:30080
# or if running locally: curl http://localhost:30080
```

3. Traffic is **forwarded to ClusterIP internally**, then distributed across Nginx pods.

**Traffic flow diagram:**

```
[Host or External] --> NodePort:30080 --> ClusterIP (internal) --> Pod1 or Pod2
```

### Key takeaways

* NodePort is **for external/dev access only**, not recommended in production.
* Useful to **quickly test services without an Ingress**.
* Internally, NodePort still uses **ClusterIP** to route traffic to pods.

---

## ⚡ Comparison: ClusterIP vs NodePort

| Feature         | ClusterIP                   | NodePort                       |
| --------------- | --------------------------- | ------------------------------ |
| Access scope    | Internal only               | Internal + External via NodeIP |
| Default type?   | Yes                         | No                             |
| External access | ❌                           | ✅                              |
| Use case        | Microservices, internal API | Local dev, testing without LB  |
| Port mapping    | ClusterIP → Pod             | NodePort → ClusterIP → Pod     |

---

## 🔑 Production Interpretation (without LB or Ingress)

* **ClusterIP:** Core building block. Every internal service should be ClusterIP.
* **NodePort:** Only needed for **testing locally or exposing small apps temporarily**.
* **Traffic routing:** NodePort forwards to ClusterIP → ClusterIP distributes to pods.
* **Scaling:** Add more replicas to the deployment → ClusterIP automatically balances traffic.

---

## 💡 Notes / Best Practices

1. Use **ClusterIP for all internal services** by default.
2. Only use **NodePort for dev or temporary exposure**.
3. Never rely on NodePort for production external access — use LoadBalancer or Ingress later.
4. Always label your pods and services carefully (`env`, `app`, etc.) to ensure proper selection.

---
