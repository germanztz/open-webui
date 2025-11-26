#!/bin/bash

NAMESPACE=openwebui
KUBEALIAS="kubectl='microk8s kubectl'"

1_install_microk8s() {

    if snap list | grep -q "microk8s"; then
        echo "microk8s already installed"
    else
        sudo snap install microk8s --classic # --channel=1.34
        sudo usermod -a -G microk8s $USER
        mkdir -p ~/.kube
        chmod 0700 ~/.kube

        alias kubectl='microk8s kubectl'
        grep -q "$KUBEALIAS" ~/.bash_aliases || echo "$KUBEALIAS" >> ~/.bash_aliases

        sudo microk8s status --wait-ready
        sudo microk8s enable hostpath-storage
        sudo microk8s enable dns
        sudo microk8s enable community
        sudo microk8s enable ingress
        sudo microk8s enable registry
        sudo microk8s enable nvidia
        # sudo microk8s enable dashboard
        # sudo microk8s enable dashboard-ingress

        sudo microk8s kubectl patch deployment registry -n container-registry --type=json \
            -p='[{
                "op": "replace",
                "path": "/spec/template/spec/volumes/0",
                "value": {
                "name": "registry-data",
                "hostPath": {
                    "path": "/home/ollama/microk8s/registry-data/",
                    "type": "DirectoryOrCreate"
                }
                }
            }]'
        # sudo microk8s kubectl apply -f registry.deploy.yaml 
        sudo microk8s kubectl delete pvc registry-claim -n container-registry
    fi

    microk8s kubectl get pods --all-namespaces
    # sudo microk8s kubectl describe secret -n kube-system microk8s-dashboard-token | grep token
    # echo -e "\n\nhttps://kubernetes-dashboard.127.0.0.1.nip.io\n\n"
    echo "MicroK8s enabled."

}

2_configure_docker_registry() {
    kubectl get svc -n container-registry
    sudo sed -i '0,/{/s//{\n    "insecure-registries": \["localhost:32000"\],/' /etc/docker/daemon.json
    sudo systemctl restart docker
    echo "Registry configured and Docker daemon restarted."
}

3_build_and_push_tts_image() {
    echo "Building and pushing TTS image to MicroK8s registry..."
    (cd ../openai-edge-tts && docker build -t localhost:32000/daimler/openai-edge-tts:1.0.0 .)
    docker push localhost:32000/daimler/openai-edge-tts:1.0.0
    echo "TTS image built and pushed successfully."
    # kubectl scale deployment tts -n $1 --replicas=0
    # kubectl scale deployment tts -n $1 --replicas=1
    # kubectl rollout restart deployment tts -n $1
}

4_build_and_push_openwebui_image() {
    echo "Building and pushing openwebui image to MicroK8s registry..."
    sed -i 's/--platform=\$BUILDPLATFORM //g' ../../Dockerfile
    (cd ../../ && docker build -t localhost:32000/daimler/openwebui:0.6.40 .)
    docker push localhost:32000/daimler/openwebui:0.6.40
    echo "openwebui image built and pushed successfully."
    # kubectl scale deployment openwebui -n $1 --replicas=0
    # kubectl scale deployment openwebui -n $1 --replicas=1
    # kubectl rollout restart deployment openwebui -n $1
}

5_apply_yaml() {
    kubectl create ns $1
    kubectl apply -f . -n=$1
}

1_install_microk8s