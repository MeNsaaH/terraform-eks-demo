# terraform-trials

Exploring Terraform on AWS using ArgoCD, Helm, ACM


## Getting Started

### Requirements
- AWS Cli
- Helm v2.16 
- argocd cli

### Configure AWS
```
$ aws configure
aWS Access Key ID [****************7CDE]:
AWS Secret Access Key [****************2NGa]:
Default region name [eu-west-2]:
Default output format [None]: 
```

### Deployment
```bash
$ git clone https://git.deimos.co.za/mensaah/terraform-trials.git
$ cd terraform-eks
$ terraform init
$ terraform plan
$ terraform apply
# After Running apply, run `terraform init` again to move the terraform state to aws s3 bucket
$ terraform init # moves state to s3
```

### Destruction
```
$ terraform destroy -target module.helm_agones.helm_release.agones -auto-approve && sleep 60
$ terraform destroy
```
There is an issue with the AWS Terraform provider: https://github.com/terraform-providers/terraform-provider-aws/issues/9101. Due to this issue you should remove helm release first (as stated above), otherwise terraform destroy will timeout and never succeed. Remove all created resources manually in that case, namely: 3 Auto Scaling groups, EKS cluster, and a VPC with all dependent resources

### IAM User Profile
After running `terraform apply`, an encrypted password output is printed out. The encrypted password may be decrypted using the command line, for example: 
```
$ terraform output password | base64 --decode | keybase pgp decrypt
```
