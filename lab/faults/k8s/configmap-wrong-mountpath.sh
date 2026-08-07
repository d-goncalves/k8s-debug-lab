# id: configmap-wrong-mountpath
# layer: kubernetes
# symptom: HTTP 200, but the wrong content
# hint: read the body, not just the status code
# answer: the ConfigMap is mounted somewhere nginx does not read, so the image default applies
inject() { k patch deploy web -n demo --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts/0/mountPath","value":"/etc/nginx/conf.d.bak"}]'; }
revert() { k patch deploy web -n demo --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts/0/mountPath","value":"/etc/nginx/conf.d"}]'; }
