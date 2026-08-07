# id: coredns-scaled-to-zero
# layer: kubernetes
# symptom: several unrelated workloads fail at once; nginx cannot resolve its upstream
# hint: when everything breaks together, look one layer down, not at each workload
# answer: cluster DNS is gone, so in-cluster service names no longer resolve
inject() { k -n kube-system scale deploy coredns --replicas=0; k delete pod -n demo -l app=web 2>/dev/null; }
revert() { k -n kube-system scale deploy coredns --replicas=1; k -n kube-system rollout status deploy/coredns --timeout=180s; k rollout restart deploy/web -n demo; }
