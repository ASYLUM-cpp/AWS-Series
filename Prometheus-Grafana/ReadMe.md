# Kubernetes Cluster + Monitoring (Prometheus & Grafana)

---

## Detailed Technical Walkthrough

### 1. Cluster Architecture

**Environment**

* Platform: AWS EC2 (manual setup)
* OS: Ubuntu 22.04
* Kubernetes: v1.30.x
* Runtime: containerd
* CNI: Flannel

**Nodes**

* Control Plane: `k8s-master`
* Workers: `k8s-worker-1`, `k8s-worker-2`

Each node has:

* **Node IP (VPC private IP)** → `10.0.1.x`
* **Pod CIDR** allocated by Kubernetes

---

### 2. Networking Model (Key to Everything)

Each worker node has **three important network layers**:

1. **Node network (VPC)**

   * Interface: `enp39s0`
   * Example IP: `10.0.1.82`, `10.0.1.92`
   * Used for:

     * kubelet ↔ API server
     * NodePort traffic

2. **Pod bridge (cni0)**

   * Acts like a virtual switch
   * Example:

     * Worker-1: `10.244.1.1/24`
     * Worker-2: `10.244.2.1/24`

3. **Overlay network (flannel.1)**

   * Connects pod networks across nodes
   * Example:

     * Worker-1 subnet: `10.244.1.0/24`
     * Worker-2 subnet: `10.244.2.0/24`

Pods get IPs from the **node-local Pod CIDR**, not from the VPC.

---

### 3. Pod Communication (Mental Diagram)

```
[ Pod 10.244.1.5 ]
        │ veth
        ▼
[ cni0 bridge 10.244.1.1 ]
        │
        ▼
[ flannel overlay ]
        │
        ▼
[ Pod 10.244.2.7 on another node ]
```

Key point:

* Pod IPs **do not appear in `ip a` on the host**
* They exist inside **network namespaces**

---

### 4. Workload Exposure

**NodePort Service**

* Service listens on **every node IP**
* Example:

  * Node IP: `10.0.1.92`
  * NodePort: `30081`

Flow:

```
Client → NodeIP:NodePort
       → kube-proxy
       → Pod IP
```

That’s why this works:

```bash
curl http://10.0.1.92:30081/get
```

---

### 5. Monitoring Stack Design

#### Node Exporter (DaemonSet)

Why DaemonSet?

* One pod per node
* Direct access to host metrics

Configuration highlights:

* `hostNetwork: true`
* Port: `9100`

Result:

```bash
curl http://10.0.1.92:9100/metrics
```

Returns raw system metrics directly from the node.

---

#### Prometheus

Role:

* Central metrics scraper + time-series DB

Scraping model used:

```yaml
scrape_configs:
- job_name: "node-exporter"
  static_configs:
  - targets:
    - "10.0.1.82:9100"
    - "10.0.1.92:9100"
```

Debugging lessons:

* Pods running ≠ metrics available
* Always verify:

  * `/targets` page
  * `up` metric

---

### 6. Grafana

Role:

* Visualization only
* No data collection

Once Prometheus had data:

* Grafana Explore immediately populated
* Dashboards rendered without changes

Key realization:

> Grafana being empty almost always means **Prometheus is empty**.

---

### 7. Core Lessons Learned

* Kubernetes networking is **layered**, not magical
* Pod IP ≠ Node IP
* Services are traffic routers, not processes
* DaemonSets are perfect for node-level agents
* Monitoring problems are usually **config, not tools**

---

### 8. Why This Setup Matters

This setup mirrors **real production fundamentals**:

* Manual bootstrap
* Explicit networking
* Explicit scraping
* No managed abstractions

If something breaks here, you know *exactly where to look*.

---

**Next steps**

* Replace static targets with Kubernetes service discovery
* Add Alertmanager
* Add application-level metrics

---

*End of document*
