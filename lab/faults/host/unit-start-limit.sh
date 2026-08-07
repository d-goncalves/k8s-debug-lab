# id: unit-start-limit
# layer: host
# symptom: failed unit; systemctl start refuses with "start request repeated too quickly"
# hint: read the refusal. the counter must be cleared before it will start again.
# answer: it burned through StartLimitBurst and needs systemctl reset-failed (real fix: the script exits 1)
inject() {
  cat > /usr/local/bin/lab-flapper <<'F'
#!/bin/bash
echo "lab-flapper starting"
exit 1
F
  chmod +x /usr/local/bin/lab-flapper
  cat > /etc/systemd/system/lab-flapper.service <<'S'
[Unit]
Description=Lab flapping worker
StartLimitIntervalSec=60
StartLimitBurst=3
[Service]
Type=simple
ExecStart=/usr/local/bin/lab-flapper
Restart=always
RestartSec=1
[Install]
WantedBy=multi-user.target
S
  systemctl daemon-reload
  systemctl enable lab-flapper >/dev/null 2>&1
  systemctl start lab-flapper 2>/dev/null || true
  sleep 10
}
revert() { systemctl disable --now lab-flapper >/dev/null 2>&1; rm -f /etc/systemd/system/lab-flapper.service /usr/local/bin/lab-flapper; systemctl daemon-reload; systemctl reset-failed lab-flapper 2>/dev/null || true; }
