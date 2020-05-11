apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  labels:
    app: argocd-server-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    external-dns.alpha.kubernetes.io/hostname: "${host_name}"
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/certificate-arn: "${cert_arn}"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
spec:
  rules:
  - host: "${host_name}"
    http:
      paths:
       - path: /*
         backend:
           serviceName: ssl-redirect
           servicePort: use-annotation
       - path: /*
         backend:
            serviceName: argocd-server
            servicePort: https
