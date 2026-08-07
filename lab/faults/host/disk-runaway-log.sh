# id: disk-runaway-log
# layer: host
# symptom: disk high and CLIMBING while you watch; du can see the file
# hint: measure the number twice. steady growth over minutes means something on a schedule.
# answer: a cron job appends to a log with no rotation. fix the writer AND add rotation; truncate, do not rm.
inject() {
  mkdir -p /var/log/lab
  fallocate -l 12G /var/log/lab/app.log
  cat > /etc/cron.d/lab-writer <<'C'
* * * * * root /usr/bin/dd if=/dev/zero bs=1M count=15 >> /var/log/lab/app.log 2>/dev/null
C
  chmod 644 /etc/cron.d/lab-writer
}
revert() { rm -f /etc/cron.d/lab-writer; rm -rf /var/log/lab; }
