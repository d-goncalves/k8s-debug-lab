# id: oom-memory-limit
# layer: kubernetes
# symptom: CrashLoopBackOff, exit code 137
# hint: describe the pod. Last State, not State.
# answer: the memory limit is far below the working set, so the kernel OOM-kills it
inject() { k patch deploy db -n demo --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/resources/requests/memory","value":"8Mi"},{"op":"replace","path":"/spec/template/spec/containers/0/resources/limits/memory","value":"16Mi"}]'; }
revert() { k patch deploy db -n demo --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/resources/requests/memory","value":"128Mi"},{"op":"replace","path":"/spec/template/spec/containers/0/resources/limits/memory","value":"512Mi"}]'; }
