# id: unit-masked
# layer: host
# symptom: a service that should run is not running, and start silently does nothing
# hint: NOT in --failed. systemctl list-unit-files --state=masked
# answer: the unit is masked (symlinked to /dev/null) and cannot start until unmasked
inject() { systemctl mask chronyd >/dev/null 2>&1; systemctl stop chronyd 2>/dev/null || true; }
revert() { systemctl unmask chronyd >/dev/null 2>&1; systemctl enable --now chronyd >/dev/null 2>&1; }
