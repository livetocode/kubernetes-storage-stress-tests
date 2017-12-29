This script will stress your Kubernetes node by running all versions of nodejs in order to verify the container image garbage collection.

It will first pick the first schedulable node, then grab the list of all the tags of the official node repository, from DockerHub.
Finally, it will execute for each tag a "kubectl run node --version" for the corresponding image.

You can then monitor your disk usage with Prometheus/Grafana and notice the file system grow, then shrink after each cleanup.
You might encounter failing pods when disk is not sufficient. They won't retry since the restart policy is set to Never.

The pods are run within the docker-stress-test namespace, which is always deleted then created at the beginning of each run.

You will see the pods in the kubernetes dashboard, but you might not have access to their logs once the garbage collector flushed the completed containers.

See https://kubernetes.io/docs/concepts/cluster-administration/kubelet-garbage-collection/
