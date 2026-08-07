# id: logrotate-disabled
# layer: host
# symptom: a large log, and the timer that should trim it is off
# hint: two separate faults - the timer, and whether the file is even covered by a config
# answer: logrotate.timer is disabled; adding a config is also needed for real coverage
inject() { systemctl disable --now logrotate.timer >/dev/null 2>&1; }
revert() { systemctl enable --now logrotate.timer >/dev/null 2>&1; }
