FROM coollabsio/openclaw:latest

USER root

# ---------------------------------------------------------------------------
# System dependencies (needed by brew, gh, bw, and general tooling)
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    curl \
    wget \
    git \
    build-essential \
    procps \
    file \
    unzip \
    sudo \
    ca-certificates \
    gnupg \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# GitHub CLI (gh)
# ---------------------------------------------------------------------------
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Bitwarden CLI (bw)
# ---------------------------------------------------------------------------
RUN curl -sL "https://vault.bitwarden.com/download/?app=cli&platform=linux" -o /tmp/bw.zip \
    && unzip /tmp/bw.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/bw \
    && rm /tmp/bw.zip

# ---------------------------------------------------------------------------
# Homebrew (Linuxbrew)
# ---------------------------------------------------------------------------
ENV NONINTERACTIVE=1
RUN useradd -m -s /bin/bash claw 2>/dev/null || true \
    && echo 'claw ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER claw
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

USER root
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# ---------------------------------------------------------------------------
# Node.js (needed for clawhub CLI)
# ---------------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# ClawHub CLI (skill management)
# ---------------------------------------------------------------------------
RUN npm install -g clawhub

# ---------------------------------------------------------------------------
# Coolify CLI
# ---------------------------------------------------------------------------
RUN curl -fsSL https://raw.githubusercontent.com/coollabsio/coolify-cli/main/scripts/install.sh | bash

# ---------------------------------------------------------------------------
# Prepare directories for non-root runtime
# ---------------------------------------------------------------------------
RUN chown -R claw:claw /app \
    && mkdir -p /data && chown -R claw:claw /data

# ---------------------------------------------------------------------------
# Custom entrypoint (configures tools, then drops to non-root user)
# ---------------------------------------------------------------------------
COPY entrypoint.sh /custom-entrypoint.sh
COPY preinstall-claws.sh /preinstall-claws.sh
RUN chmod +x /custom-entrypoint.sh /preinstall-claws.sh
ENTRYPOINT ["/custom-entrypoint.sh"]
