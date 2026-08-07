# id: service-wrong-targetport
# layer: kubernetes
# symptom: endpoints populated and ready, connections still fail
# hint: the EndpointSlice shows the resolved port. what does the container listen on?
# answer: targetPort forwards to a port nothing is listening on
inject() { k patch svc api -n demo --type=merge -p '{"spec":{"ports":[{"port":80,"targetPort":8080}]}}'; }
revert() { k patch svc api -n demo --type=merge -p '{"spec":{"ports":[{"port":80,"targetPort":"http"}]}}'; }
