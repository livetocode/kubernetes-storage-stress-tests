#!/bin/bash
# print commands
#set -x 

# Install missing tools
which jq &> /dev/null
if [ $? -ne 0 ]; then
    brew install jq
fi
which docker-ls &> /dev/null
if [ $? -ne 0 ]; then
    brew install docker-ls
fi

# parameters
#Tooling options: docker | kubernetes
#TOOLING=docker
TOOLING=kubernetes
KUBERNETES_NAMESPACE=docker-stress-test
# Find the first node that can be scheduled for pods
KUBERNETES_NODE=`kubectl get nodes -o json|jq -r '.items[] | select(.spec.unschedulable != true) | .metadata.name' | head -1`
#KUBERNETES_DEBUG="--dry-run"
DOCKER_REPOSITORY=library/node
WAIT_TIME=180s

initKubernetes() {
    kubectl delete ns $KUBERNETES_NAMESPACE
    sleep 10s
    kubectl create ns $KUBERNETES_NAMESPACE
    if [ -z "$KUBERNETES_NODE" ]; then
        echo "Could not find a schedulable kubernetes node!"
        exit 1
    fi
    echo "Scheduling all pods on node $KUBERNETES_NODE"
}

runInKubernetes() {
    POD_NAME=$1
    IMAGE_NAME=$2
    echo "create kubernetes pod $POD_NAME to run image $IMAGE_NAME"
    cat <<EOF | kubectl create $KUBERNETES_DEBUG -f -
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  namespace: $KUBERNETES_NAMESPACE
spec:
  restartPolicy: Never
  nodeName: $KUBERNETES_NODE
  containers:
  - name: test
    image: $IMAGE_NAME
    imagePullPolicy: IfNotPresent
    command: ["node"]
    args: ["--version"]
EOF
}

if [ "$TOOLING" == "kubernetes" ]; then
   initKubernetes
fi

# get a list of images
RUN_COUNT=0
docker-ls tags $DOCKER_REPOSITORY --json | jq -r '.Tags[]' |  while read tag
do
    RUN_COUNT=$((RUN_COUNT+1))
    echo "---------------------------------------------------------------------------------------------------------"
    echo `date` "- Step $RUN_COUNT - test $DOCKER_REPOSITORY/$tag"
    # run a docker command for each image
    if [ "$TOOLING" == "kubernetes" ]; then
        #kubectl run TEST-$RUN_COUNT -n $KUBERNETES_NAMESPACE --image=$DOCKER_REPOSITORY:$tag --restart=Never -- node --version
        runInKubernetes test-$RUN_COUNT $DOCKER_REPOSITORY:$tag
    else
        docker run $DOCKER_REPOSITORY:$tag node --version
        # print disk usage
        df -H
    fi

    # wait before running the next command
    sleep $WAIT_TIME
done
echo "---------------------------------------------------------------------------------------------------------"
echo `date` "- Done"
