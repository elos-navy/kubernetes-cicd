FROM quay.io/openshift/origin-jenkins-agent-base:latest
USER root
RUN yum -y install skopeo && yum clean all

# Install helm client.
RUN cd /tmp && wget https://storage.googleapis.com/kubernetes-helm/helm-v2.13.0-linux-amd64.tar.gz && tar xzf helm-v2.13.0-linux-amd64.tar.gz && mv -f linux-amd64/helm /usr/local/bin/ && mv -f linux-amd64/tiller /usr/local/bin/

USER 1001
