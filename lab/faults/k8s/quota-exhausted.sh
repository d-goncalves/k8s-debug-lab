# id: quota-exhausted
# layer: kubernetes
# symptom: rollout stuck and NO new pod is ever created
# hint: there is no pod to describe. describe the ReplicaSet instead.
# answer: a ResourceQuota caps pods at the current count, so the ReplicaSet cannot create a surge pod
inject() {
  cat <<'YAML' | k apply -f -
apiVersion: v1
kind: ResourceQuota
metadata: {name: demo-quota, namespace: demo}
spec:
  hard: {pods: "5"}
YAML
}
revert() { k delete resourcequota demo-quota -n demo --ignore-not-found; }
