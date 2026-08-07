# id: nodeselector-unmatched
# layer: kubernetes
# symptom: pod Pending, node Ready and untainted
# hint: describe the Pending pod. then kubectl get nodes --show-labels
# answer: nodeSelector requires a label no node carries
inject() { k patch deploy db -n demo --type=json -p '[{"op":"add","path":"/spec/template/spec/nodeSelector","value":{"disktype":"ssd"}}]'; }
revert() { k patch deploy db -n demo --type=json -p '[{"op":"remove","path":"/spec/template/spec/nodeSelector"}]' 2>/dev/null || true; }
