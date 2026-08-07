# id: ingress-wrong-backend
# layer: kubernetes
# symptom: 404 or 503 from the ingress; every pod healthy
# hint: kubectl get ingress does not show the backend. describe does.
# answer: the Ingress routes to a Service name that does not exist
inject() { k patch ingress demo -n demo --type=json -p '[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/name","value":"web-frontend"}]'; }
revert() { k patch ingress demo -n demo --type=json -p '[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/name","value":"web"}]'; }
