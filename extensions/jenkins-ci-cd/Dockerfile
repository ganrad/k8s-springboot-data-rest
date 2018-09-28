# Custom Jenkins Image with Git, Pipeline, Maven and Build Timestamp plugins
# Dated: 09-27-2018
# Image name: jenkins-gr
FROM jenkins/jenkins:lts
MAINTAINER Ganesh Radhakrishnan ganrad01@gmail.com

# Install plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Install docker client on Jenkins container
USER root
RUN apt-get update && \
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
RUN usermod -aG docker jenkins
USER jenkins
