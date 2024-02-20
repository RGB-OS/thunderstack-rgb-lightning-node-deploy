# Use an official Python runtime as a parent image
FROM python:3.8-slim

# Set Terraform Version
ARG TERRAFORM_VERSION=1.7.3

# Install basic utilities
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI
RUN pip install --no-cache-dir awscli

# Install Terraform
RUN curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install Docker client
RUN curl -fsSL https://get.docker.com | sh

# Verify installations
RUN aws --version \
    && terraform version \
    && docker --version

ENTRYPOINT ["/bin/bash"]
