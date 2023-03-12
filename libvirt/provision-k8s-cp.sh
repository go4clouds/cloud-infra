#!/bin/bash

# ensure running as root
if [ "$(id -u)" != "0" ]; then
  exec sudo "$0" "$@"
fi

if [ "$#" -eq 2 ]; then
  HELM_VER=$1
  HELM_URL=https://get.helm.sh/helm-${HELM_VER}-linux-amd64.tar.gz

  KUBERNETES_VER=$(echo "$2" | sed "s/v//g")
  KUBERNETES_URL=https://storage.googleapis.com/kubernetes-release/release/${2}/bin/linux/amd64/kubectl
fi

if curl --output /dev/null --silent --head --fail "$HELM_URL"; then
  echo "Installing Helm $HELM_VER"
else
  HELM_VER=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | jq -r '.tag_name')
  HELM_URL=https://get.helm.sh/helm-${HELM_VER}-linux-amd64.tar.gz
  echo "Installing Helm $HELM_VER (latest)"
fi

curl -sSL "$HELM_URL" | sudo tar -C /usr/local/bin --strip-components=1 -xzf - linux-amd64/helm

DOWNLOAD_DIR=/usr/local/bin
mkdir -p $DOWNLOAD_DIR

if curl --output /dev/null --silent --head --fail "$KUBERNETES_URL"; then
  echo "Installing Kubernetes $KUBERNETES_VER"
else
  KUBERNETES_VER="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
  KUBERNETES_URL=https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VER}/bin/linux/amd64/kubectl
  echo "Installing Kubernetes $KUBERNETES_VER (latest)"
fi

cd $DOWNLOAD_DIR
curl -L --remote-name-all "${KUBERNETES_URL}"
chmod +x kubectl
