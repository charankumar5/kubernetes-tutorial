# Kubernetes Services – Pod IP, ClusterIP, NodePort, and LoadBalancer

## 1️⃣ Example Deployment

### Deployment: Nginx

```yaml id="nginx_deploy"
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

* **2 replicas** → 2 pods running Nginx.
* Pods are labeled `env=dev`.
* Each pod gets a **unique Pod IP** inside the cluster.

---

### Service: LoadBalancer

```yaml id="lb_service"
apiVersion: v1
kind: Service
metadata:
  name: load-balancing-service
  labels:
    env: dev
  namespace: default
spec:
  selector:
    env: dev
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

* **Selector `env=dev`** → routes traffic to the 2 Nginx pods.
* **LoadBalancer type**:

  * In cloud: provisions external IP for external access.
  * In local clusters (kind/minikube): exposes NodePort automatically.
* Internally, Kubernetes creates a **ClusterIP** to route and load balance traffic to pods.

---

## 2️⃣ How traffic flows

### Pod IP (Direct access)

* Pods can communicate **directly using Pod IPs**:

```text
PodA --> 192.168.1.3:80  # Hits specific pod
PodA --> 192.168.2.2:80  # Hits other pod
```

* **Limitations**:

  * Pod IPs change on restart.
  * No load balancing.
  * Hard to use in production.

---

### ClusterIP (Internal load balancing)

* Kubernetes automatically creates **ClusterIP** for the LoadBalancer service:

```text
ClusterIP: 10.96.16.55
```

* Internal traffic to the service:

```text
PodA --> ClusterIP:80 --> Pod1 or Pod2 (load-balanced)
```

* **Advantages**:

  * Stable IP / DNS name (`load-balancing-service`)
  * Automatic load balancing
  * Resilience if a pod restarts

---

### NodePort (External access fallback)

* On local clusters, LoadBalancer exposes **NodePort automatically**:

```text
NodePort: 32265
Access: <NodeIP>:32265
```

* Traffic flow:

```text
External Client --> NodeIP:32265 --> ClusterIP:10.96.16.55 --> Pod1 or Pod2
```

---

### LoadBalancer (Cloud / External access)

* In cloud environments, Kubernetes provisions an **external LoadBalancer** automatically.
* Traffic flow:

```text
Client --> LoadBalancer External IP --> ClusterIP --> Pod1 / Pod2
```

* ClusterIP **always sits between external traffic and pods**, ensuring load balancing and resilience.

---

## 3️⃣ Visual Summary

```
              External Client
                     |
          +----------+----------+
          |  LoadBalancer / NodePort
          +----------+----------+
                     |
               ClusterIP (stable)
                     |
          +----------+----------+
          |                     |
       Pod1:80               Pod2:80
```

* **Pod IPs**: ephemeral, direct pod-to-pod traffic, no LB.
* **ClusterIP**: stable, internal load balancing, service discovery.
* **NodePort**: exposes service on each node for local access.
* **LoadBalancer**: external access in cloud, sits on top of ClusterIP.

---

## 4️⃣ Key Takeaways

1. **Pod IPs are temporary** → not recommended for production.
2. **ClusterIP is essential** → decouples pods, provides load balancing and resilience.
3. **NodePort** → useful for local development or exposing services in local clusters.
4. **LoadBalancer** → cloud-friendly external access; internally still relies on ClusterIP.
5. **Always use services** (ClusterIP or higher) for production deployments to ensure stability, scalability, and proper routing.

---
