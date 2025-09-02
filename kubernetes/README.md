# Kubernetes manifests

## Description
In this README, I will explain the Kubernetes manifests, which are not that many, but work as expected and still add another layer of complexity to the project.

For context, using Kubernetes means that now the containers run on pods, which are virtual spots for containers in which one or multiple containers can run simultaneously, which comes in handy when the app uses a microservices architecture and we don't want one error in one part of the app to stop the other parts of the app from running, which are called microservices as the name indicates. 

Since the pod is virtual, it can be assigned to worker nodes, which are machines that are available to run those pods, real machines, and they can run one or multiple pods. In this project, I use EC2 instances as worker nodes, which means that I start 2 EC2 instances, and the only pod of the cluster can be scheduled to any of the EC2 instances, which is great because if a machine fails, the pod can be restarted in other healthy machine.

Pods have their own dynamic IPs, while the worker nodes have their own static IPs, and to route traffic to the pods, it is necessary to use a Service, which is a Kubernetes resource that can work as a load balancer, routing traffic to the worker nodes because these ones have static IPs, and from there the kube-proxy routes traffic to the pods in that worker node, because as I mentioned earlier, you can have multiple pods in the same node.

I maintained this project simple since it just includes a REST API, but if it had a microservices architecture, I'd need to use an Ingress, which is another Kubernetes resource that works as a load balancer for the different microservices in an app, and it goes before the Service, so the Ingress tells to the Service which microservice to route the traffic.

## Helm Charts
As I mentioned in the previous README, Helm is the package manager that allows me to send the Kubernetes manifests in their final form to the EKS cluster, reason why I have the Chart.yaml and values.yaml files.

## Deployment manifest
In this manifest, I set replicas to 1 in the Deployment resource since I only had 2 EC2 instances, so if one doesn't start, the pod can be scheduled in another one in another AZ. As you can see, I use the values.yaml file to pass the image and the environment variables to the container, so that it fetches the latest image that passes all the quality and security controls from the CI/CD pipeline and has all the variables it needs to run the app correctly.

Another thing too is the connection to the database, whose URL can only be obtained after creating the RDS instance, so in the CI/CD pipeline I take the database URL and pass it to Helm so that it passes it to the container in runtime.

In the ports part, I put "http" and then use "tcp" because Kubernetes doesn't support HTTP, but I put it symbolically. I also include a limit in the resources, which are very limited because I use t3.micro for the EC2 instances, so I try to limit as much as possible the resources allocated to each container.

Finally, I included liveness and readiness checks, to make sure the container's health is checked multiple times before restarting the container.

## Service manifest
As I explained earlier, in this project the Service resource works as a load balancer, which listens to port 80 (HTTP) and forwards the requests to port 8000 (pod).