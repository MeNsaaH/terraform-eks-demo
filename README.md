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
$ terraform destroy
```

### IAM User Profile
After running `terraform apply`, an encrypted password output is printed out. The encrypted password may be decrypted using the command line, for example: 
```
$ terraform output password | base64 --decode | keybase pgp decrypt
```
