#!/bin/bash
# Este script se ejecuta tras aplicar al cluster el fichero user-create-objects.yaml
# Obtiene la info y configura un kubeconfig
# fuente: https://devopscube.com/kubernetes-kubeconfig-file/

SERVICE_ACCCOUNT=cloud-op

SA_SECRET_TOKEN=$(kubectl -n default get secret/${SERVICE_ACCCOUNT} -o=go-template='{{.data.token}}' | base64 --decode)
CLUSTER_NAME=$(kubectl config current-context)
CURRENT_CLUSTER=$(kubectl config view --raw -o=go-template='{{range .contexts}}{{if eq .name "'''${CLUSTER_NAME}'''"}}{{ index .context "cluster" }}{{end}}{{end}}')
CLUSTER_CA_CERT=$(kubectl config view --raw -o=go-template='{{range .clusters}}{{if eq .name "'''${CURRENT_CLUSTER}'''"}}"{{with index .cluster "certificate-authority-data" }}{{.}}{{end}}"{{ end }}{{ end }}')
CLUSTER_ENDPOINT=$(kubectl config view --raw -o=go-template='{{range .clusters}}{{if eq .name "'''${CURRENT_CLUSTER}'''"}}{{ .cluster.server }}{{end}}{{ end }}')


cat << EOF > ${SERVICE_ACCCOUNT}-kubeconfig
apiVersion: v1
kind: Config
current-context: ${CLUSTER_NAME}
contexts:
- name: ${CLUSTER_NAME}
  context:
    cluster: ${CLUSTER_NAME}
    user: ${SERVICE_ACCCOUNT}
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    certificate-authority-data: ${CLUSTER_CA_CERT}
    server: ${CLUSTER_ENDPOINT}
users:
- name: ${SERVICE_ACCCOUNT}
  user:
    token: ${SA_SECRET_TOKEN}
EOF
