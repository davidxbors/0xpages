FROM ubuntu:latest

# Set environment variables
ENV HUGO_VERSION=0.127.0
ENV TZ=America/Los_Angeles
ENV HUGO_ENVIRONMENT=production

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    git \
    curl \
    nodejs \
    npm \
    snapd \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set timezone
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Install Hugo
RUN wget -O /tmp/hugo.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb \
    && dpkg -i /tmp/hugo.deb \
    && rm /tmp/hugo.deb

# Install Dart Sass (via npm since snap might be complex in Docker)
RUN npm install -g sass

# Set working directory
WORKDIR /app

# Create entrypoint script
RUN echo '#!/bin/bash \n\
echo "🚀 Starting Hugo build process..." \n\
\n\
# Check if this is a git repository with submodules \n\
if [ -d ".git" ]; then \n\
  echo "📦 Updating git submodules..." \n\
  git submodule update --init --recursive \n\
fi \n\
\n\
# Install Node.js dependencies if package.json exists \n\
if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then \n\
  echo "📦 Installing Node.js dependencies..." \n\
  npm ci \n\
fi \n\
\n\
# Set default base URL if not provided \n\
BASE_URL=${BASE_URL:-http://localhost:1313} \n\
\n\
# Build the site \n\
if [ "$1" = "build" ]; then \n\
  echo "🔨 Building site with Hugo..." \n\
  hugo --gc --minify --baseURL "$BASE_URL/" \n\
  echo "✅ Build complete! Site generated in ./public directory" \n\
\n\
elif [ "$1" = "serve" ]; then \n\
  echo "🌐 Serving site with Hugo server..." \n\
  hugo server --bind=0.0.0.0 -D --disableFastRender \n\
\n\
elif [ "$1" = "shell" ]; then \n\
  echo "🐚 Starting shell..." \n\
  /bin/bash \n\
\n\
else \n\
  echo "Usage: \n\
  - build: Build the site \n\
  - serve: Build and serve the site \n\
  - shell: Start a shell" \n\
  exit 1 \n\
fi \n\
' > /usr/local/bin/entrypoint.sh \
&& chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["build"]