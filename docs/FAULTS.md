# Fault catalogue

Generated from the fault scripts. Each script carries its own `symptom`, `hint`
and `answer` metadata; `./provision reveal` prints the answer for whatever is
currently injected.

## Reading a failure

| Signal | Meaning |
|--------|---------|
| `404` | proxy alive, no route matches |
| `502` | route exists, upstream failed fast |
| hang / timeout | sent somewhere with no listener and no reject |
| connection refused | reached the host, nothing on that port |
| `no route to host` | packet filtering / iptables |
| exit 137 | SIGKILL, almost always OOM |
| exit 127 / 126 | not found / not executable |
| `[::1]:8080 refused` from kubectl | no kubeconfig, not a dead cluster |
| `Pending` | scheduler could not place it — describe the pod, it explains itself |
| `Operation not permitted` as root | file attribute (chattr), not permissions |

## The unifying idea

Almost every Kubernetes fault here is a **name pointing at something that does
not exist** — a selector, an ingress class, a storage class, a secret key, a
port, a probe path — and none of them produce an error. The object looks normal.
Debugging is checking that references resolve, not scanning for red text.

See `./provision list` for the live table.
