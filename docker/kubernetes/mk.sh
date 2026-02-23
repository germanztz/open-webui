#!/bin/bash

NAMESPACE=ia
read -r -d '' aliases <<'EOF'
alias kubectl='microk8s kubectl'
alias k='microk8s kubectl'
alias klogs='multitail -ci green --label "comfyui: " -L "microk8s kubectl logs -f deployment.apps/comfyui"  -ci blue --label "tts: " -L "microk8s kubectl logs -f deployment.apps/tts"  -ci yellow --label "openwebui: " -L "microk8s kubectl logs -f deployment.apps/openwebui"  -ci red  --label "ollama: "  -L "microk8s kubectl logs -f deployment.apps/ollama"'
alias kpurge='microk8s kubectl get pods --no-headers | grep -v "Running" | cut -f1 -d\  | xargs -r microk8s kubectl delete pod'
alias ollama='microk8s kubectl exec deploy/ollama -- ollama'
alias ollamaps='watch microk8s kubectl exec deploy/ollama -- ollama ps'
EOF


1_install_microk8s() {

    if snap list | grep -q "microk8s"; then
        echo "microk8s already installed"
    else
        sudo snap install microk8s --classic # --channel=1.34
        sudo usermod -a -G microk8s $USER
        mkdir -p ~/.kube
        chmod 0700 ~/.kube

        grep -q "kubectl" ~/.bash_aliases || echo "$aliases" >> ~/.bash_aliases

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

3_build_and_push_tts_image() { IMAGE_VERSION="$1" 
    echo "Building and pushing TTS image to MicroK8s registry..."
    (cd ../openai-edge-tts && docker build -t localhost:32000/daimler/openai-edge-tts:$IMAGE_VERSION .)
    docker push localhost:32000/daimler/openai-edge-tts:$IMAGE_VERSION
    # microk8s ctr images tag localhost:32000/daimler/openai-edge-tts:$IMAGE_VERSION localhost:32000/daimler/openai-edge-tts:latest
    (microk8s ctr images list; docker images) | grep openai-edge-tts
    echo "TTS image built and pushed successfully."
    echo "Update tts-deploy.yaml image to $IMAGE_VERSION and run 'k apply -f tts-deploy.yaml' "
}

4_build_and_push_openwebui_image() { IMAGE_VERSION="$1" 
    echo "Building and pushing openwebui image to MicroK8s registry..."
    sed -i 's/--platform=\$BUILDPLATFORM //g' ../../Dockerfile
    (cd ../../ && docker build -t localhost:32000/daimler/openwebui:$IMAGE_VERSION .)
    docker push localhost:32000/daimler/openwebui:$IMAGE_VERSION
    # microk8s ctr images tag localhost:32000/daimler/openwebui:$IMAGE_VERSION localhost:32000/daimler/openwebui:latest
    (microk8s ctr images list; docker images) | grep openwebui
    echo "openwebui image built and pushed successfully."
    echo "Update openwebui-deploy.yaml image to $IMAGE_VERSION and run 'k apply -f openwebui-deploy.yaml' "
}

4_build_and_push_comfyui_image() { 
    echo "Building and pushing comfyui image to MicroK8s registry..."
    (cd ../ComfyUI-Docker && docker build . -t localhost:32000/daimler/comfyui:0.3.75)
    docker push localhost:32000/daimler/comfyui:0.3.75
    echo "TTS image built and pushed successfully."
    kubectl rollout restart deploy comfyui 
}

5_apply_yaml() { NAMESPACE="$1"
    kubectl create ns $NAMESPACE
    kubectl apply -f . -n=$NAMESPACE
}

delete_image(){ IMAGE_NAME="$1"
    microk8s ctr image rm --sync $IMAGE_NAME
    docker image rm --force $IMAGE_NAME
    microk8s ctr image list | grep localhost
}

purge_pods() {
    microk8s kubectl get pods --no-headers | grep -v "Running" | cut -f1 -d\  | xargs -r microk8s kubectl delete pod
    echo "Purging completed."
    microk8s kubectl get pods
}


# Main execution logic
if [ $# -eq 0 ]; then
    echo "Examples"
    echo "$0 1_install_microk8s"
    echo "$0 4_build_and_push_openwebui_image 0.6.43"
    echo " "
    purge_pods
else
    func_name=$1
    shift
    "$func_name" "$@"
fi
