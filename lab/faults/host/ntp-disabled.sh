# id: ntp-disabled
# layer: host
# symptom: nothing broken now; time sync is off and clock will drift
# hint: timedatectl. one line, rules out a whole class of TLS/cert weirdness.
# answer: chronyd is stopped and disabled; clock drift will eventually break TLS and auth
inject() { systemctl stop chronyd 2>/dev/null; systemctl disable chronyd >/dev/null 2>&1; }
revert() { systemctl enable --now chronyd >/dev/null 2>&1; }
