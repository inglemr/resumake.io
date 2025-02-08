FROM node:18.20-bookworm

# Install required dependencies
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


# Install TeX Live manually with an explicit mirror
RUN mkdir -p /usr/local/texlive && \
    wget -qO /tmp/install-tl-unx.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    tar -xzf /tmp/install-tl-unx.tar.gz -C /tmp && \
    cd /tmp/install-tl-* && \
    echo "selected_scheme scheme-basic" > texlive.profile && \
    ./install-tl --profile=texlive.profile --no-interaction --repository=https://mirror.ctan.org/systems/texlive/tlnet && \
    rm -rf /tmp/install-tl-* /tmp/install-tl-unx.tar.gz

# Add TeX Live to PATH
ENV PATH="/usr/local/texlive/2024/bin/aarch64-linux:$PATH"

# Install required LaTeX packages
RUN tlmgr update --self 

RUN tlmgr install texliveonfly adjustbox tcolorbox collectbox ucs environ trimspaces  titling enumitem rsfs xifthen ifmtarg
# RUN tlmgr install xelatex



# Set up the working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json .
RUN npm install

# Copy the application files
COPY . .

# Build the client and server
RUN npm run build:client --legacy-peer-deps && npm run build:server --legacy-peer-deps

# Expose the necessary port
EXPOSE 3000

# Start the application
CMD ["npm", "run", "start"]