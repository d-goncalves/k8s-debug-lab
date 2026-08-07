# id: hosts-entry-wrong
# layer: host
# symptom: demo.local resolves, but curl hangs then times out
# hint: it resolves fine. to what? a host that answers, or one that does not exist?
# answer: /etc/hosts points demo.local at an unreachable address, so connections hang
inject() { sed -i '/demo.local/d' /etc/hosts; echo "192.168.199.199 demo.local" >> /etc/hosts; }
revert() { sed -i '/demo.local/d' /etc/hosts; echo "127.0.0.1 demo.local" >> /etc/hosts; }
