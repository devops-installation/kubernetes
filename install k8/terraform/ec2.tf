data "aws_vpc" "default" {
  default = true

}

# Get default subnet (any one)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get latest Ubuntu 24.04 AMI
# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"] # Canonical

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}
#   Generate SSH key pair for EC2 access

# Generate SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key (.pem file)
resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "minikube-key.pem"

  file_permission = "0400"
}

# Create AWS key pair
resource "aws_key_pair" "generated_key" {
  key_name   = "minikube-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# EC2 Instance
resource "aws_instance" "ubuntu_ec2" {
  ami                         = data.aws_ssm_parameter.ubuntu.value
  instance_type               = "t3.medium"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated_key.key_name

  tags = {
    Name = "minikube-master"
  }

  # SSH connection
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh_key.private_key_pem
    host        = self.public_ip
  }
  # Provisioner: Install Docker + Minikube
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y docker.io curl apt-transport-https",

      # Docker setup
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ubuntu",

      # Install kubectl
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl",
      "chmod +x kubectl",
      "sudo mv kubectl /usr/local/bin/",

      # Install Minikube
      "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
      "sudo install minikube-linux-amd64 /usr/local/bin/minikube",

      # Start Minikube (docker driver)
      "sudo -u ubuntu minikube start --driver=docker",
      "git clone https://github.com/devops-installation/kubernetes.git"

    ]
  }
}

