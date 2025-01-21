## K8s Flux Cluster(s) Starter
A starter template for deploying and managing Kubernetes cluster(s) using FluxCD for GitOps, integrated with essential tools like JupyterHub, Harbor (artifact registry), Prometheus & Grafana (monitoring and visualization), and Terraform for managing secrets on AWS. This repository provides a structured approach to managing your Kubernetes infrastructure and applications declaratively through Git.

This project and its README are a constant work in progress, feel free to submit issues, pull requests, and suggestions!


### Features
- **Flux GitOps:** Continuous deployment and synchronization with Git.
- **Harbor:** Secure and efficient container image registry.
- **Prometheus & Grafana:** Robust monitoring and visualization stack.
- **JupyterHub:** Interactive notebook environment for data science.
- **Terraform with AWS:** Infrastructure as Code for managing secrets and AWS resources.
- **Modular Configuration:** Organized manifests and configurations for scalability.
- **Dependency Management:** Ensures the correct order of resource deployment using Flux Kustomizations.

### Repository Structure
```perl
k8s-flux-starter/
├── apps/
|   ├── base/                           # Base applications manifests
|   |   ├── harbor/                     # Harbor deployment manifests
|   |   ├── kube-prometheus-stack/      # Monitoring via Prometheus & Grafana
|   |   └── jupyterhub/                 # JupyterHub deployment manifests
│   ├── production/                     # Production applications manifests
│   └── development/                    # Development applications manifests
│   └── secrets/                        # Application secrets manifests
├── clusters/
│   └── production/                     # High-level cluster configuration for Flux
│   └── development/                    # High-level cluster configuration for Flux
├── infrastructure/
│   ├── controllers/                    # Infrastructure controllers manifests
│   ├── configs/                        # Infrastructure configurations manifests
│   └── network/                        # Network configurations manifests
├── terraform/
│   |   ├── modules/                    # Terraform modules
│   └── main.tf                         # Terraform main configuration
|   └── state.tf                        # Terraform state configuration
|   └── provider.tf                     # Terraform provider configuration
|   └── variables.tf                    # Terraform variables
|   └── terraform.tfvars.empty          # Terraform variables placeholder (sensitive once moved)
|   └── state.config.empty              # Terraform state configuration placeholder (sensitive once moved)
├── README.md       
└── ...                                 # Additional configurations and scripts

```

### Prerequisites
1. **Kubernetes Cluster >= 1.29:**  if not using K3s you will need to customize the ingress controller.
    - **Local Cluster:** K3s, Kind, Minikube, etc.
    - **Managed Cluster:** AWS EKS, GKE, AKS, etc.
