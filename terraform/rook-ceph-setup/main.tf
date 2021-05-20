terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.10.0"
    }
  }
}
// Create a rook-ceph namespace
provider "kubernetes" {
  config_path = "../linode-cluster/kube-config"
}

# resource "time_sleep" "wait_30_seconds" {
#   depends_on   = [local_file.kubeconfigfile]
#   create_duration = "30s"
# }

resource "kubernetes_namespace" "create_ns" {
  metadata {
    name = "rook-ceph"
  }
}

// Use the rook-ceph helm chart to install rook operator
provider "helm" {
  kubernetes {
    config_path = "../linode-cluster/kube-config"
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
  config_path = "../linode-cluster/kube-config"
}

data "kubectl_file_documents" "manifests" {
    content = file("cluster.yaml")
}

resource "kubectl_manifest" "ceph-cluster" {
    depends_on   = [helm_release.rook-ceph]
    count     = length(data.kubectl_file_documents.manifests.documents)
    yaml_body = element(data.kubectl_file_documents.manifests.documents, count.index)
}