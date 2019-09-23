# k8s-mongodb-replica-set

This repository is an example set of scripts and Kubernetes manifests to deploy a MongoDB Replica Set into Kubernetes.

## Shipper

Shipper is a bash script used to build the MongoDB primary and secondary Container Images using Buildah. The following options are available.

- `--build-images|--create-images` builds container images using buildah
- `--delete-images` deletes the container images
- `--save-images` saves the images as docker-archive files in /tmp

Example usage

```BASH
buildah unshare ./shipper.sh --create-images
```

```BASH
./shipper.sh --save-images
```

```BASH
./shipper.sh --delete-images
```

## Kubernetes

The Kubernetes manifests are broken up into

- `deployment.yml` deploys three MongoDB pods
- `persistantvolumes.yml` creates three persistant volumes. WARNING, these are created in /tmp - don't copy this verbatim into a production deployment without updating it
- `persistantvolumeclaims.yml` creates three peristant volume claims
- `services.yml` creates services for each pod exposing port 27017 at 31100, 31101, and 31102 for mongodb0, mongdb1, and mongodb2 pods respectively

The deployment manifest declares the first database user which by default is `root` and `password`. Note, these is also reflected in `files/init-mongodb0-post.sh` should you update them.

## MongoDB

The MongoDB Replica Set consists of three nodes. Parameters are passed to the containers via the Kubernetes deployments.yml to define the Replica Set, IP binding, listening port configuration, and the location of the shared key file which is created when ./shipper.exe --create-images is executed and added to the container images.

During the MongoDB container init process the `files/init-mongodb0.sh` script in this repository will be executed. This script forks to `files/init-mongodb0-post.sh` which does the following

- sleeps for 30 seconds
- performs an rs.initiate() to configure the replica set
- sleeps for 30 seconds
- creates a sample collection and dummy document

The forking and sleeping are required to a) give the pods time to come up and allow the containers built in init process to complete, and b) give the rs.initiate() time to complete and stabalise.

In order for the sample collection and dummy document instructions to complete, mongodb0 is given a higher priority to ensure it becomes the primary.

## Requirements

- Buildah Version 1.10.1