# Buildkite Platform - Cluster as a Service

This project provides a web-based platform for automatically provisioning and deploying Kubernetes clusters using Buildkite as the task execution engine. Users can log in, provide a GitHub repository URL, and have their Kubernetes resources automatically deployed to a fresh cluster.

## Prerequisites

- Node.js v14+ installed
- A Buildkite account with API access
- Docker installed (for local development)
- A GitHub repository containing Kubernetes manifests
- Minikube installed (for local testing)

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
