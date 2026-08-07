# id: service-wrong-port
# layer: kubernetes
# symptom: caller hangs; selector and endpoints look perfect
# hint: EndpointSlice shows the target side only. what port does the CALLER ask for?
# answer: the Service listens on a different port than its clients use
inject() { k patch svc api -n demo --type=merge -p '{"spec":{"ports":[{"port":8080,"targetPort":"http"}]}}'; }
revert() { k patch svc api -n demo --type=merge -p '{"spec":{"ports":[{"port":80,"targetPort":"http"}]}}'; }
