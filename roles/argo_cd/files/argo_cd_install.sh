#!/bin/bash

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

HASHED_ADMIN_PASS=$(htpasswd -nbBC 10 "" "$ARGO_ADMIN_PASS" | tr -d ':\n')

helm upgrade --install argocd argo/argo-cd \
  --namespace "{{ k3s.argocd.namespace }}" \
  --create-namespace \
  --set server.service.type=NodePort \
  --set server.service.nodePortHttps="{{ k3s.argocd.https_node_port }}" \
  --set server.service.nodePortHttp="{{ k3s.argocd.http_node_port }}" \
  --set-string "configs.repositories.repo1.url={{ k3s.argocd.connected_repo }}" \
  --set-string "configs.repositories.repo1.type=git" \
  --set-string "configs.repositories.repo1.name=connected-repo" \
  --set-string "configs.repositories.repo1.sshPrivateKey=$ARGO_SSH_PRIVATE_KEY" \
  --set-string "configs.secret.argocdServerAdminPassword=$HASHED_ADMIN_PASS"
