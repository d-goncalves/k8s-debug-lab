# id: pvc-missing-storageclass
# layer: kubernetes
# symptom: db pod Pending forever
# hint: describe the PVC, not just the pod. then kubectl get sc
# answer: storageClassName names a class that does not exist. the field is immutable, so the PVC must be recreated.
inject() {
  k scale deploy db -n demo --replicas=0
  k delete pvc db-data -n demo --wait=true 2>/dev/null
  cat <<'YAML' | k apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: db-data, namespace: demo}
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: fast-ssd
  resources: {requests: {storage: 1Gi}}
YAML
  k scale deploy db -n demo --replicas=1
}
revert() {
  k scale deploy db -n demo --replicas=0
  k delete pvc db-data -n demo --wait=true 2>/dev/null
  k apply -f "$STACK_DIR/10-db.yaml"
  k scale deploy db -n demo --replicas=1
}
