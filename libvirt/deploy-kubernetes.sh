#!/bin/bash
#shellcheck disable=SC2145,SC2016

set -eux

log()   { (>&1 echo -e "$@") ; }
info()  { log "[ INFO ] $@" ; }
error() { (>&2 echo -e "[ ERROR ] $@") ;}

if [ -z "${TR_MASTER_IPS}" ] || [ -z "${TR_USERNAME}" ]; then
    error '$TR_MASTER_IPS $TR_USERNAME must be specified'
    exit 1
fi

sleep 5

if [ $CNI_PLUGIN == "cilium" ]; then
    CILIUM_VERSION=$(curl -s https://api.github.com/repos/cilium/cilium/releases/latest | jq -r '.tag_name' | sed -e 's/^v//')
    CNI_INSTALL="helm repo add cilium https://helm.cilium.io/
    helm install cilium cilium/cilium --version ${CILIUM_VERSION} --namespace kube-system --set kubeProxyReplacement=disabled"
else
    CNI_INSTALL="kubectl apply -f https://projectcalico.docs.tigera.io/manifests/calico.yaml"
fi

info "### Run following commands to bootstrap Kubernetes cluster:\\n"

i=0
for MASTER in $TR_MASTER_IPS; do
    if [ $i -eq "0" ]; then
        # As temporary fix we have to disable kubeProxyReplacement for Cilium, https://github.com/cilium/cilium/pull/16084
        ssh -o 'StrictHostKeyChecking no' -l ${TR_USERNAME} ${MASTER} /bin/bash <<-EOF
          set -eux
          sudo kubeadm init --cri-socket /run/containerd/containerd.sock --control-plane-endpoint k8scp:6443 --upload-certs | tee kubeadm-init.log
          mkdir -p /home/${TR_USERNAME}/.kube
          sudo cp /etc/kubernetes/admin.conf /home/${TR_USERNAME}/.kube/config
          sudo chown ${TR_USERNAME}:users /home/${TR_USERNAME}/.kube/config
          eval "$CNI_INSTALL"
EOF

        export KUBEADM_MASTER_JOIN=`ssh -o 'StrictHostKeyChecking no' -l ${TR_USERNAME} ${MASTER} tail -n12 kubeadm-init.log | head -n3`
        export KUBEADM_WORKER_JOIN=`ssh -o 'StrictHostKeyChecking no' -l ${TR_USERNAME} ${MASTER} tail -n2 kubeadm-init.log`
    else
        ssh -o 'StrictHostKeyChecking no' -l ${TR_USERNAME} ${MASTER} /bin/bash <<-EOF
          set -eux
          sudo ${KUBEADM_MASTER_JOIN}
          mkdir -p /home/${TR_USERNAME}/.kube
          sudo cp /etc/kubernetes/admin.conf /home/${TR_USERNAME}/.kube/config
          sudo chown ${TR_USERNAME}:users /home/${TR_USERNAME}/.kube/config
EOF
    fi
    ((++i))
done

i=0
for WORKER in $TR_WORKER_IPS; do
    ssh -o 'StrictHostKeyChecking no' -l ${TR_USERNAME} ${WORKER} /bin/bash <<-EOF
      set -eux
      sudo ${KUBEADM_WORKER_JOIN}
EOF
    ((++i))
done

scp -o 'StrictHostKeyChecking no' ${TR_USERNAME}@${MASTER}:/home/${TR_USERNAME}/.kube/config ./admin.conf
export KUBECONFIG=`pwd`/admin.conf

#RELEASE=$(curl -sSL https://dl.k8s.io/release/stable.txt)
RELEASE=$KUBERNETES_VER
curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/kubectl
chmod +x kubectl
./kubectl get nodes

log ""
log "WARNING!!! To start with K8s cluster please run following command:"
log "export KUBECONFIG=`pwd`/admin.conf"
log "./kubectl get nodes"
log ""
