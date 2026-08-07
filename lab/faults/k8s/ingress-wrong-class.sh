# id: ingress-wrong-class
# layer: kubernetes
# symptom: 404 from the ingress; every pod healthy
# hint: which controller owns that Ingress?
# answer: ingressClassName names a class no running controller implements, so no rule is ever programmed
inject() { k patch ingress demo -n demo --type=merge -p '{"spec":{"ingressClassName":"nginx"}}'; }
revert() { k patch ingress demo -n demo --type=merge -p '{"spec":{"ingressClassName":"traefik"}}'; }
