output "vpc_id" {
  description = "ID of the newly-created EC2 VPC."
  value       = aws_vpc.vpc.id
}

output "public_ip" {
  description = "IP Address of the control plane for the newly-created EC2 VPC."
  value       = aws_instance.control_plane.public_ip
}

output "public_dns" {
  description = "Public DNS FQDN of the control plane for the newly-created EC2 VPC."
  value       = aws_instance.control_plane.public_dns
}

output "private_ip" {
  description = "Private IP Address of the control plane."
  value       = aws_instance.control_plane.private_ip
}

output "bastion_public_ip" {
  description = "IP Address of the bastion host for the newly-created EC2 VPC."
  value       = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  description = "Public DNS FQDN of the bastion host for the newly-created EC2 VPC."
  value       = aws_instance.bastion.public_dns
}

output "userdata_bastion_public_ip" {
  description = "IP Address of the bastion host for the newly-created EC2 VPC."
  value       = aws_instance.bastion.public_ip
}

output "userdata_cluster_ssh" {
  description = "SSH command to the bastion host."
  value       = "ssh ubuntu@${aws_instance.bastion.public_ip} -oStrictHostKeyChecking=no"
}