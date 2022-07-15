# rukpak-example
## Introduction
This repository was built with the intent of providing a clear and easy-to-follow tutorial for working with `RukPak`. More specifically, creating a simple web application using in Go using `RukPak` and `ArgoCD`.

Before getting started, it is important to clarify an understanding of our stack. Working within the Kubernetes ecosystem can be complex and filled with a lot of jargon. Establishing a solid conceptual understanding of the problem space allows us to get into the weeds with more confidence.

### ArgoCD
`ArgoCD` is a GitOps tool that uses Git repositories and their references (branches and tags) as a source of truth when maintaing a system. It does this by continually working to reconcile the state of a cluster to match the defined state in a Git reference.

For mor information on `ArgoCD` and GitOps in general, check out [ArgoCD's documentation](https://argo-cd.readthedocs.io/en/stable/).

### RukPak
From the developers of `RukPak` themselves:

> `RukPak` is a pluggable solution for the packaging and distribution of cloud-native content and supports advanced strategies for installation, updates, and policy. The project provides a content ecosystem for installing a variety of artifacts, such as Git repositories, Helm charts, OLM bundles, and more onto a Kubernetes cluster. These artifacts can then be managed, scaled, and upgraded in a safe way to enable powerful cluster extensions.

Essentially, `RukPak` is a way of safely extending our cluster's functionality with applications. This becomes especially powerful as we build out applications that rely on many different Kubernetes controllers, custom resources, and applications.

## Prequisites

- [Go 1.18](https://go.dev/dl/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)

## Exploring our application
The source code for the example repo can be found [here](https://github.com/tylerslaton/rukpak-example). If you would like to follow along (or start on your own application) templating the repo is supported. This feature allows you to essentially fork all of the code but not bring along any of the original repo's commits.

![](https://i.imgur.com/gLFz2hb.png)

If you want to just view the code and not use it in any official capacity, you can go ahead and clone it locally.

> **Note**: This repository has a variety of Makefile commands to make interacting with it easier. We will be using them throughout the tutorial. If you would like to see all available targets run `make help`.

### API code
The code for this web application is entirely encapsulated inside of `main.go` in the root. To start it, you can run:

```shell
$ make run
CGO_ENABLED=0 go run main.go
2022/07/14 15:39:31 listening on port 8080...
```

In another terminal, we can now send requests over to the server via curl (or the tool of your choosing):

```shell
$ curl localhost:8080
{"message":"success"}
```

In the spirit of keeping things simple, the code for this API is very tightly scoped.

```go=
package main

import (
	"encoding/json"
	"log"
	"net/http"
)

func index(w http.ResponseWriter, r *http.Request) {
	log.Println("incoming request for /")
	json.NewEncoder(w).Encode(map[string]string{"message": "success"})
}

func main() {
	http.HandleFunc("/", index)
	log.Println("listening on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

You can extend this out as you want or just leave it as is. Feel free to use this as a basis for your application if you'd like. For the purposes of this tutorial, the code that we are deploying is less important.

### Application manifests
The code in this application can easily be deployed to a local (or remote) cluster via the `manifests/` directory. This directory provides the essential manifests for running this application. This includes:

* **Deployment** - How the application should be deployed onto the cluster
* **Service** - A static path to be able to reach the application
* **Namespace** - Allows our application to be segmented from others

These manifests can be applied to any cluster using the [kubectl](https://kubernetes.io/docs/tasks/tools/) cli tool.

```
kubectl apply -f manifests
```

Of course, we're more interested in automating this process, so let's keep moving forward.

### RukPak manifests
`RukPak` is a set of API's that help us to deploy applications easily from various sources of differing structures. It does this by having a variety of sources and provisioners that can read from those sources. A source contains a collection of manifests in a format that the provisioner is able to recognize. At the time of writing this, there are currently 2 different provisioners:

* `plain` - Static kubernetes manifests
* `registry` - Kubernetes manifests defined in the format required by Operator Lifecycle Manager (OLM)

There are also a variety of sources available:

* [Image](https://github.com/operator-framework/rukpak#bundle) - Path to a container image
* [Git](https://github.com/operator-framework/rukpak/blob/main/docs/git-bundles.md)- Reference to a Git resource (branch, tag, etc.)
* [Local](https://github.com/operator-framework/rukpak/blob/main/docs/local-bundles.md) - A `ConfigMap` on cluster that contains the `manifests`

For our purposes today we are using a `plain` bundle sourced via `git`. Let's take a look at the layout of the `bundle-deployment.yaml`.

```yaml
apiVersion: core.rukpak.io/v1alpha1
kind: BundleDeployment
metadata:
  name: sample-api
spec:
  provisionerClassName: core.rukpak.io/plain
  template:
    metadata:
      labels:
        app: sample-api
    spec:
      provisionerClassName: core.rukpak.io/plain
      source:
        type: git
        git:
          repository: https://github.com/tylerslaton/rukpak-example
          ref:
            tag: v0.0.2
```

There are a couple of things to notice here. First, you'll notice that we are defining a `BundleDeployment` in this resource. This is what `RukPak` will use report back status of unpacking and installation for our `Bundle`. The other thing to notice is the second `spec` defined in this manifest. That spec if for defining a `Bundle` and in it we can define the source. Lastly, each level of spec requires that we define a `provisionerClassName` which tells `RukPak` which provisioner to use

All together, we are going to use this manifest as our source of truth when deploying the application.

## Getting the cluster ready
You can use any flavor of cluster you want for the purposes of this demonstration. If you just want to use regular kubernetes in a light-weight fashion, I recommend using [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/). If you are working on OpenShift, consider using OpenShift Local (formerly known as `crc`) to start a local cluster.

> **Note**: If you are using OpenShift, feel free to replace any reference to `kubectl` with `oc`.

### Installing RukPak
At the time of writing, the most recent version of `RukPak` is v0.6.0 and releases are done about every three weeks. Installing the latest release is as simple as going to [the release page](https://github.com/operator-framework/rukpak/releases) and following the instructuions. You'll known when to come back when the installation succeeds and the following command produces results:

```
$ kubectl get crd | grep "rukpak"
```

### Setting up ArgoCD
`ArgoCD` themselves have really great documentation around setting up their application on cluster. Check it out [here](https://argo-cd.readthedocs.io/en/stable/getting_started/). If you are using an OpenShift cluster, check out `ArgoCD`'s [operator documentation](https://argocd-operator.readthedocs.io/en/latest/install/start/) to move forward. You'll know when to come back when you've logged into the 


## Adding ArgoCD deployments

### Creating the application
To get started, go ahead and click on the "new app" button in the top left. This will open a window that will allow us to create a new application through the user interface.

First, we need to define some meta data around the application as well as how synchronization will occur. The `Sync Policy` setting being `Automatic` essentially allows `ArgoCD` to continuously watch a resource and work to reconcile changes to it. If that is set to `Manual` then a user will have to interact with it directly.
![](https://i.imgur.com/vhB7Zfn.png)

Next we need to begin defining what resource (`git` or `helm` based) we want to use. Here we are defining the [rukpak-example](https://github.com/tylerslaton/rukpak-example) repository and point it to the `rukpak` directory in its path.

![](https://i.imgur.com/7XJy9lc.png)

Finally, we need to define what cluster we are going to write to. If you don't have the cluster you're looking for defined in the drop down here, you probably missed [this step](https://argo-cd.readthedocs.io/en/stable/getting_started/#5-register-a-cluster-to-deploy-apps-to-optional) in `ArgoCD`'s documentation. In this example, we just use the default kubernetes service.

![](https://i.imgur.com/RCf6HTd.png)

With all of this configuration defined, you should begin to see `ArgoCD` deploy our resources! This process starts fairly quickly, so keep a lookout when you hit the create button.

![](https://i.imgur.com/gO9gWOc.png)

### Demonstrating some interesting features
Now that we have `ArgoCD` step to watch our repository, there are a few interesting things about our deployment process.

#### Deleted resources backed by our git source get recreated
If we were to delete our `BundleDeployment` that got created by `ArgoCD` like so:

```shell
$ kubectl delete bundledeployment sample-api
bundledeployment.core.rukpak.io "sample-api" deleted
```

This will result in `ArgoCD` automatically recreating. This happens very quick, so lets take a look in slow motion.

First, it notices there is a skew in our cluster state from our source of truth.
![](https://i.imgur.com/LaRERcF.png)

Then it does the work needed to fix the skew and creates the `BundleDeployment` again
![](https://i.imgur.com/iCieYoe.png)

Finally, our cluster state is back to the state it was prior to deletion.
![](https://i.imgur.com/1mgxcFU.png)


#### Updates to our git source result in those changes propagating to the cluster
Say that we go ahead and make a change to our `rukpak` directory to include another `BundleDeployment`. To do this, we only need to commit a new manifest into the `main` branch for the repository. For now, lets go ahead and install a simple application called [Combo](https://github.com/operator-framework/combo) with the following manifest.

```yaml
kind: BundleDeployment
metadata:
  name: combo
spec:
  provisionerClassName: core.rukpak.io/plain
  template:
    metadata:
      labels:
        app: combo
    spec:
      provisionerClassName: core.rukpak.io/plain
      source:
        image:
          ref: quay.io/operator-framework/combo-bundle:v0.0.1
        type: image
```

If you wait some time (you can hit the synchronize button if you don't want to wait) we can see that the resources get automatically created onto the cluster as we would expect.

![](https://i.imgur.com/D4h47hI.png)

Since this Bundle has more manifests to it, we can see them all portrayed better here. Our `rukpak-example` manifests don't have a lot to them so this exemplifies some of the visualization that we can out of the box with `ArgoCD`.
