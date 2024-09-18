# Kubernetes Terraform Module

A Terraform module for creating a pre-baked Kubernetes cluster for use in lab sessions.

## Testing locally

Create a `vars.tfvars` file with the following content, replacing the values with valid ones from your AWS account:

```hcl
key_pair_name = "your-key-pair-name"
security_group_id = "your-security-group-id"
```

Then run the following commands:

```bash
terraform init
terraform plan
terraform apply -var-file=vars.tfvars -auto-approve
```

After the cluster is up and running, you can access the cluster using the bastion instance via SSH or EC2 Instance Connect.

To destroy the cluster, run:

```bash
terraform destroy -var-file=vars.tfvars -auto-approve
```

Notes:

- Any resources created within the cluster (PVs, LoadBalancers, etc) will need to be destoryed manually.

## Usage

To use in a lab Terraform configuration, add the following code to your template:

```hcl
module kubernetes_cluster {
  source = "github.com/cloudacademy/terraform-module-kubernetes-cluster"

  control_plane_ami       = "current_ami"
  worker_ami              = "current_ami"
  bastion_ami             = "current_ami"
  key_pair_name           = "your-key-pair-name"
  control_plane_user_data = "your-user-data"
  worker1_user_data       = "your-user-data"
  worker2_user_data       = "your-user-data"
  bastion_user_data       = "your-user-data"
}
```

Example with the AWS data module:

```hcl
module "aws_data" {
  source = "github.com/cloudacademy/terraform-module-aws-data?ref=v1.0.1"
}

module kubernetes_cluster {
  source = "github.com/cloudacademy/terraform-module-kubernetes-cluster"

  control_plane_ami       = "current_ami"
  worker_ami              = "current_ami"
  bastion_ami             = "current_ami"
  key_pair_name           = "module.aws_data.aws.key_pair_name"
  control_plane_user_data = "your-user-data"
  worker1_user_data       = "your-user-data"
  worker2_user_data       = "your-user-data"
  bastion_user_data       = "your-user-data"
}
```

Notes:

- The pre-baked AMIs run on Ubuntu and require user-data to bootstrap the necessary scripts to configure the cluster.
