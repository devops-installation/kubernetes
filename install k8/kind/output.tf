# Outputs
output "public_ip" {
  value = aws_instance.ubuntu_ec2.public_ip
}

output "private_ip" {
  value = aws_instance.ubuntu_ec2.private_ip
}

output "pem_file_location" {
  value = local_file.private_key.filename
}
output "ssh_hint" {
  value = "ssh -i ${output.pem_file_location} ubuntu@${aws_instance.ubuntu_ec2.public_ip}"
}