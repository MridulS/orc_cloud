provider "helm" {
  kubernetes {
    config_path = "kube-config"
  }
}

resource "helm_release" "rook-ceph" {
  depends_on   = [linode_lke_cluster.cluster]
  name       = "rook-ceph"

  repository = "https://charts.rook.io/release"
  chart      = "rook-ceph"
}