2. **Flux CLI:**
    Flux CLI will be used to bootstrap flux on the cluster. Ensure FluxCLI is installed on your cluster machine or wherever you apply kubectl commands. Refer to the Flux [CLI Installation Guide](https://fluxcd.io/flux/installation/#install-the-flux-cli).
3. **Terraform:**
    Ensure Terraform is installed on your development machine. Follow the [Terraform Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) for your preferred installation method.
4. **AWS CLI:**
    We will be utilize AWS as our state backend for Terraform, as well as our secrets manager. Ensure AWS CLI is installed on your development machine for use with Terraform. If you would like to use a different cloud provider you can customize the Terraform configuration. Refer to the [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) for your preferred installation method.

    Ensure AWS CLI is configured with your access tokens; I recommend creating a dedicated IAM user for Terraform.
    ```bash
    aws configure
    ```
5. **Make (optional):**
    This repository uses Make to manage the terraform and flux setup. Technically it is not required, but it will make setup a bit easier. Refer to the [CMake Installation Guide](https://cmake.org/download/) for your preferred installation method.

### Setup Guide
Follow these steps to set up your Kubernetes cluster using the **k8s-flux-starter** repository.

#### 1. Create your copy of the template
Create a copy of this template repository if you have not already, or fork it. Once you have done so be sure to pull the repository to your development machine.


#### 2. Create a state backend bucket for Terraform
Manually create an S3 bucket for Terraform state storage. This bucket will be used for storing the Terraform state file. I would recommend using a versioned bucket to ensure there is a git-like history of the state file, but this is not required.

Finally create a directory in the bucket we can use to store our state file, e.g 'state'.

#### 3 Update template tfvars & stateconfig
The repository ships with an empty template for `terraform/terraform.tfvars` and `terraform/state.config`. We need to setup the actual files with our values.

1. Copy our empty template files to the actual files which will be ignored by our `.gitignore`:
    ```bash
    make setup-terraform-templates
    # OR if you don't have Make
    ./scripts/setup-terraform-templates.sh
    ```
2. Update the `terraform.tfvars` and `state.config` files with your desired values.
    ```bash
    # state.config
    bucket  = "" # The name of the bucket you manually created to store the state
    key     = "" # The key of the state file in the bucket, the prefix needs to be present
    # E.g: state/terraform.tfstate => state directory must be present in bucket, but not the state file
    region  = "" # The AWS Region you created the bucket in
    profile = "" # The AWS profile you configured to use with aws cli (typically 'default')
                # Can also be found in ~/.aws/credentials
    ```
    ```bash
    # terraform.tfvars
    aws_region = "" # Your preferred AWS region (currently used for secret manager)
    harbor_admin_password = "" # Whatever password you wish to use for the harbor admin account
    ```


#### 4. Configure AWS with Terraform
Navigate to the Terraform directory and initialize the workspace.
```bash
cd terraform
terraform init --backend-config ./state.config
```

#### 5. Provision AWS Resources
Apply the Terraform configuration to create necessary AWS resources for secrets management.
```bash
terraform apply
```
- **Review the plan** and confirm the creation by typing yes when prompted.
- **Outputs:** Note any output values, such as secret ARNs or access details, needed for further configuration.

#### 6. Setup Kubernetes Cluster
Setup a simple K3s cluster for testing the app, setup K3s or Rancher Desktop. Alternatively you can use an existing cluster, but you may need to tweak the ingress controller if you don't use K3s.

#### 7. Bootstrap Flux
Bootstrap Flux on your cluster to watch the repository and manage the cluster configuration.
```bash
flux bootstrap github \
  --owner=<your-github-username> \
  --repository=<your-repository-name> \
  --branch=main \
  --path=./clusters/development \
  --personal \
  --kubeconfig=/etc/rancher/k3s/k3s.yaml # Replace with your kubeconfig <-
```
- **Parameters:**
  - `--owner`: Your GitHub username or organization.
  - `--repository`: Name of your repository (k8s-flux-starter).
  - `--path`: Directory containing Flux configurations (./clusters/my-cluster).
  - `--personal`: Use this flag if it's a personal repository.
This command sets up Flux controllers in your cluster and configures them to sync with the specified GitHub repository path.

#### 8. Cluster Deployments
The `clusters` folder contains the main configuration for each cluster managed by flux in the repository. Each cluster is managed separately through the use of Kustomizations.

1. **Navigate to the Cluster Configuration Directory:**
    ```bash
    cd ../clusters/development
    ```
2. **Ensure Infrastructure & Apps Kustomizations Are Defined:**
    The `/clusters/development` & `/clusters/production` directory contains Kustomization manifests that define the order of deployment using dependencies. There are currently two files: `apps.yaml` and `infrastructure.yaml`. These define the dependency resolution order of the Kustomize overlays.

    Flux will automatically detect and apply these Kustomizations in the correct order.

3. Apply changes
    Make any changes that you desire, such as interval timings for Kustomizations and push the new changes to GitHub.
    ```bash
    git add .
    git commit -m "Update infrastructure"
    git push origin main
    ```

4. Wait for Flux to reconcile the changes
    Flux will automatically reconcile the changes and deploy the infrastructure components based on our interval settings. Alternatively we can manually trigger a reconciliation for the system manually on our cluster:
    ```bash
    flux reconcile ks flux-system --with-source
    ```

5. Monitor the progress
    We can view the progress of the reconciliation by checking the logs in the Flux system namespace:
    ```bash
    kubectl logs deployments/helm-controller -n flux-system
    kubectl logs deployments/kustomize-controller -n flux-system
    kubectl logs deployments/source-controller -n flux-system
    kubectl logs deployments/notification-controller -n flux-system
    ```
    The `kustomize-controller` is typically where you want to look during a reconciliation, but the other controllers are also involved. For example if there is an update to a HelmRepository or HelmRelase the `helm-controller` would be the one to check.

6. Verify Infrastructure
    Ensure everything is still running as expected:
    ```bash
    flux get kustomizations -A
    ```
    Should display that all kustomizations are up to date and ready.

    ```bash
    kubectl get all -n flux-system
    ```
    Should display all the resources that Flux has deployed in a consistent state.

#### 9. Configure DNS
We need to configure DNS records for JupyterHub, Harbor, and Grafana to point to our ingress controller.

- `/apps/base/<cluster>/jupyterhub-values.yaml` contains the DNS configuration for the JupyterHub Ingress
- `/apps/base/<cluster>/harbor-values.yaml` contains the DNS configuration for the Harbor Ingress
- `/infrastructure/network/grafana-ingress.yaml` contains the DNS configuration for the Grafana Ingress

It runs on your local network out of the box on the domain `internal`, but you can change it to your desired domain.

**Grab the ingress IP:**
```bash
kubectl get ingress -A'
```
Finally add the records to your DNS table. For my homelab setup on my local network I added these to my Unbound DNS server as overrides on my OPNSense box. Check out more info about my homelab [on my blog](https://bennettdixon.dev/blog?tag=homelab).
```yaml
Host: harbor
Domain: <your-domain> # e.g internal
Type: A
Value: <your-ingress-ip> # e.g 10.0.10.42
Description: Harbor Server
```
```yaml
Host: grafana
Domain: <your-domain> # e.g internal
Type: A
Value: <your-ingress-ip> # e.g 10.0.10.42
Description: Grafana Monitoring Dashboard
```
```yaml
Host: jupyter
Domain: <your-domain> # e.g internal
Type: A
Value: <your-ingress-ip> # e.g 10.0.10.42
Description: JupyterHub
```
**Note**: The ingress IP should be the same for both records, only change the Host to allow the ingress service to resolve correctly.


### Deploy your own apps
Deploy your applications using Flux.

1. **Navigate to the base applications Directory:**
    ```bash
    cd ../apps/base
    mkdir my-app && cd my-app
    ```
2. **Add a new namespace for the app:**
    ```yaml
    # /apps/base/my-app/namespace.yaml
    apiVersion: v1
    kind: Namespace
    metadata:
        name: my-app
    labels:
        toolkit.fluxcd.io/tenant: sre-team

3. **Define Your Application Manifests:**
    ```yaml
    # /apps/base/my-app/my-app.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
        name: my-app
        namespace: my-app
    spec:
    replicas: 3
    selector:
        matchLabels:
            app: my-app
    template:
        metadata:
            labels:
                app: my-app
        spec:
            containers:
                - name: my-app
                image: your-harbor-repo/my-app:latest
                ports:
                    - containerPort: 80
    ```
4. **Define your Kustomization:**

    ```yaml
    # /apps/base/my-app/kustomization.yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
        - namespace.yaml
        - my-app.yaml
    ```

5. **Include your app in your cluster's apps' kustomization:**

    ```yaml
    # Update /apps/production/kustomization.yaml:
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
        - ../base/harbor
        - ../base/kube-prometheus-stack
        - ../base/my-app # <-- Add your app as a resource
    patches:
        - path: harbor-values.yaml
            target:
            kind: HelmRelease
            name: harbor
    # Optionally define more patches as necessary
    ```

5. **(optional) define an ingress for your app:**

    ```yaml
    # /infrastructure/network/my-app-ingress.yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
        name: my-app-ingress
        namespace: my-app
    annotations:
        # If not running on k3s, replace with your ingress controller
        kubernetes.io/ingress.class: "traefik"
        cert-manager.io/cluster-issuer: "letsencrypt"
    labels:
        app: my-app
    spec:
        tls:
        - hosts:
            - my-app.internal  # Replace with your domain
            secretName: my-app-tls-secret  # Cert-Manager will manage this secret
        rules:
            # Replace with your domain or subdomain
            - host: my-app.internal
                http:
                paths:
                - path: /
                    pathType: Prefix
                    backend:
                    service:
                        name: my-app # Replace if necessary
                        port:
                        number: 80
    ```
6. **Add the ingress to the /network Kustomization:**
    ```yaml
    # Update /infrastructure/network/kustomization.yaml:
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
    - grafana-ingress.yaml
    - my-app-ingress.yaml # <-- Add your ingress as a resource
    ```


Commit and Push Changes:

Flux will automatically detect and deploy these applications.

```bash
git add .
git commit -m "Deploy production applications"
git push origin main
```

## Uses
- [fluxcd](https://fluxcd.io) - GitOps for Kubernetes
- [Kustomize](https://kustomize.io/) & [Flux Kustomize Controller](https://github.com/fluxcd/kustomize-controller)
- [Harbor](https://goharbor.io) - Artifact Registry with features like Vulnerability Scanning with Trivy, RBAC, and SSO
- [Kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) - Prometheus & Grafana helm chart
  - [Prometheus](https://prometheus.io) - Monitoring
  - [Grafana](https://grafana.com) - Monitoring
- [cert-manager](https://cert-manager.io) - TLS Certificate Management
- [external-secrets.io](https://external-secrets.io) - ESO for k8s
- [terraform](https://www.terraform.io) for cloud infrastructure
- AWS Secrets Manager (external secrets store for k8s)
- AWS S3 (Terraform State Store)


## Configure Harbor
This section is a work in progress, check back soon!

1. Setup a non root user account in Harbor
2. Configure a docker-pull account in Harbor
3. Setup a registry and assign the docker-pull account to the registry
4. Add the docker-pull account information to the tf vars for external-secrets
5. Test the setup on your dev machine:
    1. Download the Harbor CA certificate for your registry
    2. Install the Harbor CA certificate on your dev machine
    3. Run `docker login harbor.<your-domain.com>`
    4. Build the test app and tag it:
        `docker build -t harbor.<your-domain.com>/test-registry/test-app .`
    5. Push the image to your registry: 
        `docker push harbor.<your-domain.com>/test-registry/test-app:latest`
    6. If this succeeds you will see the image available in your harbor dashboard, if this is the case we can move onto testing authentication with our cluster(s).
5. Add the registry CA certificate to your cluster nodes (main & worker nodes)
    - Make sure to restart the ca-certificates.service on your nodes `sudo updat-ca-certificates`
    - You may need to restart the node itself depending on your OS `sudo reboot`


## Roadmap
- Improve documentation
- Add pre-commit hooks
- Implement RBAC & Network policies to restrict cross-namespace access
- Implement automated testing for manifests
- Add sample apps
- Add a unified logging layer using Fluentd
