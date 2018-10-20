---
layout: post
current: post
cover: assets/images/2018-10-07-set-sail-a-production-ready-istio-adapter/banner.jpg
navigation: True
title: Set sail a production-ready Istio Adapter
date: 2018-10-07 11:49:00
tags: [Distributed Systems]
class: post-template
subclass: 'post tag-distributed-systems'
author: venilnoronha
---

So, you've walked through the Istio Mixer Adapter [guide](https://github.com/istio/istio/wiki/Mixer-Out-Of-Process-Adapter-Dev-Guide) and want to now publish your own **amazing** adapter? This post will run you through the process of setting sail your own adapter on the seas of production.

<img src="assets/images/2018-10-07-set-sail-a-production-ready-istio-adapter/istio-logo.svg" alt="Istio" style="width: 150px;" />

## Introduction

Depending on your knowledge of [Go](https://golang.org/), [Protobufs](https://developers.google.com/protocol-buffers/), [gRPC](https://grpc.io/), [Istio](https://istio.io/), [Docker](https://www.docker.com/) and [Kubernetes](https://kubernetes.io/), you may find the process of publishing an Istio Mixer Adapter from being easy to tasking. This post assumes that you have some experience with these technologies, and that you've been able to complete at least one of the walk-throughs from the Istio Wiki.

For the purpose of this post, I'd be talking about building an Istio Mixer Adapter that consumes [Metrics](https://preliminary.istio.io/docs/reference/config/policy-and-telemetry/templates/metric/). Here's a run-down of the steps we'll be looking at:

1. The Istio Mixer - Adapter Interface Architecture
2. Creating An Out-Of-Tree Mixer Adapter
3. Publishing The Adapter To Docker Hub
4. Writing Kubernetes Config For The Adapter
5. Deploying And Testing The Adapter With Istio

Again, I will try my best to render all the important details in this post to bring your new adapter to life.

## The Istio Mixer - Adapter Interface Architecture

Let's first have a look at how the adapter is to be interfaced with the Istio Mixer. Kubernetes abstracts the interfacing to some extent; however, it's important for us to understand this, at least, in a little detail.

![The Architecture](assets/images/2018-10-07-set-sail-a-production-ready-istio-adapter/architecture.svg)

Here's a brief description of each of the elements in the architecture above.

* **Microservice** is a user application that is deployed over Istio
* **Proxy** is the Istio component, i.e. [Envoy Proxy](https://www.envoyproxy.io/), that controls the network communication in the [Service Mesh](https://en.wikipedia.org/wiki/Microservices#Service_Mesh)
* **Mixer** refers to the Istio component that receives metric (and other) data from the Proxy and forwards it to other components, in this case, the Adapter
* **Adapter** is the application we're building which consumes metric data from the Mixer over a gRPC channel
* **Operator** is an actor who is responsible for configuring the deployment, in this case, Istio and the Adapter

The important thing to note here is that each of these components run as seperate processes, and that they may be distributed over a network. Also, Mixer establishes a gRPC channel with the Adapter for the purpose of providing it with user configuration and metric data.

## Creating An Out-Of-Tree Mixer Adapter

For brevity, I'm relying on the Istio [Mixer Out Of Tree Adapter Walkthrough](https://github.com/istio/istio/wiki/Mixer-Out-of-Tree-Adapter-Walkthrough) for you to follow and build a working out-of-tree mixer adapter. Below is an outline of the steps you're required to follow to create a working out-of-tree Istio Mixer Adapter that consumes metric data.

1. Create `config.proto` to represent the Adapter configuration
2. Create the `mygrpcadapter.go` implementation which handles the `HandleMetric(context.Context, *metric.HandleMetricRequest) (*v1beta11.ReportResult, error)` gRPC API call
3. Generate the configuration files via `go generate ./...`
4. Create `main.go` which creates the gRPC server and listens to API calls
5. Write the `sample_operator_config.yaml` for the adapter
6. Test and validate your adapter by starting a local Mixer process
7. Configure the out-of-tree project
8. Vendor the necessary dependencies (using [Go Modules](https://github.com/golang/go/wiki/Modules), [Glide](https://glide.sh/), [Dep](https://golang.github.io/dep/), etc. this time)
9. Build and test the out-of-tree adapter by starting a local Mixer process

## Publishing The Adapter To Docker Hub

Once you have the `myootadapter` project set up and tested locally, it's time to build and publish the Adapter to a repository like [Docker Hub](https://hub.docker.com/). Please perform the following steps before proceeding.

1. Move the contents of the `mygrpcadapter/testdata/` directory to under `operatorconfig/`
2. Create a file named `Dockerfile` to hold the steps to create the Docker image
3. Finally, create a file named `mygrpcadapter-k8s.yaml` under `operatorconfig/` which we'll use later to deploy the Adapter via Kubernetes

Once you've followed these steps, you should have a project structure like below.

```shell
── myootadapter
   ├── Dockerfile
   ├── glide.lock # Depending on your vendoring tool,
   ├── glide.yaml # you'd have some files like these.
   ├── mygrpcadapter
   │   ├── cmd
   │   │   └── main.go
   │   ├── config
   │   │   ├── config.pb.go
   │   │   ├── config.proto
   │   │   ├── config.proto_descriptor
   │   │   ├── mygrpcadapter.config.pb.html
   │   │   └── mygrpcadapter.yaml
   │   └── mygrpcadapter.go
   └── operatorconfig
       ├── attributes.yaml
       ├── metrictemplate.yaml
       ├── sample_operator_config.yaml
       ├── mygrpcadapter-k8s.yaml
       └── mygrpcadapter.yaml
```

Let's now build the Docker image and publish it to Docker Hub.

### Building The Docker Image

The [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/) pattern can be used to build the Docker image. Copy the following contents to your `Dockerfile`.

```dockerfile
FROM golang:1.11 as builder
WORKDIR /go/src/github.com/username/myootadapter/
COPY ./ .
RUN CGO_ENABLED=0 GOOS=linux \
    go build -a -installsuffix cgo -v -o bin/mygrpcadapter ./mygrpcadapter/cmd/

FROM alpine:3.8
RUN apk --no-cache add ca-certificates
WORKDIR /bin/
COPY --from=builder /go/src/github.com/username/myootadapter/bin/mygrpcadapter .
ENTRYPOINT [ "/bin/mygrpcadapter" ]
CMD [ "8000" ]
EXPOSE 8000
```

The `CMD [ "8000" ]` line tells Docker to pass `8000` as an argument to `/bin/mygrpcadapter` which is defined by the `ENTRYPOINT [ "/bin/mygrpcadapter" ]` line. Since we fix the gRPC listener port to `8000` here, we must also update the `sample_operator_config.yaml` to reflect the same. We do that by replacing `address: "{ADDRESS}"` with `address: mygrpcadapter:8000`.

Let's also update the `file_path` to store the output on a volume which we'll create later. Update `file_path: "out.txt"` to `file_path: "/volume/out.txt"`. You'd then land up with a Handler configuration like below.

```yaml
apiVersion: "config.istio.io/v1alpha2"
kind: handler
metadata:
 name: h1
 namespace: istio-system
spec:
 adapter: mygrpcadapter
 connection:
   address: "mygrpcadapter:8000"
 params:
   file_path: "/volume/out.txt"
```

Now, we run the following command from the `myootadapter` directory to build and tag the Docker image.

```shell
docker build -t dockerhub-username/mygrpcadapter:latest .
```

### Publishing The Image To Docker Hub

First, login to Docker Hub via your terminal.

```shell
docker login
```

Next, push the image using the following command.

```shell
docker push dockerhub-username/mygrpcadapter:latest
```

## Writing Kubernetes Config For The Adapter

Let's now fill out the configuration for deploying the adapter via Kubernetes. Copy the following configuration to the `mygrpcadapter-k8s.yaml` file which we created earlier.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mygrpcadapter
  namespace: istio-system
  labels:
    app: mygrpcadapter
spec:
  type: ClusterIP
  ports:
  - name: grpc
    protocol: TCP
    port: 8000
    targetPort: 8000
  selector:
    app: mygrpcadapter
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: mygrpcadapter
  namespace: istio-system
  labels:
    app: mygrpcadapter
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: mygrpcadapter
      annotations:
        sidecar.istio.io/inject: "false"
        scheduler.alpha.kubernetes.io/critical-pod: ""
    spec:
      containers:
      - name: mygrpcadapter
        image: dockerhub-username/mygrpcadapter:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
        volumeMounts:
        - name: transient-storage
          mountPath: /volume
      volumes:
      - name: transient-storage
        emptyDir: {}
```

The above configuration defines a simple service with just a single replica which is created out of the image at `dockerhub-username/mygrpcadapter:latest`. The service can be referred to by name as `mygrpcadapter` and can be addressed to via port `8000`. That's how the `address: "mygrpcadapter:8000"` configuration  in `sample_operator_config.yaml` refers to this particular deployment.

Also, notice these special annotations:

```yaml
annotations:
  sidecar.istio.io/inject: "false"
  scheduler.alpha.kubernetes.io/critical-pod: ""
```

This tells the Kubernetes scheduler to not inject the Istio Proxy sidecar if automatic injection is in place. We do that because we don't really need a Proxy in front of our Adapter. Also, the second annotation marks this pod as _critical_ for the system.

We also create a transient volume named `transient-storage` which is used for storing the Adapter output i.e. the `out.txt` file. The following snippet from the above configuration enables us to do that.

```yaml
    volumeMounts:
    - name: transient-storage
      mountPath: /volume
  volumes:
  - name: transient-storage
    emptyDir: {}
```

## Deploying And Testing The Adapter With Istio

Again, for brevity, I'm relying on the project documentation for you to [deploy Istio](https://istio.io/docs/setup/kubernetes/quick-start/), [run the Bookinfo sample application](https://istio.io/docs/examples/bookinfo/) and to [determine the ingress IP and port](https://istio.io/docs/tasks/traffic-management/ingress/#determining-the-ingress-ip-and-ports).

### Deploying The Adapter

We can now deploy the Adapter via Kubernetes like so:

```shell
kubectl apply -f operatorconfig/
```

This should deploy the `mygrpcadapter` service under the `istio-system` namespace. You can verify this by executing the following command.

```shell
kubectl get pods -n istio-system
```

This would print a log like below.

```
NAME                                       READY     STATUS        RESTARTS   AGE
istio-citadel-75c88f897f-zfw8b             1/1       Running       0          1m
istio-egressgateway-7d8479c7-khjvk         1/1       Running       0          1m
.
.
mygrpcadapter-86cb6dd77c-hwvqd             1/1       Running       0          1m
```

You could also check the Adapter logs by executing the following command.

```shell
kubectl logs mygrpcadapter-86cb6dd77c-hwvqd -n istio-system
```

It should then print the following log.

```
listening on "[::]:8000"
```

### Testing The Adapter

Execute the following command in your terminal, or hit the `http://${GATEWAY_URL}/productpage` URL in your browser to send a request to the Bookinfo deployment.

```shell
curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
```

Verify the output in the `/volume/out.txt` file by accessing the Adapter container.

```shell
kubectl exec mygrpcadapter-86cb6dd77c-hwvqd cat /volume/out.txt
```

You should see an output like below.

```
HandleMetric invoked with:
  Adapter config: &Params{FilePath:/volume/out.txt,}
  Instances: 'i1metric.instance.istio-system':
  {
		Value = 1235
		Dimensions = map[response_code:200]
  }
```

## Conclusion

Istio provides a standard mechanism to manage and observe microservices in the cloud. Mixer enables developers to easily extend Istio to custom platforms. And, I hope that this guide has given you a glimpse of the Istio Mixer - Adapter interfacing, and how to build a production-ready Adapter yourself!

-----

Go, publish your own Istio Mixer Adapter! Feel free to use the [Wavefront by VMware Adapter for Istio](https://github.com/vmware/wavefront-adapter-for-istio) for reference.

Also, refer to [this Wiki](https://github.com/istio/istio/wiki/Publishing-Adapters-and-Templates-to-istio.io) if you wish to publish your adapter on the [Istio Adapters](https://istio.io/docs/reference/config/policy-and-telemetry/adapters/) page.

**Disclaimer:** My postings are my own and don't necessarily represent VMware's positions, strategies or opinions.
