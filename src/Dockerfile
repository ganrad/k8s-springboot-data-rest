# Springboot Service : 03-29-2018
#
# po-rest-service
#

FROM centos:latest
MAINTAINER Ganesh Radhakrishnan ganrad01@gmail.com

# Builder version
ENV BUILDER_VERSION 1.0
LABEL io.k8s.description="Base image for running a Java Spring Boot application" \
      io.k8s.display-name="Purchase Order (RESTFul) Service Spring Boot Application 1.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="Java,Springboot"

# Install required util packages
RUN yum -y update; \
    yum install ca-certificates -y; \
    yum install sudo -y; \
    yum clean all -y

# Install OpenJDK 1.8, create required directories.
RUN yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel && \
    yum clean all -y && \
    mkdir -p /home/apps

# Change working directory
WORKDIR /home/apps

# For Spring Boot, there should only be 1 fat jar
ADD ./target/po-rest-service-1.0.jar /home/apps/po-rest-service-1.0.jar

# Run the po-rest-service application
CMD java -jar ./po-rest-service-1.0.jar
