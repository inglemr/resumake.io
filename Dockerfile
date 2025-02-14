# Use Node.js base image for build stage
FROM node:18.20-buster AS build

# Install required dependencies for the build
RUN apt-get update && apt-get install -y --no-install-recommends \
    perl \
    fontconfig \
    ghostscript \
    poppler-utils \
    wget \
    curl \
    bash \
    tar \
    xz-utils \
    tzdata \
    gcc \
    make \
    perl-modules && \
    rm -rf /var/lib/apt/lists/*

# Set up the working directory for your app
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json .
RUN npm install

# Copy the rest of the application files
COPY . .

# Build the client and server
RUN npm run build:client --legacy-peer-deps && npm run build:server --legacy-peer-deps

# Now, switch to the runtime image based on Debian with nginx
FROM debian:bullseye-slim

# Install required dependencies and TeX Live, plus nginx
RUN apt-get update && apt-get install -y --no-install-recommends \
    perl \
    fontconfig \
    ghostscript \
    poppler-utils \
    wget \
    curl \
    bash \
    tar \
    xz-utils \
    gcc \
    make \
    perl-modules \
    texlive-base texlive-fonts-recommended texlive-latex-base \
    nginx && \
    rm -rf /var/lib/apt/lists/*

# Install TeX Live and LaTeX packages
RUN wget -qO /tmp/install-tl-unx.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    tar -xzf /tmp/install-tl-unx.tar.gz -C /tmp && \
    cd /tmp/install-tl-* && \
    echo "selected_scheme scheme-basic" > texlive.profile && \
    ./install-tl --profile=texlive.profile --no-interaction --repository=https://mirror.ctan.org/systems/texlive/tlnet && \
    rm -rf /tmp/install-tl-* /tmp/install-tl-unx.tar.gz

# Add TeX Live to PATH for the runtime
ENV PATH="/usr/local/texlive/2024/bin/x86_64-linux:$PATH"

# Install LaTeX packages required by your app in the runtime
RUN tlmgr update --self && \
    tlmgr install texliveonfly adjustbox tcolorbox collectbox ucs environ trimspaces titling enumitem rsfs xifthen ifmtarg

# Copy the production build from the build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port 80 for the nginx server
EXPOSE 80

# Start nginx to serve the app
CMD ["nginx", "-g", "daemon off;"]
