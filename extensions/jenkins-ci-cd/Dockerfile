# Build custom Jenkins Image with Git, Pipeline, Maven, Build Timestamp & other plugins.  Image also includes Docker client and Kube CLI.
# Dated: 09-27-2018
# Author: Ganesh Radhakrishnan
# Image name: jenkins-gr
FROM jenkins/jenkins:lts
MAINTAINER Ganesh Radhakrishnan ganrad01@gmail.com

# Install Jenkins plugins
RUN echo "Installing Jenkins Plugins ..."
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

USER root

# Install docker client
RUN echo "Installing Docker-ce ..." && \
    apt-get update && \
    apt-get -y install apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common && \
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey && \
    add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
     $(lsb_release -cs) \
     stable" && \
    apt-get update && \
    apt-get -y install docker-ce

# Install kubectl CLI
RUN echo "Installing Kubectl ..." \
    && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && touch /etc/apt/sources.list.d/kubernetes.list \
    && echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install -y kubectl

# Add jenkins user to docker group
RUN usermod -aG docker jenkins

USER jenkins

