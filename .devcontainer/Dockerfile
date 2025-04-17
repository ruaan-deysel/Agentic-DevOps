FROM mcr.microsoft.com/devcontainers/base:ubuntu

LABEL name="Nucleus"
LABEL description="Lightweight container for Azure Infrastructure as Code development"

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Make sure the vscode user has sudo access without password
RUN echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/vscode

# Install dependencies
RUN apt-get update && \
  apt-get install -y wget apt-transport-https software-properties-common curl git

# Install PowerShell 7.5.0
RUN ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then \
  # Install PowerShell 7.5.0 for x64 using binary archive
  curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/powershell-7.5.0-linux-x64.tar.gz && \
  mkdir -p /opt/microsoft/powershell/7 && \
  tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && \
  chmod +x /opt/microsoft/powershell/7/pwsh && \
  ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
  rm /tmp/powershell.tar.gz; \
  elif [ "$ARCH" = "aarch64" ]; then \
  # Install PowerShell 7.5.0 for ARM64 using binary archive
  curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/powershell-7.5.0-linux-arm64.tar.gz && \
  mkdir -p /opt/microsoft/powershell/7 && \
  tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && \
  chmod +x /opt/microsoft/powershell/7/pwsh && \
  ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
  rm /tmp/powershell.tar.gz; \
  fi

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
  apt-get install -y gh

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
