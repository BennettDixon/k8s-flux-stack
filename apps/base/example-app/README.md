# Example App
This shows an example of an app that can be built and hosted on the internal Harbor registry then deployed in the cluster(s).

In practice I would build & host the code separately from this repository, but for a simple example I have included a Dockerfile to build a simple node application to host on the Harbor registry and deploy in the cluster(s).

The deployment is disabled via the `kustomization.yaml`. Once the container is built & pushed to harbor you can try enabling the deployment.