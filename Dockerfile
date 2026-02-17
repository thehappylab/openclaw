FROM coollabsio/openclaw:latest

ARG BUILD_VERSION=dev
LABEL org.opencontainers.image.version="${BUILD_VERSION}"
ENV OPENCLAW_VERSION="${BUILD_VERSION}"

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
    jq \
    ffmpeg \
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
# Node.js
# ---------------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm clawhub

# ---------------------------------------------------------------------------
# Coolify CLI
# ---------------------------------------------------------------------------
RUN curl -fsSL https://raw.githubusercontent.com/coollabsio/coolify-cli/main/scripts/install.sh | bash

# ---------------------------------------------------------------------------
# Brew wrapper: auto-drops to claw user when invoked as root
# (Homebrew refuses to run as root; the gateway runs as root)
# ---------------------------------------------------------------------------
RUN BREW_REAL="$(readlink -f /home/linuxbrew/.linuxbrew/bin/brew)" \
    && rm /home/linuxbrew/.linuxbrew/bin/brew \
    && printf '#!/bin/bash\nif [ "$(id -u)" = "0" ]; then\n  exec sudo -u claw %s "$@"\nelse\n  exec %s "$@"\nfi\n' \
       "$BREW_REAL" "$BREW_REAL" \
       > /home/linuxbrew/.linuxbrew/bin/brew \
    && chmod +x /home/linuxbrew/.linuxbrew/bin/brew

# ---------------------------------------------------------------------------
# Prepare /data for volume mounts
# ---------------------------------------------------------------------------
RUN mkdir -p /data

# ---------------------------------------------------------------------------
# Default shell preferences (interactive sessions should open in bash)
# ---------------------------------------------------------------------------
RUN usermod -s /bin/bash root \
    && usermod -s /bin/bash claw
ENV SHELL=/bin/bash

# ---------------------------------------------------------------------------
# Custom entrypoint (configures tools, then calls original entrypoint)
# ---------------------------------------------------------------------------
COPY entrypoint.sh /custom-entrypoint.sh
RUN chmod +x /custom-entrypoint.sh
ENTRYPOINT ["/custom-entrypoint.sh"]
CMD ["/bin/bash"]
