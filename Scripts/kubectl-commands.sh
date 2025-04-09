### Some common kubectl commands, workflow to run everything below

# First, start terminal / your command line shell and navigate to this repository, i.e.:
cd Documents/R_github/MAPS-Bootstrap/Scripts

## To save your namespace string and not keep typing it:
ns=cal-poly-appleby

## To start up the viewer pod (with the same image that will be used for MAPS runs, in this case, so can be used to test things as well)
## You can also replace the yaml file with another pod definition you want to start
kubectl -n $ns apply -f 00-viewer-pod.yaml 

## This one forces the viewer to run on an ARM64 node, for testing purposes
kubectl -n $ns apply -f 00-viewer-pod-arm.yaml 

## To delet the viewer pod (or any other pod):
kubectl -n $ns delete -f 00-viewer-pod.yaml

## To check the status of your pods/jobs:
kubectl -n $ns get pods --watch

## These two should just be used to transfer a few small files... 
## To copy something from a container's working directly to your kube notebook (need to confirm what this means, I think just to whatever directory you run the command from)
kubectl -n $ns cp viewer-pod:/data/MAPS/file.txt ./file.txt

## To copy something from your computer to your working directory in a pod (opposite direction from above)
kubectl -n $ns cp ./file.txt viewer-pod:/data/MAPS/file.txt 

## To start an interactive shell session (i.e. a command line on a remote pod)
kubectl -n $ns exec -it viewer-pod -- /bin/bash

## To leave the session, just type "exit"
exit

## To look at log files, at least for indexed jobs, you should look at the status to get the full run name for a pod, i.e. 
kubectl logs maps-job-0-jtn29

kubectl -n $ns apply -f 02-indexed-job-maps-test.yaml
kubectl -n $ns delete -f 02-indexed-job-maps-test.yaml

####################
## Running everything from the beginning
kubectl -n $ns apply -f 00-viewer-pod.yaml
kubectl -n $ns apply -f 01A-data-pod-maps.yaml
kubectl -n $ns get pods --watch ## when the above finishes, exit the pod status screen (ctrl-c), then you can delete 01A and run 01B
kubectl -n $ns delete -f 01A-data-pod-maps.yaml
kubectl -n $ns apply -f 01B-data-pod-maps-pt2.yaml
kubectl -n $ns get pods --watch ## when the above finishes, exit the pod status screen (ctrl-c), then you can delete 01B and run 02
kubectl -n $ns delete -f 01B-data-pod-maps-pt2.yaml
## Note: the below command will run all 3.9 MILLION MODELS.  Be sure you want to do this!
kubectl -n $ns apply -f 02-indexed-job-maps.yaml # This one will run everywhere on anything but there seems to be a problem with how that's handeled on the cluster side
kubectl -n $ns apply -f 02-indexed-job-maps-2.yml # This one runs everywhere but is not opportunistic and only tries to run 120 at once
kubectl -n $ns apply -f 02-indexed-job-maps-ex.yaml # This one only runs on CSU-affiliated cluster components

## get a summary of the jobs
kubectl describe jobs/maps-e-job

## Once everything is complete, use this to combine everything together:
kubectl -n $ns apply -f 03-data-combine-pod-maps.yaml
## And delete it when it's done
kubectl -n $ns delete -f 03-data-combine-pod-maps.yaml
## Then transfer the final table from the cluster (it will end up in whatever directory you're in on the command line when you excecute it)
## The viewer pod needs to still be running though, FYI!
kubectl -n $ns cp viewer-pod:/data/MAPS/MAPS_output_table.rds ./MAPS_output_table.rds

## Once you are sure everything's done, be sure to delete the jobs to free up scheduling space on the cluster! (Your pods aren't taking up processing power or memory now, but the logs and scheduler info for all those pods is still in memory on the scheduling pod.)
kubectl -n $ns delete -f 02-indexed-job-maps-ex.yaml
