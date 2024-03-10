#!/bin/bash

workers=1

label_bgp () {
  kubectl label nodes cp01 bgp-policy=a
  for (( i=1; i<=$workers; i++)) do
    local NAME="worker0$i"
    kubectl label nodes $NAME bgp-policy=a
  done
}

up_workers () {
  for (( i=1; i<=$workers; i++)) do
    local NAME="worker0$i"
    vagrant up $NAME
  done
}

wait_kube_api () {
  local kube_api=$(yq '.clusters[0].cluster.server' ~/.kube/config)
  until $(curl --output /dev/null --silent --head --insecure $kube_api); do
      printf '.'
      sleep 1
  done
}

wait_cilium_bgp () {
  until [[ $(kubectl wait --for condition=established --timeout=10s crd/ciliumbgppeeringpolicies.cilium.io 2> /dev/null) = "customresourcedefinition.apiextensions.k8s.io/ciliumbgppeeringpolicies.cilium.io condition met" ]]; do
      printf '.'
      sleep 1
  done
}

get_kubeconfig () {
  SSH_IP="$(vagrant address cp01)"
  ssh-keygen -R $SSH_IP -f ~/.ssh/known_hosts
  scp -o StrictHostKeyChecking=no -i /home/$USER/.vagrant.d/insecure_private_keys/vagrant.key.rsa "vagrant@$SSH_IP:.kube/config" /tmp/cp01.yaml
  sh -c "sed -i 's/127\.0\.0\.1/$SSH_IP/' /tmp/cp01.yaml"
  kubecm merge -y /tmp/cp01.yaml
}

vagrant destroy --force
vagrant up 

# Setup Kube CLI
get_kubeconfig
# kubectl config use-context rke2

# # Wait for kube api to be available.
# wait_kube_api

# # Wait for CiliumBGPPeeringPolicy CRD
# wait_cilium_bgp

# # Enable BGP
# # kubectl apply -f rke_files/bgp_metalLB.yaml
# kubectl apply -f rke_files/bgp_control_plane.yaml
# kubectl apply -f rke_files/cilium-ippool.yaml

# # Demo App
# kubectl apply -f rke_files/demo.yaml

# # Start Workers
# up_workers

# # Label nodes 
# # label_bgp
