#  Build and deploy a Java Springboot microservice application on Azure Container Service (AKS) running on Microsoft Azure.

In a nutshell, you will work on the following activities.
1.  Build a containerized Springboot Java Microservice Application (version 1.0) using VSTS (Visual Studio Team Services).  This activity corresponds to the **Continuous Deployment** aspect of a DevOps solution.
2.  Deploy the containerized Java Springboot microservice application in Azure Container Service (AKS) running on Azure.
3.  TBD: Update the application code (version 2.0) in a separate branch and then re-build and re-deploy the containerized application on AKS.  This activity focuses on the **Continuous Integration** aspect of a DevOps solution.

**Prerequisities:**
1.  A GitHub account to fork this GitHub repository and/or clone this repository.
2.  A Visual Studio Team Services Account.  You can get a free VSTS account by accessing the [Visual Studio Team Services](https://www.visualstudio.com/team-services/) website.
3.  An active Microsoft Azure subscription.  You can obtain a free Azure subscription by accessing the [Microsoft Azure](https://azure.microsoft.com/en-us/?v=18.12) website.

**Important Notes:**
- Only commands prefixed with a **$** sign (denotes the command prompt in Linux) are required to be executed on the Linux terminal window.  Lines prefixed with the **#** symbol are to be treated as comments. 

This Springboot application demonstrates how to build and deploy a *Purchase Order* microservice (`po-service`) as a containerized application on Azure Container Service (AKS) on Microsoft Azure. The deployed microservice supports all CRUD operations on purchase orders.

### A] Deploy a Linux CentOS VM on Azure (~ Bastion Host)
This Linux VM will be used for the following purposes
- Running a VSTS build agent (docker container) which will be used for running application and container builds.
- Installing Azure CLI 2.0 client.  This will allow us to administer and manage all Azure resources including the AKS cluster resources.
- Installing Git client.  We will be cloning this repository to make changes to the Kubernetes resources before deploying them to the AKS cluster.

Follow the steps below to create the Bastion host (Linux VM), install Azure CLI, login to your Azure account using the CLI, install Git client and cloning this GitHub repository.

1.  Open a command terminal on your workstation.  This tutorial requires you to run Azure CLI version 2.0.4 or later.  Refer to [install Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) documentation to install Azure CLI for your specific platform (Operating system).

2.  An Azure resource group is a logical container into which Azure resources are deployed and managed.  So let's start by first creating a **Resource Group** using the Azure CLI.  Alternatively, you can use Azure Portal to create this resource group.  
```
az group create --name myResourceGroup --location eastus
```
**NOTE:** Specify either *eastus* or *westus2* as the location for the resource group.  At the time of this writing, AKS cluster is available in public preview mode in eastus, westus2, centralus and canada regions.  **All** Azure resources will be deployed to the same resource group.

3.  Use the command below to create a **CentOS 7.4** VM on Azure.  Make sure you specify the correct **resource group** name and provide a value for the *password*.  Once the command completes, it will print the VM connection info. in the JSON message (response).  Note down the public IP address, login name and password info. so that we can connect to this VM using SSH (secure shell).
Alternatively, if you prefer you can use SSH based authentication to connect to the Linux VM.  The steps for creating and using an SSH key pair for Linux VMs in Azure is documented [here](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys).  You can then specify the location of the public key with the `--ssh-key-path` option to the `az vm create ...` command.
```
az vm create --resource-group myResourceGroup --name k8s-lab --image OpenLogic:CentOS:7.4:7.4.20180118 --size Standard_B2s --generate-ssh-keys --admin-username labuser --admin-password <password> --authentication-type password
```

4.  Install Azure CLI and Git client on this VM.  Then clone this GitHub repository to this VM. Refer to the commands below.
```
# Open a terminal window and SSH into the VM.  Substitute your public IP address in the command below.
$ ssh labuser@x.x.x.x
#
# Next, we will install Azure CLI on this VM so that we can to deploy this application to the AKS cluster later in step [D].
#
# Import the Microsoft repository key.
$ sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
#
# Create the local azure-cli repository information.
$ sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
#
# Install with the yum install command.
$ sudo yum install azure-cli
#
# Test the install
$ az -v
#
# Login to your Azure account
$ az login -u <user name> -p <password>
#
# View help on az commands, sub-commands
$ az --help
#
# Install Git client
$ sudo yum install git
#
# Check Git version number
$ git --version
#
# Switch to home directory and clone this GitHub repository.  Later on you will also be forking this GitHub repository to get a separate copy of this project added to your GitHub account.  This will allow you to make changes to the application artifacts without affecting resources in the forked (original) GitHub project.
$ cd
$ git clone https://github.com/ganrad/k8s-springboot-data-rest.git
$ cd k8s-springboot-data-rest
```

5.  (Optional) Install OpenJDK 8 on the VM.  See commands below.
```
$ sudo yum install -y java-1.8.0-openjdk-devel
$ java --version
```

6.  Next, install **docker-ce** container runtime. Refer to the commands below.
```
$ sudo yum update
$ sudo yum install -y yum-utils device-mapper-persistent-data lvm2
$ sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
$ sudo yum install docker-ce-18.03.0.ce
$ sudo systemctl enable docker
$ sudo groupadd docker
$ sudo usermod -aG docker labuser
```

LOGOUT AND RESTART YOUR VM BEFORE PROCEEDING

```
$ sudo docker info
```

7.  Pull the Microsoft VSTS agent container from docker hub.  It will take a few minutes to download the image.
```
$ docker pull microsoft/vsts-agent
$ docker images
```

8.  Next, we will generate a VSTS personal access token (PAT) to connect our VSTS build agent to your VSTS account.  Login to VSTS using your account ID. In the upper right, click on your profile image and click **security**.  

![alt tag](./images/C-01.png)

Click on **Add** to create a new PAT.  In the next page, provide a short description for this token, select a expiry period and click **Create Token**.  See screenshot below.

![alt tag](./images/C-02.png)

In the next page, make sure to **copy and store** the PAT (token) into a file.  Keep in mind, you will not be able to retrieve this token again.  Incase you happen to lose or misplace the token, you will need to generate a new PAT and use it to reconfigure the VSTS build agent.  So save this PAT (token) to a file.

9.  Use the command below to start the VSTS build container.  Substitute the correct value for **VSTS_TOKEN** parameter, the value which you copied and saved in a file in the previous step.  The VSTS build agent will initialize and you should see a message indicating "Listening for Jobs".
```
docker run -e VSTS_ACCOUNT=ganrad -e VSTS_TOKEN=<xyz> -v /var/run/docker.sock:/var/run/docker.sock --name vstsagent -it microsoft/vsts-agent
```

### B] Deploy Azure Container Registry (ACR)
In this step, we will deploy an instance of Azure Container Registry to store container images which we will build in later steps.  A container registry such as ACR allows us to store multiple versions of application container images in one centralized repository and consume them from multiple nodes (VMs/Servers) where our applications are deployed.

1.  Login to your Azure portal account.  Then click on **Container registries** in the navigational panel on the left.  If you don't see this option in the nav. panel then click on **All services**, scroll down to the **COMPUTE** section and click on the star beside **Container registries**.  This will add the **Container registries** option to the service list in the navigational panel.  Now click on the **Container registries** option.  You will see a page as displayed below.

![alt tag](./images/B-01.png)

2.  Click on **Add** to create a new ACR instance.  Give a meaningful name to your registry, select an Azure subscription, select the **Resource group** which you created in step [A] and leave the location as-is.  The location should default to the location assigned to the resource group.  Select the **Basic** pricing tier.  Click **Create** when you are done.

![alt tag](./images/B-02.png)

3.  From the Linux terminal window connected to the Bastion host, create a **Service Principal** and grant relevant permissions (role) to this principal.  This is required to allow our AKS cluster to pull container images from this ACR registry.
```
# List your Azure subscriptions.  Note down the subscription ID.  We will need it in the next step.
$ az account list
#
# (Optional) Select and use the appropriate subscription ID (value of 'id' from previous step) 
$ az account set --subscription <SUBSCRIPTION_ID>
#
# Create the Azure service principal.  Substitute values for SUBSCRIPTION_ID, RG_GROUP, REGISTRY_NAME & SERVICE_PRINCIPAL_NAME.  Specify a meaningful name for the service principal.
$ az ad sp create-for-rbac --scopes /subscriptions/<SUBSCRIPTION_ID>/resourcegroups/<RG_NAME>/providers/Microsoft.ContainerRegistry/registries/<REGISTRY_NAME> --role Contributor --name <SERVICE_PRINCIPAL_NAME>
```
**NOTE:** From the `JSON` output of the previous command, copy and save the values for **appId** and **password**.  We will need these values in step [D] when we deploy this application to AKS.

### C] Create a new Build definition in VSTS to deploy the Springboot microservice
In this step, we will define the tasks for building the microservice (binary artifacts) application and packaging (layering) it within a docker container.  The build tasks use **Maven** to build the Springboot microservice & **docker-compose** to build the application container.  During the application container build process, the application binary is layered on top of a base docker image (CentOS 7).  Finally, the built application container is pushed into ACR which we deployed in step [B] above.

Before proceeding with the next steps, feel free to inspect the dockerfile and source files in the GitHub repository (under src/...).  This will give you a better understanding of how continous deployment (CD) can be easily implemented using VSTS.

1.  Fork this GitHub repository to **your** GitHub account.  In the browser window, click on **Fork** in the upper right hand corner to get a separate copy of this project added to your GitHub account.  Remember you must be signed in to your GitHub account in order to fork this repository.

![alt tag](./images/A-01.png)

2.  If you haven't already done so, login to VSTS using your account ID and create a new VSTS project. Give a name to your VSTS project.

![alt tag](./images/A-02.png)

3.  We will now create a **Build** definition and define tasks which will execute as part of the application build process.  Click on **Build and Release** in the top menu and then click on *Builds*.  Click on **New definition**

![alt tag](./images/A-03.png)

4.  In the **Select a source** page, select *GitHub* as the source repository. Give your connection a name and then select *Authorize using OAuth* link.  Optionally, you can use a GitHub *personal access token* instead of OAuth.  When prompted, sign in to your **GitHub account**.  Then select *Authorize* to grant access to your VSTS account.

5.  Once authorized, select the **GitHub Repo** which you forked in step [1] above.  Then hit continue.

![alt tag](./images/A-05.png)

6.  Search for text *Maven* in the **Select a template** field and then select *Maven* build.  Then click apply.

![alt tag](./images/A-06.png)

7.  Select *Default* in the **Agent Queue** field.  The VSTS build agent which you deployed in step [A] connects to this *queue* and listens for build requests.

![alt tag](./images/A-07.png)

8.  On the top extensions menu in VSTS, click on **Browse Markplace** and then search for text *replace tokens*.  In the results list below, click on **Colin's ALM Corner Build and Release Tools** (circled in yellow in the screenshot).  Then click on **Get it free** to install this extension in your VSTS account.

![alt tag](./images/A-08.PNG)

9.  Go back to your build definition and click on the plus symbol beside **Phase 1**.  Search by text *replace tokens* and then select the extension **Replace Tokens** which you just installed in the previous step.  Click **Add**.

![alt tag](./images/A-09.png)

10.  Click on the **Replace Tokens** task and drag it to the top of the task list.  In the **Source Path** field, select *src/main/resources* and specify `*.properties` in the **Target File Pattern** field.  In the **Token Regex** field, specify `__(\w+[.\w+]*)__` as shown in the screenshot below.  In the next step, we will use this task to specify the target kubernetes service name and namespace name.

![alt tag](./images/A-10.png)

11.  Click on the **Variables** tab and add a new variable to specify the Kubernetes service name and namespace name as shown in the screenshot below.

Variable Name | Value
------------- | ------
svc.name.k8s.namespace | mysql.development

![alt tag](./images/A-11.png)

12.  Switch back to the **Tasks** tab and click on the **Maven** task.  Specify values for fields **Goal(s)**, **Options** as shown in the screen shot below.  Ensure **Publish to TFS/Team Services** checkbox is enabled.

![alt tag](./images/A-12.png)

13.  Go thru the **Copy Files...** and **Publish Artifact:...** tasks.  These tasks copy the application binary artifacts (*.jar) to the **drop** location on the VSTS server.

14.  Next, we will package our application binary within a container.  Review the **docker-compose.yml** and **Dockerfile** files in the source repository to understand how the application container image is built.  Click on the plus symbol to add a new task. Search for task *Docker Compose* and click **Add**.

![alt tag](./images/A-14.png)

15.  Click on the *Run a Docker Compose ...* task on the left panel.  Specify *Azure Container Registry* for **Container Registry Type**.  In the **Azure Subscription** field, select your Azure subscription.  Click on **Authorize**.  In the **Azure Container Registry** field, select the ACR which you created in step [B] above.  Check to make sure the **Docker Compose File** field is set to `**/docker-compose.yml`.  Enable **Qualify Image Names** checkbox.  In the **Action** field, select *Build service images* and also enable **Include Latest Tag** checkbox.  See screenshot below.

![alt tag](./images/A-15.PNG)

16.  Once our application container image has been built, we will push it into the ACR.  Let's add another task to publish the container image built in the previous step to ACR.  Similar to step [15], search for task *Docker Compose* and click **Add**.

17.  Click on the *Run a Docker Compose ...* task on the left.  Specify *Azure Container Registry* for **Container Registry Type**.  In the **Azure Subscription** field, select your Azure subscription.  In the **Azure Container Registry** field, select the ACR which you created in step [B] above.  Check to make sure the **Docker Compose File** field is set to `**/docker-compose.yml`.  Enable **Qualify Image Names** checkbox.  In the **Action** field, select *Push service images* and also enable **Include Latest Tag** checkbox.  See screenshot below.

![alt tag](./images/A-17.PNG)

18.  Click **Save and Queue** to save the build definition and queue it for execution. Wait for the build process to finish.  When all build tasks complete OK and the build process finishes, you will see the screen below.

![alt tag](./images/A-18.png)

In the VSTS build agent terminal window, you will notice that a build request was received from VSTS and processed successfully. See below.

![alt tag](./images/A-19.png)

### D] Create an Azure Container Service (AKS) cluster and deploy our Springboot microservice
In this step, we will first deploy an AKS cluster on Azure.  Our Springboot **Purchase Order** microservice application reads/writes purchase order data from/to a relational (MySQL) database.  So we will deploy a **MySQL** database container (ephemeral) first and then deploy our Springboot Java application.  Kubernetes resources (object definitions) are usually specified in manifest files (yaml/json) and then submitted to the API Server.  The API server is responsible for instantiating corresponding objects and bringing the state of the system to the desired state.

Kubernetes manifest files for deploying the **MySQL** and **po-service** (Springboot application) containers are provided in the **k8s-scripts/** folder in the GitHub repository.  There are two manifest files in this folder **mysql-deploy_v1.8.yaml** and **app-deploy_v1.8.yaml**.  As the names suggest, the *mysql-deploy* manifest file is used to deploy the **MySQL** database container and the other file is used to deploy the **Springboot** microservice respectively.

Before proceeding with the next steps, feel free to inspect the Kubernetes manifest files to get a better understanding of the following.  These are all out-of-box capabilities provided by Kubernetes.
-  How confidential data such as database user names & passwords are injected (at runtime) into the application container using **Secrets**
-  How application configuration information such as database connection URL and the database name parameters are injected (at runtime) into the application container using **ConfigMaps**
-  How **environment variables** such as the MySQL listening port is injected (at runtime) into the application container.
-  How services in Kubernetes can auto discover themselves using the built-in **Kube-DNS** proxy.

In case you want to modify the default values used for MySQL database name and/or database connection properties (user name, password ...), refer to [Appendix A](#appendix-a) for details.  You will need to update the Kubernetes manifest files.

Follow the steps below to provision the AKS cluster and deploy the *po-service* microservice.
1.  Ensure the *Resource provider* for AKS service is enabled (registered) for your subscription.  A quick and easy way to verify this is, use the Azure portal and go to *->Azure Portal->Subscriptions->Your Subscription->Resource providers->Microsoft.ContainerService->(Ensure registered)*.  Alternatively, you can use Azure CLI to register all required service providers.  See below.
```
az provider register -n Microsoft.Network
az provider register -n Microsoft.Storage
az provider register -n Microsoft.Compute
az provider register -n Microsoft.ContainerService
```

2.  Switch back to the Linux VM (Bastion Host) terminal window where you have Azure CLI installed and make sure you are logged into to your Azure account.  We will install **kubectl** which is a command line tool for administering and managing a Kubernetes cluster.  Refer to the commands below in order to install *kubectl*.
```
# Switch to your home directory
$ cd
#
# Create a new directory 'aztools' under home directory to store the kubectl binary
$ mkdir aztools
#
# Install kubectl binary in the new directory
$ az aks install-cli --install-location=./aztools/kubectl
#
# Add the location of kubectl binary to your search path
$ export PATH=$PATH:/home/labuser/aztools
#
# Check if kubectl is installed OK
$ kubectl version -o yaml
```

3.  Refer to the commands below to create an AKS cluster.  If you haven't already created a **resource group**, you will need to create one first.  If needed, go back to step [A] and review the steps for the same.  Cluster creation will take a few minutes to complete.
```
# Create the AKS cluster
$ az aks create --resource-group myResourceGroup --name akscluster --node-count 1 --dns-name-prefix akslab --generate-ssh-keys
```

4.  Connect to the AKS cluster.
```
# Configure kubectl to connect to the AKS cluster
$ az aks get-credentials --resource-group myResourceGroup --name akscluster
#
# Check cluster nodes
$ kubectl get nodes -o wide
#
# Check default namespaces in the cluster
$ kubectl get namespaces
```

5.  Next, create a new Kubernetes **namespace** resource.  This namespace will be called *development*.  
```
# Make sure you are in the *k8s-springboot-data-rest* directory.
$ kubectl create -f dev-namespace.json 
#
# List the namespaces
$ kubectl get namespaces
```

6.  Create a new Kubernetes context and associate it with the **development** namespace.  We will be deploying all our application artifacts into this namespace in subsequent steps.
```
# Create the 'dev' context
$ kubectl config set-context dev --cluster=akscluster --user=clusterUser_myResourceGroup_akscluster --namespace=development
#
# Switch the current context to 'dev'
$ kubectl config use-context dev
#
# Check your current context (should list 'dev' in the output)
$ kubectl config current-context
```

7.  Configure Kubernetes to use the ACR (configured in step [B]) to pull our application container images and deploy containers.
When creating deployments, replica sets or pods, AKS (Kubernetes) will try to use docker images already stored locally (on nodes) or pull them from the public docker hub.  To change this, we need to specify the ACR as part of Kubernetes object configuration (yaml or json).  Instead of specifying this directly in the configuration, we will use Kubernetes **Secrets**.  By using secrets, we tell the Kubernetes runtime to use the info. contained in the secret to authenticate against ACR and push/pull images.  In the Kubernetes object (pod definition), we reference the secret by it's name only.

kubectl parameter | Value to substitute
----------------- | -------------------
SERVICE_PRINCIPAL_ID | 'appId' value from step [B]
YOUR_PASSWORD | 'password' value from step [B]

```
# Create a secret containing credentials to authenticate against ACR.  Substitute values for REGISTRY_NAME, YOUR_MAIL, SERVICE_PRINCIPAL ID and YOUR_PASSWORD.
$ kubectl create secret docker-registry acr-registry --docker-server <REGISTRY_NAME>.azurecr.io --docker-email <YOUR_MAIL> --docker-username=<SERVICE_PRINCIPAL_ID> --docker-password <YOUR_PASSWORD>
#
# List the secrets
$ kubectl get secrets
```

8.  Update the **app-deploy_v1.8.yaml** file.  The *image* attribute should point to your ACR.  This will ensure AKS pulls the application container image from the correct registry. Substitute the correct value for the *ACR registry name* in the *image* attribute (highlighted in yellow) in the pod spec as shown in the screenshot below.

![alt tag](./images/D-01.PNG)

9.  Deploy the **MySQL** database container.
```
$ kubectl create -f mysql-deploy_v1.8.yaml
#
# List pods.  You can specify the '-w' switch to watch the status of pod change.
$ kubectl get pods
```
The status of the mysql pod should change to *Running*.  See screenshot below.

![alt tag](./images/D-02.png)

(Optional) You can login to the mysql container using the command below. Specify the correct value for the pod ID.
```
$ kubectl exec <pod ID> -i -t -- mysql -u mysql -p sampledb
```

10.  Deploy the **po-service** microservice container.
```
$ kubectl create -f app-deploy_v1.8.yaml
#
# List pods.  You can specify the '-w' switch to watch the status of pod change.
$ kubectl get pods
```
The status of the mysql pod should change to *Running*.  See screenshot below.

![alt tag](./images/D-03.png)

11.  (Optional) As part of deploying the *po-service* Kubernetes service object, an Azure cloud load balancer gets auto-provisioned and configured. The load balancer accepts HTTP requests for our microservice and re-directes all calls to the service endpoint (port 8080).  Take a look at the Azure load balancer.

![alt tag](./images/D-04.png)

### E] Accessing the Purchase Order Microservice REST API 

As soon as the **po-service** application is deployed in AKS, 2 purchase orders will be inserted into the backend (MySQL) database.  The inserted purchase orders have ID's 1 and 2.  The application's REST API supports all CRUD operations (list, search, create, update and delete) on purchase orders.

In a Kubernetes cluster, applications deployed within pods communicate with each other via services.  A service is responsible for forwarding all incoming requests to the backend application pods.  A service can also expose an *External IP Address* so that applications thatare external to the AKS cluster can access services deployed within the cluster.

Use the command below to determine the *External* (public) IP address (Azure load balancer IP) assigned to the service end-point.
```
# List the kubernetes service objects
$ kubectl get svc
```
The above command will list the **IP Address** (both internal and external) for all services deployed within the *development* namespace as shown below.  Note how the **mysql** service doesn't have an *External IP* assisgned to it.  Reason for that is, we don't want the *MySQL* service to be accessible from outside the AKS cluster.

![alt tag](./images/E-01.png)

The REST API exposed by this microservice can be accessed by using the _context-path_ (or Base Path) `orders/`.  The REST API endpoint's exposed are as follows.

URI Template | HTTP VERB | DESCRIPTION
------------ | --------- | -----------
orders/ | GET | To list all available purchase orders in the backend database.
orders/{id} | GET | To get order details by `order id`.
orders/search/getByItem?{item=value} | GET | To search for a specific order by item name
orders/ | POST | To create a new purchase order.  The API consumes and produces orders in `JSON` format.
orders/{id} | PUT | To update a new purchase order. The API consumes and produces orders in `JSON` format.
orders/{id} | DELETE | To delete a purchase order.

You can access the Purchase Order REST API from your Web browser, e.g.:

- http://<Azure_load_balancer_ip>/orders
- http://<Azure_load_balancer_ip>/orders/1

Use the sample scripts in the *./scripts* folder to test this microservice.

### Appendix A
In case you want to change the name of the *MySQL* database name, root password, password or username, you will need to make the following changes.  See below.

- Update the *Secret* object **mysql** in file *./k8s-scripts/mysql-deploy_v1.8.yaml* file with appropriate values (replace 'xxxx' with actual values) by issuing the commands below.
```
# Create Base64 encoded values for the MySQL server user name, password, root password and database name. Repeat this command to generate values for each property you want to change.
$ echo "xxxx" | base64 -w 0
# Then update the corresponding parameter value in the Secret object.
```

- Update the *./k8s-scripts/app-deploy_v1.8.yaml* file.  Specify the correct value for the database name in the *ConfigMap* object **mysql-db-name** parameter **mysql.dbname** 

- Update the *Secret* object **mysql-sql** in file *./k8s-scripts/app-deploy_v1.8.yaml* file with appropriate values (replace 'xxxx' with actual values) by issuing the commands below.
```
# Create Base64 encoded values for the MySQL server user name and password.
$ echo "mysql.user=xxxx" | base64 -w 0
$ echo "mysql.password=xxxx" | base64 -w 0
# Then update the *db.username* and *db.password* parameters in the Secret object accordingly.

```

Congrats!  You have just built and deployed a Java Springboot microservice on Azure Kubernetes Service!!
