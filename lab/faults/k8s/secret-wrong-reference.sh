# id: secret-wrong-reference
# layer: kubernetes
# symptom: CreateContainerConfigError, container never starts, no logs at all
# hint: describe the pod. logs cannot help - nothing was ever created.
# answer: envFrom references a Secret name that does not exist
inject() { k patch deploy db -n demo --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/envFrom/0/secretRef/name","value":"db-creds"}]'; }
revert() { k patch deploy db -n demo --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/envFrom/0/secretRef/name","value":"db-credentials"}]'; }
