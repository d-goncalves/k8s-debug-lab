# id: hosts-entry-missing
# layer: host
# symptom: demo.local does not resolve at all
# hint: check /etc/hosts BEFORE the resolver. nsswitch checks files first.
# answer: the /etc/hosts entry for demo.local was removed
inject() { sed -i '/demo.local/d' /etc/hosts; }
revert() { grep -q demo.local /etc/hosts || echo "127.0.0.1 demo.local" >> /etc/hosts; }
