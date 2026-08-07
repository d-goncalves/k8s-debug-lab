# id: image-bad-tag
# layer: kubernetes
# symptom: ImagePullBackOff on new pods; old ReplicaSet still serving
# hint: do not guess the correct tag. the old ReplicaSet still has it.
# answer: the image tag has a typo, so the pull fails
inject() { k set image deploy/api api=nginx:1.29-alpin3 -n demo; }
revert() { k set image deploy/api api=nginx:1.29-alpine -n demo; }
