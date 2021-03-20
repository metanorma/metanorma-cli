ARG RUBY_IMAGE=ruby:3.0-buster

FROM ${RUBY_IMAGE}

RUN apt-get update -qq && apt-get install -yy curl wget

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get update && apt-get install -qq -y nodejs build-essential \
    libxml2-dev libxslt1-dev libqtwebkit4 libqt4-dev xvfb wait-for-it \
    openjdk-11-jdk libpq-dev --fix-missing --no-install-recommends \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# install latest bundler
RUN gem install bundler
RUN npm install yarn -g

# Create app directory
WORKDIR /metanorma-cli

# Set bundle path
ENV BUNDLE_PATH /bundle

# Copy files
COPY . .

# Default to console
CMD ["bin/console"]
