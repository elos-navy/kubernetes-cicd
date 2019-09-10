FROM docker.io/openshift/jenkins-agent-maven-35-centos7:v3.11
USER root
RUN yum -y install skopeo buildah && yum clean all

# Install helm client.
RUN cd /tmp && wget https://storage.googleapis.com/kubernetes-helm/helm-v2.13.0-linux-amd64.tar.gz && tar xzf helm-v2.13.0-linux-amd64.tar.gz && mv -f linux-amd64/helm /usr/local/bin/ && mv -f linux-amd64/tiller /usr/local/bin/

# Install gomplate - go template commandline tool.
RUN curl -o /usr/local/bin/gomplate -sSL https://github.com/hairyhenderson/gomplate/releases/download/v3.5.0/gomplate_linux-amd64 && chmod +x /usr/local/bin/gomplate

USER 1001
