# Buildkite Platform - Cluster as a Service

This project provides a web-based platform for automatically provisioning and deploying Kubernetes clusters using Buildkite as the task execution engine. Users can log in, provide a GitHub repository URL, and have their Kubernetes resources automatically deployed to a fresh cluster.

## Prerequisites

- Node.js v14+ installed
- A Buildkite account with API access
- Docker installed (for local development)
- A GitHub repository containing Kubernetes manifests
- Minikube installed (for local testing)
- AWS account with the following:
  - AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY set as environment variables
  - AWS_REGION set as an environment variable
  - EKS cluster configuration set as environment variables (EKS_CLUSTER_NAME, EKS_NODE_GROUP_NAME, EKS_NODE_INSTANCE_TYPE, EKS_NODE_MIN_SIZE, EKS_NODE_MAX_SIZE, EKS_NODE_DESIRED_SIZE)

## Local Development Setup

1. Install dependencies:
   ```bash
   npm install
   npm install express-basic-auth
   npm install nodemon
   ```

2. Create a `.env` file in the root directory with the following variables:
   ```
   BUILDKITE_API_KEY=your_buildkite_api_key
   BUILDKITE_ORG_SLUG=your_buildkite_org_slug 
   BUILDKITE_PIPELINE_SLUG=your_buildkite_pipeline_slug
   PORT=3000
   BASIC_AUTH_USER=admin
   BASIC_AUTH_PASSWORD=password
   AWS_ACCESS_KEY_ID=your_aws_access_key_id
   AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
   AWS_REGION=your_aws_region
   EKS_CLUSTER_NAME=your_cluster_name
   EKS_NODE_GROUP_NAME=your_node_group
   EKS_NODE_INSTANCE_TYPE=t3.medium
   EKS_NODE_MIN_SIZE=2
   EKS_NODE_MAX_SIZE=4
   EKS_NODE_DESIRED_SIZE=2
   ```

3. Start Minikube:
   ```bash
   minikube start
   ```

4. Enable the Minikube Docker daemon:
   ```bash
   eval $(minikube docker-env)
   ```

5. Start the development server:
   ```bash
   npm run dev
   ```

The application will be available at http://localhost:3000

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/your_username/buildkite-platform.git
   ```

2. Add the repository to Buildkite:
   - Go to your Buildkite account
   - Click on "Add a new pipeline"
   - Select the repository you just cloned
   - Click on "Create pipeline"

3. Configure the pipeline:
   - Go to your pipeline settings
   - Click on "Edit pipeline"
   - Select the "YAML" configuration option
   - Upload the `pipeline.yaml` file from this repository
   - Click on "Save pipeline"

4. Disable all GitHub activity:
   - Go to your GitHub repository settings
   - Click on "Actions"
   - Disable all GitHub Actions
   - Click on "Save"

5. You are now ready to use the Buildkite Platform!
