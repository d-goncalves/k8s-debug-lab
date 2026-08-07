# id: scaled-to-zero
# layer: kubernetes
# symptom: nothing in kubectl get pods for that workload - absence, not failure
# hint: kubectl get deploy. absence is harder to notice than failure.
# answer: the Deployment was scaled to zero replicas
inject() { k scale deploy api -n demo --replicas=0; }
revert() { k scale deploy api -n demo --replicas=2; }
