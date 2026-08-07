# id: rogue-uid0-account
# layer: host
# symptom: nothing broken; an extra account has UID 0
# hint: grep ":0:0:" /etc/passwd. UID 0 IS root, regardless of the name.
# answer: a second UID 0 account is a full root backdoor. contain and preserve, do not just userdel.
inject() { id lab-backup >/dev/null 2>&1 || useradd -o -u 0 -g 0 -M -s /bin/bash -c "Lab backup account" lab-backup; }
revert() { userdel -f lab-backup 2>/dev/null || true; }
