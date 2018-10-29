# Get user's subscription ID
SUB_ID=$(az account show --query id --output tsv)

# Create the SP and assign 'Contributor' role access to the user's subscription
az ad sp create-for-rbac --scopes $SUB_ID --role Contributor --name sp-sub-contributor >> SP_SUB.txt

cat ./SP_SUB.txt
