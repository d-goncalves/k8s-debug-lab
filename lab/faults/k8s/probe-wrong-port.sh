# id: probe-wrong-port
# layer: kubernetes
# symptom: pods Running but 0/1, service has no ready endpoints
# hint: describe the pod and read the readiness probe. is anything listening there?
# answer: the readiness probe targets a port nothing serves, so the pod never becomes Ready
inject() { k patch deploy api -n demo --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":8081}]'; }
revert() { k patch deploy api -n demo --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":"http"}]'; }
