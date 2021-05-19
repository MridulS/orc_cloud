terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "1.16.0"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.10.0"
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
  depends_on = [linode_lke_cluster.cluster]
  count = var.volume_count
  label = format("%s%s","data-volume-", count.index)
  region = var.region
  linode_id = linode_lke_cluster.cluster.pool[0].nodes[count.index].instance_id
  size = var.volume_size
}

resource "local_file" "kubeconfig" {
  depends_on   = [linode_lke_cluster.cluster]
  filename     = "kube-config"
  content      = base64decode(linode_lke_cluster.cluster.kubeconfig)
}