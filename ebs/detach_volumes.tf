resource "null_resource" "detach_volume" {
  for_each = var.user_node_ids

  provisioner "local-exec" {
    command = <<EOT
      VOLUME_ID=$(aws ec2 describe-volumes --filters Name=tag:Name,Values="rln-ebs-${var.user_id}-${each.key}" --query "Volumes[0].VolumeId" --output text)
      if aws ec2 describe-volumes --volume-ids $VOLUME_ID | grep -q "InstanceId"; then
        aws ec2 detach-volume --volume-id $VOLUME_ID
        aws ec2 wait volume-available --volume-ids $VOLUME_ID
      fi
    EOT
  }
}

variable "user_node_ids" {
  type = map(string)
}

variable "user_id" {
  type = string
}

variable "region" {
  description = "AWS region where the resources will be deployed"
  type        = string
  default     = "us-east-2"
}
