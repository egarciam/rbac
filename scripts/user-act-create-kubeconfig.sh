#!/bin/bash
# Este script se ejecuta tras aplicar al cluster el fichero user-create-objects.yaml
# Obtiene la info y configura un kubeconfig
# fuente: https://devopscube.com/kubernetes-kubeconfig-file/

# Function to print usage
print_usage() {
    echo "Usage: $0 [-h] -s <sa> [-n <ns>]"
    echo "Description: This script requires the service account (sa) parameter specified with -sa and an optional namespace (ns) parameter specified with -ns."
    echo "Options:"
    echo "  -h         Print this help message"
    echo "  -s <sa>   Specify the service account"
    echo "  -n <ns>   Specify the namespace (optional, default is 'default')"
    exit 1
}

if [ $# -lt 1 ]; then
   print_usage
fi

# Parse command-line options
while getopts "hs:n:" opt; do
    case ${opt} in
        h )
            print_usage
            ;;
        s )
            sa=$OPTARG
            ;;
        n )
            ns=$OPTARG
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            print_usage
            ;;
    esac
done

# Check if the service account is provided
if [ -z "$sa" ]; then
    echo "Error: Service account (-s) parameter is required."
    print_usage
fi

# Set the namespace to default if not provided
if [ -z "$ns" ]; then
    ns="default"
fi

# Your script logic goes here
echo "Service Account: $sa"
echo "Namespace: $ns"


SERVICE_ACCCOUNT=$sa

SA_SECRET_TOKEN=$(kubectl -n default get secret/${SERVICE_ACCCOUNT} -o=go-template='{{.data.token}}' | base64 --decode)
CLUSTER_NAME=$(kubectl config current-context)
CURRENT_CLUSTER=$(kubectl config view --raw -o=go-template='{{range .contexts}}{{if eq .name "'''${CLUSTER_NAME}'''"}}{{ index .context "cluster" }}{{end}}{{end}}')
CLUSTER_CA_CERT=$(kubectl config view --raw -o=go-template='{{range .clusters}}{{if eq .name "'''${CURRENT_CLUSTER}'''"}}"{{with index .cluster "certificate-authority-data" }}{{.}}{{end}}"{{ end }}{{ end }}')
CLUSTER_ENDPOINT=$(kubectl config view --raw -o=go-template='{{range .clusters}}{{if eq .name "'''${CURRENT_CLUSTER}'''"}}{{ .cluster.server }}{{end}}{{ end }}')


cat << EOF > ${SERVICE_ACCCOUNT}-${CURRENT_CLUSTER}-kubeconfig
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
