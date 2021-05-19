## Config files to set up a LKE cluster backed by rook-ceph storage.

Get your Linode API key and export to environment so terraform linode module can talk to LKE.
```
$ export TF_VAR_token= ........
```

Make sure you have installed terraform locally.
```
$ terraform init
$ terraform plan # will show you the resources about to be created
$ terraform apply
```

To destroy the cluster it's not just `terraform destroy`, we need
to remove the `kube-config` file from the state otherwise terraform
will delete it from deleting the cluster resources and will end up in
a limbo. (poetically described at https://github.com/hashicorp/terraform/issues/20196#issuecomment-536612462)

```
$ terraform state rm local_file.kubeconfig # remove the local file from state
$ terraform destroy
```
