#!/bin/bash

# ensure running as root
if [ "$(id -u)" != "0" ]; then
  exec sudo "$0" "$@"
fi

if [ "$#" -eq 3 ]; then
  CONTAINERD_VER=$(echo "$1" | sed "s/v//g") #Delete "v" from string
  CONTAINERD_URL=https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VER}/cri-containerd-cni-${CONTAINERD_VER}-linux-amd64.tar.gz

  KUBERNETES_VER=$(echo "$2" | sed "s/v//g")
  KUBERNETES_URL=https://storage.googleapis.com/kubernetes-release/release/${2}/bin/linux/amd64/{kubeadm,kubelet}  
fi

if curl --output /dev/null --silent --head --fail "$CONTAINERD_URL"; then
  echo "Installing Containerd v$CONTAINERD_VER"
else
  CONTAINERD_VER=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest | jq -r '.tag_name')
  CONTAINERD_URL=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest | jq -r '.assets[] | select(.browser_download_url | contains("cri-containerd-cni") and endswith("linux-amd64.tar.gz")) | .browser_download_url')
  echo "Installing Containerd $CONTAINERD_VER (latest)"
fi

curl -L "${CONTAINERD_URL}" | sudo tar --no-overwrite-dir -C / -xz

systemctl enable containerd
systemctl start containerd

CNI_VERSION=$(curl -s https://api.github.com/repos/containernetworking/plugins/releases/latest | jq -r '.tag_name')
ARCH="amd64"
mkdir -p /opt/cni/bin
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz" | sudo tar -C /opt/cni/bin -xz

DOWNLOAD_DIR=/usr/local/bin
mkdir -p $DOWNLOAD_DIR

if curl --output /dev/null --silent --head --fail "$KUBERNETES_URL"; then
  echo "Installing Kubernetes $KUBERNETES_VER"
else
  KUBERNETES_VER="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
  KUBERNETES_URL=https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VER}/bin/linux/amd64/{kubeadm,kubelet}
  echo "Installing Kubernetes $KUBERNETES_VER (latest)"
fi

cd $DOWNLOAD_DIR
curl -L --remote-name-all "${KUBERNETES_URL}"
chmod +x {kubeadm,kubelet}

RELEASE_VERSION=$(curl -s https://api.github.com/repos/kubernetes/release/releases/latest | jq -r '.name')
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

systemctl enable kubelet

sudo sh -c "echo $3 k8scp >> /etc/hosts"
