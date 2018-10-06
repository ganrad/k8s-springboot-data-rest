#!/bin/bash

# Before running this script, specify correct values for the following 2 variables !!!!
ACR_RESOURCE_GROUP=ACR-RG-NAME
ACR_NAME=ACR-NAME

# Get the ACR registry resource id
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $ACR_RESOURCE_GROUP --query "id" --output tsv)
SP_ID=sp-$ACR_NAME

# Create the service principal with "Contributor" role acccess to the ACR and save the output
# to a file SP_ACR.txt in current directory
az ad sp create-for-rbac --scopes $ACR_ID --role Contributor --name $SP_ID >> SP_ACR.txt

cat ./SP_ACR.txt
