# id: file-immutable
# layer: host
# symptom: cannot edit /etc/hosts even as root: Operation not permitted
# hint: EPERM as root, not EACCES. stat is blind to it. lsattr is not.
# answer: the immutable attribute (chattr +i) blocks all writes, including root
inject() { sed -i '/demo.local/d' /etc/hosts; echo "192.168.199.199 demo.local" >> /etc/hosts; chattr +i /etc/hosts; }
revert() { chattr -i /etc/hosts 2>/dev/null; sed -i '/demo.local/d' /etc/hosts; echo "127.0.0.1 demo.local" >> /etc/hosts; }
