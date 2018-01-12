# Description

This script will stress your Kubernetes node by running all versions of nodejs in order to verify the garbage collection or the container images.

See https://kubernetes.io/docs/concepts/cluster-administration/kubelet-garbage-collection/

# Steps

It will first pick the first schedulable node, then grab the list of all the tags of the official node repository, from DockerHub.
Finally, it will execute for each tag a "node --version" for the corresponding image.

# Observe

You can then monitor your disk usage with Prometheus/Grafana and notice the file system grow, then shrink after each cleanup.
You might encounter failing pods when disk is not sufficient. They won't retry since the restart policy is set to Never.

# Warning

The pods are run within the *docker-stress-test* namespace, which is always **deleted** then created at the beginning of each run.

You will see the pods in the kubernetes dashboard, but you might not have access to their logs once the garbage collector flushed the completed containers.

# Requirements

- kubectl / docker
- jq
- docker-ls

# Start

Ensure that your KUBECONFIG var is properly set and verify the options with the script (namespace, sleep period, tooling...), then run:

```
bash run-many-different-docker-images.sh
```


# Issues

## Node crash

We experienced node reboots after a few gigs of docker images. 

We had to upgrade the kernel to fix this.

## Garbage collector won't work

We noticed that the data was not garbaged collected because we used either btrfs or xfs with overlay which were not properly monitored by the cadvisor verion of the kubelet.