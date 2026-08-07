# id: ingress-wrong-host
# layer: kubernetes
# symptom: 404 from the ingress for demo.local
# hint: the rule matches on Host. compare it with what you are requesting.
# answer: the host rule was changed, so requests for demo.local match no rule
inject() { k patch ingress demo -n demo --type=json -p '[{"op":"replace","path":"/spec/rules/0/host","value":"demo.internal"}]'; }
revert() { k patch ingress demo -n demo --type=json -p '[{"op":"replace","path":"/spec/rules/0/host","value":"demo.local"}]'; }
