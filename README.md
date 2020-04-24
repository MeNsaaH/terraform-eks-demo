# terraform-trials

Exploring Terraform on AWS using S3, VPC, EKS and Helm's Chart.


## Getting Started
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
```

### Destruction
```
$ terraform destroy
```
