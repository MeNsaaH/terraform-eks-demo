##################################################################################
# Helm 
##################################################################################

resource "null_resource" "install_helm" {
  depends_on = [null_resource.update_kubeconfig]

  provisioner "local-exec" {
    command = "kubectl apply -f ./k8s/tiller-user.yaml && helm init --service-account tiller"
  }
}
