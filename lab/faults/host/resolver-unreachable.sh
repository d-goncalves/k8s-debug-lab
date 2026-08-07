# id: resolver-unreachable
# layer: host
# symptom: names do not resolve; ping 8.8.8.8 works fine
# hint: network up, DNS dead. cat /etc/resolv.conf
# answer: the configured nameserver is unreachable, so every lookup hangs
inject() { cp -n /etc/resolv.conf /etc/resolv.conf.labbak; printf 'nameserver 192.0.2.1\n' > /etc/resolv.conf; }
revert() { [ -f /etc/resolv.conf.labbak ] && mv -f /etc/resolv.conf.labbak /etc/resolv.conf || printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf; }
