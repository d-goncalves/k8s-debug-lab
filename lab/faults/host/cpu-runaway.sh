# id: cpu-runaway
# layer: host
# symptom: load average high; one process pegged at 100%
# hint: ps aux --sort=-%cpu. systemctl status <pid> tells you if a unit owns it.
# answer: a stray busy-loop process, not owned by any unit. kill it; SIGTERM before SIGKILL.
inject() {
  cat > /usr/local/bin/lab-spin <<'X'
#!/bin/bash
while :; do :; done
X
  chmod +x /usr/local/bin/lab-spin
  nohup /usr/local/bin/lab-spin >/dev/null 2>&1 &
}
revert() { pkill -f lab-spin 2>/dev/null; rm -f /usr/local/bin/lab-spin; }
