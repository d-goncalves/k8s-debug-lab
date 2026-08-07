# id: kubeconfig-world-readable
# layer: host
# symptom: nothing broken; a credential file is world-readable
# hint: is anything here NOT how it should be? check permissions on cluster credentials.
# answer: the k3s kubeconfig (which contains an admin client key) is mode 644, so any local user is cluster-admin
inject() { chmod 644 /etc/rancher/k3s/k3s.yaml; }
revert() { chmod 600 /etc/rancher/k3s/k3s.yaml; }
