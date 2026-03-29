# 📦 Kubernetes ConfigMap — Complete Practical Tutorial

This guide explains **ConfigMaps in Kubernetes** in a clean, practical way with:

* ✅ Key-value usage (env variables)
* ✅ File-based usage (mounted files)
* ✅ Full manifests with comments
* ✅ Commands to run everything
* ✅ How to verify inside containers
* ✅ Real-world production use cases

---

# 🧠 What is a ConfigMap?

A **ConfigMap** is used to store **non-sensitive configuration data** in Kubernetes.

You can use it in two main ways:

| Type          | Usage                            |
| ------------- | -------------------------------- |
| 🔹 Key-value  | Inject as environment variables  |
| 🔹 File-based | Mount as files inside containers |

---

# 🔹 1. Create a ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: testmap
data:
  # Simple key-value
  testdata: testeddata  

  # File: nginx config
  default.conf: |
    server {
      listen 80;
      location / {
        root /usr/share/nginx/html;
        index index_rendered.html;
      }
    }

  # File: HTML template
  index.template.html: |
    <!DOCTYPE html>
    <html>
    <head><title>Web Server</title></head>
    <body>
      <h1>Welcome to the Web Server</h1>
    </body>
    </html>
```

---

# 🚀 Apply ConfigMap

```bash
kubectl apply -f configmap.yaml
```

Verify:

```bash
kubectl get configmap
kubectl describe configmap testmap
```

---

# 🔹 2. Use ConfigMap as Environment Variables

## 📌 Pod Manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cm-env-demo
spec:
  containers:
    - name: app
      image: busybox:latest
      command: ['sh', '-c', 'echo "Running..." && sleep 3600']

      env:
        # Static value
        - name: FIRSTNAME
          value: "test"

        # Inject from ConfigMap (key-value)
        - name: FETCH_VALUE
          valueFrom:
            configMapKeyRef:
              name: testmap   # ConfigMap name
              key: testdata   # key inside ConfigMap

        # ⚠️ Works, but NOT recommended for large content
        - name: FROM_CM
          valueFrom:
            configMapKeyRef:
              name: testmap
              key: index.template.html
```

---

## 🔍 Verify inside Pod

```bash
kubectl exec -it cm-env-demo -- sh
```

```sh
echo $FETCH_VALUE
```

Output:

```
testeddata
```

---

## ⚠️ Important Notes

* Good for **small values only**
* Not ideal for files (HTML, configs)
* Hard to manage large content

---

# 🔹 3. Use ConfigMap as Files (Recommended)

## 📌 Pod Manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cm-volume-demo
spec:
  containers:
    - name: app
      image: busybox:latest
      command: ['sh', '-c', 'echo "Running..." && sleep 3600']

      volumeMounts:
        # Mount ConfigMap as files
        - name: config-volume
          mountPath: /config

  volumes:
    - name: config-volume
      configMap:
        name: testmap
```

---

## 📁 Inside Container

```bash
kubectl exec -it cm-volume-demo -- sh
```

```sh
ls /config
```

Output:

```
default.conf
index.template.html
testdata
```

---

## 📖 Read Files

```sh
cat /config/testdata
```

Output:

```
testeddata
```

```sh
cat /config/index.template.html
```

---

## 🧠 Key Concept

| ConfigMap Key         | Becomes                       |
| --------------------- | ----------------------------- |
| `testdata`            | `/config/testdata`            |
| `default.conf`        | `/config/default.conf`        |
| `index.template.html` | `/config/index.template.html` |

---

# 🔹 4. Mount Specific Files Only (subPath)

```yaml
volumeMounts:
  - name: config-volume
    mountPath: /etc/nginx/conf.d/default.conf
    subPath: default.conf
```

👉 Only mounts **one file**, not the entire ConfigMap.

---

# 🔹 5. Mount Selected Keys Only

```yaml
volumes:
  - name: config-volume
    configMap:
      name: testmap
      items:
        - key: default.conf
          path: default.conf
```

---

# 🔥 6. Combined Example (Best Practice)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cm-full-demo
spec:
  containers:
    - name: app
      image: busybox:latest
      command: ['sh', '-c', 'sleep 3600']

      env:
        - name: APP_MODE
          valueFrom:
            configMapKeyRef:
              name: testmap
              key: testdata

      volumeMounts:
        - name: config-volume
          mountPath: /config

  volumes:
    - name: config-volume
      configMap:
        name: testmap
```

---

# 🔍 Verify Everything

```bash
kubectl exec -it cm-full-demo -- sh
```

```sh
echo $APP_MODE
ls /config
cat /config/default.conf
```

---

# 🧪 Useful Commands Cheat Sheet

```bash
# Apply resources
kubectl apply -f file.yaml

# List ConfigMaps
kubectl get configmap

# Describe ConfigMap
kubectl describe configmap testmap

# Run shell inside pod
kubectl exec -it <pod> -- sh

# View logs
kubectl logs <pod>

# Delete pod
kubectl delete pod <pod>
```

---

# 🚫 Common Mistakes

