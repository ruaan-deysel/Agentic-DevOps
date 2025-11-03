FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

LABEL name="DevOps"
LABEL description="Lightweight container for Azure Infrastructure as Code development"

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Make sure the vscode user has sudo access without password
RUN echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/vscode

# Install dependencies including Python for Ansible
RUN apt-get update && \
  apt-get install -y \
  wget \
  apt-transport-https \
  software-properties-common \
  curl \
  git \
  python3 \
  python3-pip \
  python3-venv \
  unzip \
  gnupg \
  lsb-release && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install PowerShell 7.5 (latest stable)
RUN ARCH=$(uname -m) && \
  PS_VERSION="7.5.1" && \
  if [ "$ARCH" = "x86_64" ]; then \
  curl -L -o /tmp/powershell.tar.gz "https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/powershell-${PS_VERSION}-linux-x64.tar.gz"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  curl -L -o /tmp/powershell.tar.gz "https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/powershell-${PS_VERSION}-linux-arm64.tar.gz"; \
  else \
  echo "Unsupported architecture: $ARCH"; \
  exit 1; \
  fi && \
  mkdir -p /opt/microsoft/powershell/7 && \
  tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && \
  chmod +x /opt/microsoft/powershell/7/pwsh && \
  ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
  rm /tmp/powershell.tar.gz

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Bicep CLI (architecture-aware)
RUN ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then \
  curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64; \
  elif [ "$ARCH" = "aarch64" ]; then \
  curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-arm64; \
  else \
  echo "Unsupported architecture: $ARCH"; \
  exit 1; \
  fi && \
  chmod +x ./bicep && \
  mv ./bicep /usr/local/bin/bicep

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
  apt-get update && \
  apt-get install -y gh && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install Terraform (latest 1.9.x stable)
RUN ARCH=$(uname -m) && \
  TF_VERSION="1.9.8" && \
  if [ "$ARCH" = "x86_64" ]; then \
  ARCH_SUFFIX="amd64"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  ARCH_SUFFIX="arm64"; \
  else \
  echo "Unsupported architecture: $ARCH"; \
  exit 1; \
  fi && \
  curl -Lo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${ARCH_SUFFIX}.zip" && \
  unzip /tmp/terraform.zip -d /usr/local/bin && \
  chmod +x /usr/local/bin/terraform && \
  rm /tmp/terraform.zip

# Install Ansible (latest stable via pip)
RUN python3 -m pip install --no-cache-dir --break-system-packages \
  ansible \
  ansible-lint

# Install Trivy (includes tfsec functionality for Terraform security scanning)
RUN ARCH=$(uname -m) && \
  TRIVY_VERSION="0.58.1" && \
  if [ "$ARCH" = "x86_64" ]; then \
  ARCH_SUFFIX="64bit"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  ARCH_SUFFIX="ARM64"; \
  else \
  echo "Unsupported architecture: $ARCH"; \
  exit 1; \
  fi && \
  curl -Lo /tmp/trivy.tar.gz "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${ARCH_SUFFIX}.tar.gz" && \
  tar zxf /tmp/trivy.tar.gz -C /tmp && \
  mv /tmp/trivy /usr/local/bin/trivy && \
  chmod +x /usr/local/bin/trivy && \
  rm /tmp/trivy.tar.gz

# Install Checkov (IaC security scanning)
RUN python3 -m pip install --no-cache-dir --break-system-packages checkov

# ============================================================================
# TIER 1 ESSENTIAL DEVOPS TOOLS
# ============================================================================

# Install essential utilities (jq for JSON, shellcheck for shell scripts)
RUN apt-get update && \
  apt-get install -y jq shellcheck && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install yq (YAML processor - like jq but for YAML)
RUN ARCH=$(uname -m) && \
  YQ_VERSION="4.44.3" && \
  if [ "$ARCH" = "x86_64" ]; then \
  ARCH_SUFFIX="amd64"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  ARCH_SUFFIX="arm64"; \
  else \
  echo "Unsupported architecture: $ARCH"; \
  exit 1; \
  fi && \
  curl -Lo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${ARCH_SUFFIX}" && \
  chmod +x /usr/local/bin/yq

