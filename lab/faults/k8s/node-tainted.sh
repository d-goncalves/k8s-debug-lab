# id: node-tainted
# layer: kubernetes
# symptom: new pods stay Pending; node shows Ready and schedulable
# hint: a taint is NOT visible in kubectl get nodes. describe the Pending pod.
# answer: a NoSchedule taint repels pods that do not tolerate it
inject() { k taint nodes "$(k get nodes -o jsonpath='{.items[0].metadata.name}')" maintenance=inprogress:NoSchedule; }
revert() { k taint nodes "$(k get nodes -o jsonpath='{.items[0].metadata.name}')" maintenance- 2>/dev/null || true; }
