# id: unit-failed
# layer: host
# symptom: systemctl --failed shows a unit down
# hint: status + journal. read two levels: why it fails, and whether it should run at all.
# answer: the ExecStart binary does not exist. decide install vs disable.
inject() {
  cat > /etc/systemd/system/lab-worker.service <<'S'
[Unit]
Description=Lab async worker
[Service]
Type=simple
ExecStart=/usr/local/bin/lab-worker-binary --daemon
Restart=no
[Install]
WantedBy=multi-user.target
S
  systemctl daemon-reload
  systemctl enable lab-worker >/dev/null 2>&1
  systemctl start lab-worker 2>/dev/null || true
}
revert() { systemctl disable --now lab-worker >/dev/null 2>&1; rm -f /etc/systemd/system/lab-worker.service; systemctl daemon-reload; systemctl reset-failed lab-worker 2>/dev/null || true; }