# Install kubectl (Kubernetes CLI for AKS management)
RUN ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then \
  ARCH_SUFFIX="amd64"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  ARCH_SUFFIX="arm64"; \
  else \
  echo "Unsupported architecture: $ARCH"; \
  exit 1; \
  fi && \
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH_SUFFIX}/kubectl" && \
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
  rm kubectl

# Install git-lfs (Git Large File Storage)
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
  apt-get install -y git-lfs && \
  git lfs install && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install Python-based tools (yamllint for YAML validation, pre-commit for git hooks)
RUN python3 -m pip install --no-cache-dir --break-system-packages \
  yamllint \
  pre-commit

# Install gitleaks (secret scanning to prevent credential leaks)
RUN ARCH=$(uname -m) && \
  GITLEAKS_VERSION="8.21.2" && \
  if [ "$ARCH" = "x86_64" ]; then \
  ARCH_SUFFIX="x64"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  ARCH_SUFFIX="arm64"; \
  else \
  echo "Unsupported architecture: $ARCH"; \
  exit 1; \
  fi && \
  curl -Lo /tmp/gitleaks.tar.gz "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${ARCH_SUFFIX}.tar.gz" && \
  tar xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks && \
  chmod +x /usr/local/bin/gitleaks && \
  rm /tmp/gitleaks.tar.gz

# ============================================================================
# TIER 2 HIGHLY VALUABLE DEVOPS TOOLS
# ============================================================================

# Install Helm (Kubernetes package manager for AKS deployments)
RUN ARCH=$(uname -m) && \
  HELM_VERSION="3.16.3" && \
  if [ "$ARCH" = "x86_64" ]; then \
  ARCH_SUFFIX="amd64"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  ARCH_SUFFIX="arm64"; \
  else \
  echo "Unsupported architecture: $ARCH"; \
  exit 1; \
  fi && \
  curl -Lo /tmp/helm.tar.gz "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH_SUFFIX}.tar.gz" && \
  tar xzf /tmp/helm.tar.gz -C /tmp && \
  mv /tmp/linux-${ARCH_SUFFIX}/helm /usr/local/bin/helm && \
  chmod +x /usr/local/bin/helm && \
  rm -rf /tmp/helm.tar.gz /tmp/linux-${ARCH_SUFFIX}

# Install act (run GitHub Actions workflows locally for testing)
RUN ARCH=$(uname -m) && \
  ACT_VERSION="0.2.70" && \
  if [ "$ARCH" = "x86_64" ]; then \
  ARCH_SUFFIX="x86_64"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  ARCH_SUFFIX="arm64"; \
  else \
  echo "Unsupported architecture: $ARCH"; \
  exit 1; \
  fi && \
  curl -Lo /tmp/act.tar.gz "https://github.com/nektos/act/releases/download/v${ACT_VERSION}/act_Linux_${ARCH_SUFFIX}.tar.gz" && \
  tar xzf /tmp/act.tar.gz -C /usr/local/bin act && \
  chmod +x /usr/local/bin/act && \
  rm /tmp/act.tar.gz

# Install k9s (Kubernetes CLI UI for cluster management and debugging)
RUN ARCH=$(uname -m) && \
  K9S_VERSION="0.32.7" && \
  if [ "$ARCH" = "x86_64" ]; then \
  ARCH_SUFFIX="amd64"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  ARCH_SUFFIX="arm64"; \
  else \
  echo "Unsupported architecture: $ARCH"; \
  exit 1; \
  fi && \
  curl -Lo /tmp/k9s.tar.gz "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${ARCH_SUFFIX}.tar.gz" && \
  tar xzf /tmp/k9s.tar.gz -C /usr/local/bin k9s && \
  chmod +x /usr/local/bin/k9s && \
  rm /tmp/k9s.tar.gz

# Create directories with proper permissions
RUN mkdir -p /home/vscode/.vscode-server/bin /home/vscode/.vscode-server/extensions && \
  touch /home/vscode/.vscode-server/first-run && \
  mkdir -p /workspaces/Azure-DevOps && \
  # Set proper ownership and permissions
  chown -R vscode:vscode /home/vscode/.vscode-server && \
  chmod -R 755 /home/vscode/.vscode-server && \
  chown -R vscode:vscode /workspaces && \
  chmod -R 755 /workspaces

# Reset DEBIAN_FRONTEND
ENV DEBIAN_FRONTEND=dialog