❌ Wrong field name:

```yaml
ConfigMapKeyRef   # ❌ wrong
configMapKeyRef   # ✅ correct
```

❌ Using env vars for large files
❌ Forgetting to create ConfigMap before Pod
❌ Expecting variable substitution inside ConfigMap (it does NOT happen automatically)

---

# 🏭 Real-World Use Cases

## 🔹 1. NGINX Configuration

* Store `default.conf`
* Mount into `/etc/nginx/conf.d/`

---

## 🔹 2. Application Config Files

* `application.yml`
* `config.json`

---

## 🔹 3. HTML Templates

* Used with `envsubst` or `sed`
* Inject runtime values (Pod IP, hostname)

---

## 🔹 4. Feature Flags

```yaml
featureX: enabled
featureY: disabled
```

---

## 🔹 5. Multi-environment configs

* dev / staging / prod differences

---

## 🔹 6. Sidecar / Init Container Sharing

* Generate config in init container
* Share via `emptyDir`

---

# 🔥 Best Practices

✔ Use **env vars** for:

* small configs
* flags
* endpoints

✔ Use **volumes** for:

* files
* templates
* configs

✔ Use **subPath** for:

* single file mounting

✔ Keep ConfigMaps:

* small
* readable
* environment-specific

---

# 🧠 Final Summary

| Feature      | Env Var | Volume |
| ------------ | ------- | ------ |
| Small values | ✅       | ✅      |
| Large files  | ❌       | ✅      |
| Readability  | ❌       | ✅      |
| Flexibility  | ⚠️      | ✅      |

---

# 🎯 Key Takeaway

* ConfigMap = **external configuration**
* Use:

  * 🔹 env → simple values
  * 🔹 volume → files (most common in real apps)

---

# 🚀 Kubernetes ConfigMap — From Basics to Production (Part 2)

This is a **continuation** of your ConfigMap learning, focusing on:

1. ✅ **ConfigMap + Deployment (production setup)**
2. ✅ **ConfigMap updates without restarting Pods**
3. ✅ Real-world production use cases

---

# 🔹 1. ConfigMap + Deployment (Production Setup)

In real environments, you **don’t use standalone Pods**.
You use a **Deployment** so Pods can scale, restart, and update safely.

---

## 📦 Step 1: ConfigMap (Same as before)

```yaml id="cm-prod"
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-config
data:
  app.properties: |
    APP_ENV=production
    APP_DEBUG=false

  index.html: |
    <html>
      <body>
        <h1>Welcome to Production App</h1>
      </body>
    </html>
```

---

## 🚀 Step 2: Deployment using ConfigMap

```yaml id="deploy-prod"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 2

  selector:
    matchLabels:
      app: webapp

  template:
    metadata:
      labels:
        app: webapp

    spec:
      containers:
        - name: web-container
          image: nginx:latest

          # 🔹 Inject small config as env variable
          env:
            - name: APP_ENV
              valueFrom:
                configMapKeyRef:
                  name: web-config
                  key: app.properties

          # 🔹 Mount files from ConfigMap
          volumeMounts:
            - name: config-volume
              mountPath: /usr/share/nginx/html/index.html
              subPath: index.html   # only mount this file

      volumes:
        - name: config-volume
          configMap:
            name: web-config
```

---

## 🧪 Apply and Run

```bash id="cmd1"
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
```

---

## 🔍 Verify

```bash id="cmd2"
kubectl get pods
```

```bash id="cmd3"
kubectl exec -it <pod-name> -- sh
```

```sh id="cmd4"
cat /usr/share/nginx/html/index.html
```

---

## 🌐 Access Application

```bash id="cmd5"
kubectl port-forward deployment/web-deployment 8080:80
```

Open:

```
http://localhost:8080
```

---

## 🧠 Production Insight

* Deployment ensures:

  * Self-healing Pods
  * Rolling updates
  * Scaling

* ConfigMap ensures:

  * Externalized configuration
  * No need to rebuild images

---

# 🏭 Real-World Use Cases (Production)

## 🔹 1. Web Server Configuration (NGINX)

* Store:

  * `nginx.conf`
  * `default.conf`
* Mount into:

  ```
  /etc/nginx/conf.d/
  ```

---

## 🔹 2. Microservices Configuration

Example:

```properties
DB_HOST=db.prod.internal
CACHE_ENABLED=true
LOG_LEVEL=INFO
```

👉 Inject via env vars

---

## 🔹 3. Frontend Static Content

* HTML templates
* Maintenance pages
* Version banners

---

## 🔹 4. Feature Flags

```yaml id="featureflags"
feature_login: "enabled"
feature_beta_ui: "disabled"
```

👉 Toggle features without redeploying image

---

# 🔄 2. ConfigMap Updates WITHOUT Restarting Pods

This is a **very important production concept**.

---

## ⚠️ Behavior Depends on Usage

| Usage Type      | Auto Update? |
| --------------- | ------------ |
| Env variables   | ❌ NO         |
| Mounted volumes | ✅ YES        |

---

## 🔹 Case 1: Mounted ConfigMap (Auto Updates)

