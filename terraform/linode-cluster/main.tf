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

resource "local_file" "kubeconfigfile" {
  depends_on   = [linode_volume.datavolume]
  filename     = "kube-config"
  content      = base64decode(linode_lke_cluster.cluster.kubeconfig)
}


output "kubeconfig" {
   value = linode_lke_cluster.cluster.kubeconfig
   sensitive = true
}

variable "kubeconfiginput" {
  default = "kube-config"
}

// Create a rook-ceph namespace
provider "kubernetes" {
  config_path = var.kubeconfiginput
}

resource "time_sleep" "wait_30_seconds" {
  depends_on   = [local_file.kubeconfigfile]
  create_duration = "30s"
}

resource "kubernetes_namespace" "create_ns" {
  depends_on = [time_sleep.wait_30_seconds]
  metadata {
    name = "rook-ceph"
  }
}

// Use the rook-ceph helm chart to install rook operator
provider "helm" {
  kubernetes {
    config_path = "kube-config"
  }
}

resource "helm_release" "rook-ceph" {
  depends_on = [kubernetes_namespace.create_ns]
  name       = "rook-ceph"
  namespace  = "rook-ceph"
  repository = "https://charts.rook.io/release"
  chart      = "rook-ceph"
}

// Install ceph-cluster
provider "kubectl" {
  load_config_file = true
  config_path = "kube-config"
}

data "kubectl_file_documents" "manifests" {
    content = file("cluster.yaml")
}

resource "kubectl_manifest" "ceph-cluster" {
    depends_on   = [helm_release.rook-ceph]
    count     = length(data.kubectl_file_documents.manifests.documents)
    yaml_body = element(data.kubectl_file_documents.manifests.documents, count.index)
}