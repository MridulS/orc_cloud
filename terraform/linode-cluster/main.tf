terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "1.16.0"
    }
  }
}
//Use the Linode Provider
provider "linode" {
  token = var.token
}

//Use the linode_lke_cluster resource to create
//a Kubernetes cluster
resource "linode_lke_cluster" "cluster" {
    k8s_version = var.k8s_version
    label = var.label
    region = var.region
    tags = var.tags

    dynamic "pool" {
        for_each = var.pools
        content {
            type  = pool.value["type"]
            count = pool.value["count"]
        }
    }
}

// Create data volumes for rook-ceph
resource "linode_volume" "datavolume" {
  count = var.volume_count
  label = format("%s%s","data-volume-", count.index)
  region = var.region
  linode_id = linode_lke_cluster.cluster.pool[0].nodes[count.index].instance_id
  size = var.volume_size
}

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
