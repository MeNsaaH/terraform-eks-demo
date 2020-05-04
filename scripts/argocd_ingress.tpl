apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  labels:
    app: argocd-server-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/certificate-arn: "${cert_arn}"
    external-dns.alpha.kubernetes.io/hostname: "${host_name}"
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
spec:
  rules:
  - host: "${host_name}"
    http: 
      paths:
      - backend:
          serviceName: argocd-server
          servicePort: https
