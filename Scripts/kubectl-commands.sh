### Some common kubectl commands 

## To set your namespace and not keep typing it:
ns=cal-poly-appleby

## To start up the viewer pod (with the same image that will be used for MAPS runs, in this case, so can be used to test things as well)
## You can also replace the yaml file with another pod definition you want to start
kubectl apply -f viewer-pod.yaml -n $ns

## To delet the viewer pod (or any other pod):
kubectl -n $ns delete -f viewer-pod.yaml

## To check the status of your pods/jobs:
kubectl get pods -n $ns --watch

## These two should just be used to transfer a few small files... 
## To copy something from a container's working directly to your kube notebook (need to confirm what this means, I think just to whatever directory you run the command from)
kubectl -n $ns cp viewer-pod:/data/MAPS/file.txt ./file.txt

## To copy something from your computer to your working directory in a pod (opposite direction from above)
kubectl -n $ns cp ./file.txt viewer-pod:/data/MAPS/file.txt 

## To start an interactive shell session (i.e. a command line on a remote pod)
kubectl exec -it viewer-pod -n $ns -- /bin/bash

## To leave the session, just type "exit"
exit