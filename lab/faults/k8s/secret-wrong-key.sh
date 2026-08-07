# id: secret-wrong-key
# layer: kubernetes
# symptom: db crashlooping on a fresh volume
# hint: read the secret contents, not just its name. base64 is encoding, not encryption.
# answer: the key the container expects was renamed inside the Secret
inject() {
  PW=$(k get secret db-credentials -n demo -o jsonpath='{.data.POSTGRES_PASSWORD}')
  k patch secret db-credentials -n demo --type=json \
    -p "[{\"op\":\"remove\",\"path\":\"/data/POSTGRES_PASSWORD\"},{\"op\":\"add\",\"path\":\"/data/DB_PASSWORD\",\"value\":\"$PW\"}]"
  k scale deploy db -n demo --replicas=0
  k delete pvc db-data -n demo --wait=true 2>/dev/null
  k apply -f "$STACK_DIR/10-db.yaml" 2>/dev/null
  k scale deploy db -n demo --replicas=1
}
revert() { k apply -f "$STACK_DIR/10-db.yaml"; k rollout restart deploy/db -n demo; }
