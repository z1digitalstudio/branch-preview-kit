FROM ubuntu:18.04 as build

RUN apt-get update
RUN apt-get install -y curl unzip

RUN curl -O https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
RUN unzip terraform_0.12.24_linux_amd64.zip

RUN curl -OL https://github.com/mike-engel/jwt-cli/releases/download/3.0.1/jwt-cli-3.0.1-linux.tar.gz
RUN tar -xzf jwt-cli-3.0.1-linux.tar.gz && ls target/release

FROM ubuntu:18.04 as run

COPY --from=build /target/release/jwt /usr/local/bin/jwt
COPY --from=build /terraform /usr/local/bin/terraform

RUN apt-get update && \
	apt-get install -y curl jq && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY bootstrap ./bootstrap
COPY spa ./spa
COPY index.sh .

COPY global/bootstrap.sh /usr/local/bin/bootstrap
COPY global/github-say.sh /usr/local/bin/github-say
COPY global/spa.sh /usr/local/bin/spa
