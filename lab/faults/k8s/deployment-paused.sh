# id: deployment-paused
# layer: kubernetes
# symptom: correct changes apply successfully and nothing whatsoever happens
# hint: kubectl rollout status. no error, no event, no new pod.
# answer: the Deployment is paused, so the controller never rolls out template changes
inject() { k rollout pause deployment/web -n demo; }
revert() { k rollout resume deployment/web -n demo 2>/dev/null || true; }
