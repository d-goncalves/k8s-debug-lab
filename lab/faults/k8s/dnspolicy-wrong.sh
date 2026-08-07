# id: dnspolicy-wrong
# layer: kubernetes
# symptom: one workload cannot resolve cluster names; CoreDNS is healthy and others are fine
# hint: cluster DNS works. so why does only this pod fail? compare its spec with the working revision.
# answer: dnsPolicy Default makes the pod use the node resolver instead of cluster DNS
inject() { k patch deploy web -n demo --type=json -p '[{"op":"add","path":"/spec/template/spec/dnsPolicy","value":"Default"}]'; }
revert() { k patch deploy web -n demo --type=json -p '[{"op":"remove","path":"/spec/template/spec/dnsPolicy"}]' 2>/dev/null || true; }
