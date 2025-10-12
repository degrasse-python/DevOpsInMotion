


### ----- kube-apiserver
# The Kubernetes API server validates and configures data 
# for the api objects which include pods, services, 
# replicationcontrollers, and others. 
# The API Server services REST operations and provides 
# the frontend to the cluster's shared state through 
# which all other components interact.

# location of kube-apiserver.yaml
cat /etc/kubernetes/kube-apiserver.yaml

# check the syslogs
cat /var/log/syslog | grep kube-apiserver

# logs of the pods
cat /var/log/pods/kube-system_kube-scheduler-controlplane_

# netes/manifests/kube-apiserver.yaml: couldn't parse as pod(yaml: 
# line 4: could not find expected ':'), please check config file" 
# path="/etc/kubernetes/manifests/kube-apiserver.yaml"
# 2025-08-20T19:50:45.451090+00:00 controlplane kubelet[1530]: E0820 19:50:45.450758    
# 1530 mirror_client.go:138] "Failed deleting a mirror pod" 
# err="Delete \"https://172.30.1.2:6443/api/v1/namespaces/kube-system/pods/kube-apiserver-controlplane\": 
# dial tcp 172.30.1.2:6443: connect: connection refused" pod="kube-system/kube-apiserver-controlplane"

## ans: check the syntax of the logs.
 