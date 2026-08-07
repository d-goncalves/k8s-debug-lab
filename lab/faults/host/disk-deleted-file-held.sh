# id: disk-deleted-file-held
# layer: host
# symptom: df shows the disk filling; du cannot find the space
# hint: df != du means a deleted file is still held open. lsof +c 0 +L1
# answer: a process holds an unlinked file open, so its blocks are not freed. kill the holder (and its children - they inherit the fd), do not rm.
inject() {
  mkdir -p /var/lib/lab
  cat > /usr/local/bin/lab-holder <<'H'
#!/bin/bash
exec 3< /var/lib/lab/.held.tmp
sleep 100000
H
  chmod +x /usr/local/bin/lab-holder
  fallocate -l 8G /var/lib/lab/.held.tmp
  nohup /usr/local/bin/lab-holder >/dev/null 2>&1 &
  sleep 2
  rm -f /var/lib/lab/.held.tmp
}
revert() { pkill -x sleep 2>/dev/null; pkill -f lab-holder 2>/dev/null; rm -f /usr/local/bin/lab-holder; sleep 1; }
