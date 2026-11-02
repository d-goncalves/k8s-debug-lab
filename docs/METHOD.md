# Kubernetes, from the ground up

Written for someone who ran Nomad in production. Anchored to what you already know.

---

## 1. The one idea everything else follows from

Kubernetes is **not** a system you give commands to. It is a **database plus a swarm of independent control loops**.

You never say "start this container." You write down **desired state** into a database, and a set of independent controllers each notice, compare desired state against reality, and take one small step to close the gap. Forever, in a loop.

```
   you write desired state  ──►  API server  ──►  etcd
                                     │
                     controllers watch │
                                     ▼
                     compare desired vs actual
                                     │
                              take one action
                                     │
                              write status back
```

You already know this shape. Nomad's job specs and its scheduler do the same thing. The difference is that Kubernetes has **dozens** of these loops, each owning one narrow concern, and they only communicate through the shared database.

**This is the source of every bug you hit today.** Read on.

---

## 2. The components

### Control plane

| Component | Its entire job |
|---|---|
| **etcd** | The database. All cluster state lives here. Nothing else stores anything. |
| **kube-apiserver** | The *only* component that talks to etcd. Everything else talks to it. Does auth, validation, admission. |
| **kube-scheduler** | Watches for Pods with no node assigned. Picks a node. Writes it back. **That is all it does.** |
| **kube-controller-manager** | A bundle of control loops: Deployment→ReplicaSet→Pod, the endpoints controller, the node controller, and many more. |

Note how small the scheduler's job is. When a pod is `Pending`, it means the scheduler could not complete that one task. It is not "the cluster is broken."

### On every node

| Component | Its entire job |
|---|---|
| **kubelet** | Watches for pods assigned to *its* node. Tells the container runtime to run them. Runs probes. Reports status back. |
| **container runtime** (containerd) | Actually runs containers. This is what `crictl` talks to. |
| **kube-proxy** | Reads EndpointSlices, programs iptables/IPVS rules so ClusterIPs actually route. |
| **CNI plugin** (flannel on k3s) | Pod networking. Gives each pod an IP. |

### Add-ons (not core, but always present)

- **CoreDNS** — resolves `service.namespace.svc.cluster.local`
- **Ingress controller** (Traefik on k3s) — the actual edge proxy
- **Storage provisioner** (local-path on k3s) — creates volumes on demand

> **k3s** packs all of the above into a single binary and process. That's why `systemctl status k3s` covers everything, and why when k3s networking broke this morning, *every* pod failed at once.

---

## 3. The part you were missing: the object graph

Kubernetes objects refer to each other **by name or by label**. There are **no foreign keys and no validation**. Nothing checks that the thing you pointed at exists.

```
Deployment ──creates──► ReplicaSet ──creates──► Pod
                                                 │
Service ──── selector (labels) ─────────────────►│
   │
   └──► EndpointSlice   (written by the endpoints controller:
                         "which ready pods currently match?")
                                     │
                          kube-proxy reads this
                                     │
                          iptables rules

Ingress ──ingressClassName──► IngressClass ──► a controller
Ingress ──backend.service.name──► Service

Pod ──volumes──► PVC ──storageClassName──► StorageClass ──► provisioner
Pod ──envFrom──► ConfigMap / Secret
```

**Every single arrow above is an unvalidated reference.**

If the thing on the right doesn't exist, the controller on the left simply has nothing to do. It does not error. It does not warn. It just sits there, and the object looks completely normal in `kubectl get`.

This is why "everything seems ok" kept being wrong. **There was never going to be an error.** The fault is always a reference pointing at something that isn't there.

### Every fault you hit today, in one table

| What you saw | The dangling reference |
|---|---|
| Service with no endpoints | selector labels matched no pod |
| Pods Running but `0/1` | probe pointed at a port/path nothing served |
| Service reachable, connection refused | `targetPort` pointed at a port nothing listened on |
| PVC Pending forever | `storageClassName` named a class that doesn't exist |
| Pod won't start at all | `configMapRef` named a ConfigMap that doesn't exist |
| Ingress does nothing, 404 | `ingressClassName` named a class no controller owns |

**One bug, six costumes.**

---

## 4. The traffic path, end to end

This is the demo stack, hop by hop. Every hop is a place something can break.

```
curl http://demo.local/
  │
  ├─ 1. /etc/hosts resolves demo.local ──► 192.168.1.60
  │
  ├─ 2. port 80 on the node ──► Traefik pod (the actual proxy)
  │
  ├─ 3. Traefik checks Ingress rules IT HAS CLAIMED
  │        ↑ claimed via ingressClassName → IngressClass
  │        ✗ wrong class = rule never loaded = 404
  │
  ├─ 4. rule says: send to Service "web" port 80
  │
  ├─ 5. Service web ──► its EndpointSlice ──► a ready pod IP
  │        ✗ no matching labels = empty = nowhere to send
  │        ✗ pods not Ready   = excluded = nowhere to send
  │
  ├─ 6. kube-proxy iptables DNAT ──► 10.42.0.x:80
  │        ✗ wrong targetPort = forwarded to a closed door
  │
  ├─ 7. nginx in the web pod serves / or proxies /api/
  │        proxy_pass http://api.demo.svc.cluster.local:80/
  │        ✗ wrong port here = 502
  │
  ├─ 8. CoreDNS resolves api.demo.svc.cluster.local ──► ClusterIP
  │
  ├─ 9. Service api ──► EndpointSlice ──► api pod
  │
  └─ 10. api pod's initContainer waited for postgres:5432
           postgres ──► PVC ──► StorageClass ──► provisioner
           ✗ missing StorageClass = PVC Pending = pod Pending
```

**Debug top-down.** Find the highest hop that's broken and fix that first. Everything below it is unreachable anyway, so anything you "fix" down there is unverifiable.

---

## 5. How to think about status vs spec

Every object has:

- **`spec`** — what you asked for (you write this)
- **`status`** — what's actually true (controllers write this)

When they disagree, some controller is either failing or hasn't run. `kubectl describe` shows you both plus the **Events** that controller emitted.

**Status can be stale.** The `ADDRESS` column on that broken Ingress still showed an IP, left over from when Traefik did own it. Never treat a populated status field as proof that something works.

---

## 6. What this means for how you debug

Stop scanning output for errors. **Start checking that references resolve.**

For every reference an object makes, go and confirm the target exists:

| Reference | Confirm with |
|---|---|
| Service selector | `kubectl get pods --show-labels` |
| `ingressClassName` | `kubectl get ingressclass` |
| Ingress backend service | `kubectl get svc -n <ns>` |
| `targetPort` | what the process actually listens on |
| `storageClassName` | `kubectl get sc` |
| ConfigMap / Secret name | `kubectl get cm,secret -n <ns>` |

And know these two:

- **`kubectl describe`** shows Kubernetes' view: scheduling, probes, mounts, image pulls, events
- **`kubectl logs`** shows the application's view

Readiness, scheduling, mounting and pulling are all **Kubernetes decisions**, so they live in `describe`, never in logs.

---

## 7. If you remember one thing

> Kubernetes is loosely coupled objects that point at each other by name, reconciled by independent controllers, with **nothing validating that the targets exist**.

A broken cluster rarely looks broken. It looks completely normal, with one name pointing at nothing.
