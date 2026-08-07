# id: service-selector-mismatch
# layer: kubernetes
# symptom: pods 1/1 Running, service reachable, nothing answers
# hint: kubectl get endpointslice -n demo
# answer: the Service selector matches no pod labels, so the EndpointSlice is empty
inject() { k patch svc web -n demo --type=merge -p '{"spec":{"selector":{"app":"web-frontend"}}}'; }
revert() { k patch svc web -n demo --type=merge -p '{"spec":{"selector":{"app":"web"}}}'; }
