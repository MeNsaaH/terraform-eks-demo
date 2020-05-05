#!/bin/sh

username="admin"
password=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)

argocd login $ARGOCD_URL --username $username --password $password --insecure

# Create the Argocd application using App of Apps structure
argocd app create -f scripts/app.yaml 
