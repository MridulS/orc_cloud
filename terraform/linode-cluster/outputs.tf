//Export this cluster's attributes
output "kubeconfig" {
   value = linode_lke_cluster.cluster.kubeconfig
   sensitive = true
}

output "api_endpoints" {
   value = linode_lke_cluster.cluster.api_endpoints
}

output "status" {
   value = linode_lke_cluster.cluster.status
}

output "id" {
   value = linode_lke_cluster.cluster.id
}

output "pool" {
   value = linode_lke_cluster.cluster.pool
}
