FROM docker:latest

RUN apk update && \
    apk add bash git ruby-json ansible openssh && \
    gem install stack_car --no-ri --no-rdoc && \

    wget https://github.com/rancher/cli/releases/download/v0.4.1/rancher-linux-amd64-v0.4.1.tar.gz && \
    tar zxfv rancher-linux-amd64-v0.4.1.tar.gz && \
    mv rancher-v0.4.1/rancher /bin/rancher