### Update ConfigMap

```bash id="cmd6"
kubectl edit configmap web-config
```

Change:

```html id="html1"
<h1>Updated Version</h1>
```

---

### What Happens?

* Kubernetes updates the file inside the container
* Delay: ~10–30 seconds

Check:

```bash id="cmd7"
kubectl exec -it <pod> -- cat /usr/share/nginx/html/index.html
```

---

## ❗ Important Limitation

Even though file updates automatically:

👉 Your application **must reload the file**

* NGINX → needs reload
* App → must reread file

---

## 🔹 Case 2: Environment Variables (NO Updates)

If ConfigMap changes:

```yaml id="envcase"
env:
  - name: APP_ENV
    valueFrom:
      configMapKeyRef:
        name: web-config
        key: app.properties
```

👉 Pods will **NOT see updates**

---

## 🔧 Solution: Restart Pods

```bash id="cmd8"
kubectl rollout restart deployment web-deployment
```

---

# 🔥 Production Pattern: Auto Reload

## 🔹 Option 1: Sidecar Reload Container

* Watches file changes
* Sends reload signal

Example tools:

* `inotify`
* `configmap-reload`

---

## 🔹 Option 2: Application-Level Reload

* App periodically reads config file
* Or exposes `/reload` endpoint

---

## 🔹 Option 3: Rolling Restart (Most Common)

```bash id="cmd9"
kubectl rollout restart deployment web-deployment
```

✔ Safe
✔ Simple
✔ Widely used in production

---

# 🧠 Key Production Lessons

## ✅ Use volumes when:

* You need dynamic updates
* Config changes frequently

## ❌ Avoid env vars when:

* Config changes often
* Large data involved

---

# ⚠️ Common Pitfalls

❌ Expecting env vars to auto-update
❌ Forgetting app reload mechanism
❌ Mounting entire ConfigMap when only one file is needed
❌ Not using `subPath` correctly

---

# 🎯 Final Summary

## 🔹 ConfigMap + Deployment

* Use Deployment for scalability
* Mount ConfigMap as files for flexibility
* Inject small configs via env vars

---

## 🔹 Config Updates

| Method       | Behavior         |
| ------------ | ---------------- |
| Env vars     | Requires restart |
| Volume mount | Auto updates     |

---

## 🚀 Real Production Strategy

* ConfigMap mounted as volume
* App supports reload OR
* Use rollout restart

---

# 🧩 Final Thought

> ConfigMaps are not just config storage —
> they are a **decoupling mechanism between code and environment**.

---

# 🔹 Kubernetes Secrets vs ConfigMaps (Simple Overview)

This is a **short, continuation section** from your ConfigMap tutorial, focused on production considerations.

---

## 1️⃣ ConfigMaps

| Feature     | Description                                            |
| ----------- | ------------------------------------------------------ |
| Data type   | Non-sensitive (plain text)                             |
| Use case    | App config, HTML templates, feature flags, small files |
| Mounting    | Env vars, volume files                                 |
| Auto-update | Only works when mounted as files (not env vars)        |
| Example     | `app.properties`, `nginx.conf`, `index.html`           |

---

## 2️⃣ Secrets

| Feature     | Description                                                   |
| ----------- | ------------------------------------------------------------- |
| Data type   | Sensitive (passwords, tokens, certificates)                   |
| Encoding    | Base64 (not encrypted at rest by default)                     |
| Mounting    | Env vars or volumes                                           |
| Auto-update | Same as ConfigMap (file mount updates, env vars need restart) |
| Example     | `DB_PASSWORD`, `API_KEY`, `tls.crt`                           |

---

## 🔹 Key Differences

| Aspect                 | ConfigMap                | Secret                                |
| ---------------------- | ------------------------ | ------------------------------------- |
| Purpose                | Non-sensitive config     | Sensitive config                      |
| Encoding               | Plain text               | Base64                                |
| Kubernetes object type | v1/ConfigMap             | v1/Secret                             |
| Recommended usage      | App settings, templates  | Passwords, API keys, TLS certificates |
| Security               | Not encrypted by default | Can enable encryption at rest in K8s  |

---

## 🔹 Best Practices for Production

1. **ConfigMap**

   * Use for all non-sensitive data
   * Mount as files if updates are needed
   * Use subPath to avoid overwriting files

2. **Secret**

   * Use for passwords, keys, tokens
   * Avoid printing secrets in logs
   * Enable encryption at rest if available
   * Combine with ConfigMap for combined configs if needed

---

### 🔹 Quick Example

```yaml id="secret-example"
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  DB_USER: YWRtaW4=       # admin
  DB_PASSWORD: MWYyZDFlMmU2N2Rm   # mysecretpassword
```

Mount in pod as:

```yaml id="secret-pod"
env:
  - name: DB_USER
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: DB_USER
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: DB_PASSWORD
```

---

### ✅ Takeaway

* **ConfigMap → plain config**
* **Secret → sensitive config**
* Both can be **mounted as env vars or files**, but secrets need careful handling in production.

---