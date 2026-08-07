# id: node-cordoned
# layer: kubernetes
# symptom: new pods stay Pending; running pods unaffected
# hint: kubectl get nodes. this one is visible there.
# answer: the node is cordoned, so the scheduler will not place new pods on it
inject() { k cordon "$(k get nodes -o jsonpath='{.items[0].metadata.name}')"; }
revert() { k uncordon "$(k get nodes -o jsonpath='{.items[0].metadata.name}')"; }
