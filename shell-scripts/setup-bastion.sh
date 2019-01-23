#!/bin/bash
# Author: Ganesh Radhakrishnan, garadha@microsoft.com
# Dated: 10-05-2018
# Notes:
# 1. Make sure you run this script in your home directory (of the logged in user)!
# 

set -e

if [ $# -ne 2 ]; then
	echo -e "\nUsage: setup-bastion.sh <Azure User> <Password>"
	echo -e "\tMissing arguments : Azure User name and/or password"
	exit 1
fi

# Set the user name variable
USER=`whoami`

# Install Azure CLI on this VM so that we can to deploy this application to the AKS cluster later in step [D].
#
# Import the Microsoft repository key.
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
#
# Create the local azure-cli repository information.
sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
#
# Install with the yum install command.
echo "Installing Azure CLI"
sudo yum -y install azure-cli
#
# Test the install
echo "Printing Azure CLI version"
az -v
#
# Login to your Azure account
echo "Logging into Azure using CLI"
az login -u $1 -p $2
#
# View help on az commands, sub-commands
echo "Listing Azure CLI commands"
az --help
#
# Install Git client
echo "Installing GIT client"
sudo yum -y install git
#
# Check Git version number
echo "Printing GIT version"
git --version
#
# Install OpenJDK 8 on the VM.
echo "Installing OpenJDK v1.8.0"
sudo yum install -y java-1.8.0-openjdk-devel
#
# Check JDK version
echo "Printing OpenJDK version"
java -version
#
# Install Jenkins 2.138.1
echo "Installing Jenkins"
mkdir jenkins
cd jenkins
wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war
#
# Switch back to home directory
cd
#
# Install Maven 3.5.4
echo "Installing Maven"
mkdir maven
cd maven
wget http://www-eu.apache.org/dist/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz
tar -xzvf apache-maven-3.5.4-bin.tar.gz
#
# Switch back to home directory
cd
#
# Install Helm v2.11.0
# Create a new directory 'Helm' under home directory to store the helm binary
echo "Installing Helm"
mkdir helm
cd helm
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz
tar -xzvf helm-v2.11.0-linux-amd64.tar.gz
#
# Switch back to home directory
cd
#
# Install Kubernetes CLI
# Create a new directory 'aztools' under home directory to store the kubectl binary
mkdir aztools
#
# Install kubectl binary in the new directory
echo "Installing Kubectl"
az aks install-cli --install-location=./aztools/kubectl
#
# Install Kubernetes Service Catalog 'svcat' binary in 'aztools' directory
echo "Installing Kubernetes Service Catalog"
$ cd aztools
$ curl -sLO https://servicecatalogcli.blob.core.windows.net/cli/latest/$(uname -s)/$(uname -m)/svcat
$ chmod +x ./svcat
# Switch back to home directory
$ cd
# Finally, update '.bashrc' file and set the path to Maven, Helm and Kubectl binaries
echo "Configuring PATH ..."
cd
KUBECLI=/home/${USER}/aztools
MAVEN=/home/${USER}/maven/apache-maven-3.5.4/bin
HELM=/home/${USER}/helm/linux-amd64
echo "export PATH=$MAVEN:$KUBECLI:$HELM:${PATH}" >> ~/.bashrc
echo "Configuration of jump-host environment completed!"
# End
