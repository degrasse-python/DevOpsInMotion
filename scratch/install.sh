# quick install for octopus on minikube
minikube start --cpus 4 --memory 8192 --disk-size 20g

kubectl create namespace octopus
kubectl create namespace ingress-nginx
kubectl create namespace postgresql-prod
# kubectl create namespace ingress
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update

# ingress required for helm install
helm upgrade -i ingress-nginx oci://ghcr.io/nginxinc/charts/nginx-ingress \
  --values nginx-values.yaml \
  -n ingress-nginx \
  --version 1.2.1

kubectl get svc -n ingress-nginx

# minikube addons enable ingress 
# kubectl apply -f nginx-values.yaml -n ingress-nginx
kubectl get ingress -n ingress-nginx
minikube tunnel

helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.5

openssl rand -base64 16 > octopus-master-key

# helm install mssql-latest-deploy . --set ACCEPT_EULA.value=Y --set MSSQL_PID.value=Developer
helm install postgresql-prod oci://registry-1.docker.io/bitnamicharts/postgresql \
  --values postgres-values.yaml \
  --namespace postgresql

export POSTGRES_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
kubectl port-forward --namespace default svc/my-release-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432

kubectl get all

helm upgrade --install octopus-deploy oci://registry-1.docker.io/octopusdeploy/octopusdeploy-helm  \
    --values octopus-values.yaml \
    -n octopus \
    --debug

kubectl -n octopus get secret octopus-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ; echo
