## Create an Azure Container Service (AKS) cluster and then use *Kubernetes Dashboard* to deploy the *po-service* Springboot Java Microservice

In order to access the Kubernetes Dashboard (Web UI), a PC (or a VM) running MacOS or Linux Desktop OS such as Fedora/Ubuntu/Debian (any Linux flavor) will be required.  Alternatively, a Windows 10 PC running Ubuntu/Debian/SLES Linux OS on Windows Sub-System for Linux should also work.  Azure CLI v2.0.4 or later **should** be installed on this VM/Machine.  Refer to the [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) documentation to install Azure CLI on this machine.
For the remainder of this text, this machine (Linux/MacOS/Windows) will be referred to as the **Host** machine.

You will first deploy an AKS cluster on Azure using the Azure Portal.  You will then use the Kubernetes Dashboard (Web) UI to deploy the **MySQL** database and **po-service** application containers.

YAML files for deploying all required Kubernetes objects (API resources) are provided in the [k8s-scripts](./k8s-scripts) sub-directory.  Before proceeding with the next steps, we highly recommend that you go thru the Kubernetes object definition files in this directory.


### Provision the AKS cluster
1.  Open a terminal window on the **Host** machine & use Azure CLI to login to your Azure account.  Next, install **kubectl** which is a command line tool for administering and managing a Kubernetes cluster.  Refer to the commands below in order to install *kubectl*.
```
# (Optional) Login to your Azure account.  Substitute correct values for <Azure account id> and <password>.
$ az login -u <Azure account id> -p <password>
#
# Switch to your home directory
$ cd
#
# Create a new directory 'aztools' under home directory to store the kubectl binary
$ mkdir aztools
#
# Install kubectl binary in the new directory
$ az aks install-cli --install-location=./aztools/kubectl
#
# Add the location of 'kubectl' binary to your search path and export it.
# Alternatively, add the export command below to your '.bashrc' file in your home directory. Then logout of your Host (VM) from the terminal window and log back in for changes to take effect.  By including this command in your '.bashrc' file, you don't have to set the location of the 'kubectl' binary in the PATH environment variable and export it every time you open a new terminal window.
$ export PATH=$PATH:/home/labuser/aztools
#
# Check if kubectl is installed OK
$ kubectl version -o yaml
```

2.  Using a web browser, login to the [Azure portal](https://portal.azure.com) using your account ID and password.  Verify that you have adequate permissions to register applications.  See screenshot below.

![alt tag](./images/Az-01.PNG)

3.  Search for **Kubernetes services (PREVIEW)** PaaS service in **All services**. Click on the link to open up the blade (detail panel).  Then click on *Create Kubernetes service* button.

![alt tag](./images/k8s-dash-deploy-01.PNG)

In the *Basics* tab, leave the default value for **Service principal** and specify values for **Subscription**, **Resource group**, **Kubernetes cluster name** & **DNS name prefix** as shown in the screenshot below.  Also, change the value of field **Node count** to **1** or else AKS will deploy a 3-node cluster (default).  Click **Next:Networking**.

![alt tag](./images/k8s-dash-deploy-02.PNG)

Leave all the default values as-is on the **Networking** tab.  Click **Next:Monitoring**.

![alt tag](./images/k8s-dash-deploy-03.PNG)

Leave the default values on the **Monitoring** and **Tags** tabs and click on **Review + create** button.

![alt tag](./images/k8s-dash-deploy-04.PNG)

In the summary page, review all the details and then click on **Create**.

![alt tag](./images/k8s-dash-deploy-041.PNG)

The AKS cluster will take a few minutes (5-10 mins) to get provisioned.  Once the cluster creation process finishes, the **akscluster** cluster will be displayed in the list as shown in the screenshot below.

![alt tag](./images/k8s-dash-deploy-05.PNG)

4.  Switch back to the *Host* terminal window and start the Kubernetes Dashboard proxy using **one** of the options listed below
- Use the Kubernetes proxy (kubectl) to connect to Kubernetes Dashboard
```
# Configure kubectl to connect to the AKS cluster
$ az aks get-credentials --resource-group myResourceGroup --name akscluster
#
# Start the Kubernetes dashboard proxy
$ kubectl proxy -p 8001
```
- Use Azure AKS CLI to connect to the Kubernetes Dashboard
```
# Configure kubectl to connect to the AKS cluster
$ az aks get-credentials --resource-group myResourceGroup --name akscluster
#
# Start the Kubernetes dashboard by running the following command
$ az aks browse --name akscluster --resource-group myResourceGroup
```

5.  Open another browser tab and point your browser to the Kubernetes dashboard URL [http://localhost:8001/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/](http://localhost:8001/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/)

6.  Next, create a new Kubernetes **namespace** called *development*.  In the Kubernetes **Dashboard**, click on *Namespaces* under *Cluster* on the left navigational panel.  Then click on *CREATE* link on the top.  This will open up a YAML/JSON editor (shown below).  Cut and paste the contents of file **./k8s-scripts/dev-namespace.json** into the editor, then click *Upload*.  See the screenshots below.  Alternatively, use the *Create From File* tab to upload an YAML/JSON file containing Kubernetes resource/object definition and create corresponding object on the Kubernetes API Server.

![alt tag](./images/k8s-dash-deploy-06.PNG)

![alt tag](./images/k8s-dash-deploy-07.PNG)

7.  Before proceeding, make sure you have selected the **development** namespace in the Kubernetes Dashboard UI.  This is extremely important. Otherwise the Kubernetes API objects might get created in the wrong namespace (eg., default).  See the screenshot below.

![alt tag](./images/k8s-dash-deploy-24.PNG)

8.  Switch back to the terminal window.  Create the **dev** Kubernetes context and make it the current context.  We will be deploying the **MySQL** and **po-service** application pods and all associated Kubernetes resources (objects) within this namespace.
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

9.  Configure Kubernetes to pull application container image (`po-service`) from ACR (configured in step [B]) and deploy a container instance.  When creating deployments, replica sets or pods, AKS (Kubernetes) will try to use docker images already stored locally (on nodes) or pull them from the public docker hub.  To change this, we need to specify the ACR as part of Kubernetes object configuration (yaml or json).  Instead of specifying this directly in the configuration, we will use Kubernetes **Secrets**.  By using secrets, we tell the Kubernetes runtime to use the info. contained in the secret to authenticate against ACR and push/pull images.  In the Kubernetes object (pod definition), we reference the secret by it's name only.

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

If you are familiar with Kubernetes API/Object model then you can skip to [Deploy All Kubernetes API Objects](#deploy-all-kubernetes-api-objects).  This will deploy all application artifacts to AKS.

Alternatively, if you are new to Kubernetes then you may want to proceed with the next steps.  This will give you the opportunity to study/deploy each object individually and help you understand the relationships between the objects (Kubernetes API/Object Model), how everything ties together.  

### Deploy Kubernetes API Objects Step By Step
1.  Use the Kubernetes Dashboard (Web UI) to deploy the **MySQL** database resources on Kubernetes.
-  Create the MySQL Secret API object.  Click on *Secrets* link on the left navigational panel and then click on *Create* link on the top.  Cut and paste the contents of file *./k8s-scripts/mysql-secret.yaml* into the editor and click *UPLOAD*.  Alternatively, you can also use the *Create From File* option to upload the contents of this file and create the Secret API object.

![alt tag](./images/k8s-dash-deploy-08.PNG)

![alt tag](./images/k8s-dash-deploy-09.PNG)

-  Create the MySQL Service API object.  Click on the *Services* link on the left navigational panel and then click on *Create* link on the top.  Cut and paste the contents of file *./k8s-scripts/mysql-svc.yaml* into the editor and then click *UPLOAD*.  Alternatively, use the *Create From File" option to upload the contents of this file and create the Service API object.

![alt tag](./images/k8s-dash-deploy-10.PNG)

![alt tag](./images/k8s-dash-deploy-11.PNG)

-  Create the MySQL *Deployment* API object.  Click on the *Deployments* link on the left navigational panel and then click on *Create* link on the top.  Cut and paste the contents of file *./k8s-scripts/mysql-deployment.yaml* into the editor and then click *UPLOAD*.  Alternatively, use the *Create From File" option to upload the contents of this file and create the Kubernetes Deployment API object.

![alt tag](./images/k8s-dash-deploy-12.PNG)

![alt tag](./images/k8s-dash-deploy-13.PNG)

![alt tag](./images/k8s-dash-deploy-14.PNG)

2.  Update the file **k8s-scripts/app-deployment.yaml**.  The *image* attribute should point to **your** ACR instance.  This will ensure AKS pulls the application container image from the correct registry.  Substitute the correct value for the ACR *registry name* in the *image* attribute (highlighted in yellow) within the *containers section* as shown in the screenshot below.

![alt tag](./../../images/D-01.PNG)

3.  Use the Kubernetes Dashboard (Web UI) to deploy the **po-service** Springboot application resources on Kubernetes.
-  Create the Config Map API object.  Click on *Config Maps* link on the left navigational panel and then click on *Create* link on the top.  Cut and paste the contents of file *./k8s-scripts/app-config-map.yaml* into the editor and click *UPLOAD*.  Alternatively, you can also use the *Create From File* option to upload the contents of this file and create the Configmap API object.

![alt tag](./images/k8s-dash-deploy-15.PNG)

![alt tag](./images/k8s-dash-deploy-16.PNG)

-  Create the Secret API object.  Click on the *Secrets* link on the left navigational panel and then click on *Create* link on the top.  Cut and paste the contents of file *./k8s-scripts/app-mysql-secret.yaml* into the editor and then click *UPLOAD*.  Alternatively, use the *Create From File" option to upload the contents of this file and create the Secret API object.

![alt tag](./images/k8s-dash-deploy-17.PNG)

![alt tag](./images/k8s-dash-deploy-18.PNG)

-  Create the Service API object.  Click on the *Services* link on the left navigational panel and then click on *Create* link on the top.  Cut and paste the contents of file *./k8s-scripts/app-service.yaml* into the editor and then click *UPLOAD*.  Alternatively, use the *Create From File" option to upload the contents of this file and create the Service API object.

![alt tag](./images/k8s-dash-deploy-19.PNG)

![alt tag](./images/k8s-dash-deploy-20.PNG)

-  Create the po-service *Deployment* API object.  Click on the *Deployments* link on the left navigational panel and then click on *Create* link on the top.  Cut and paste the contents of file *./k8s-scripts/app-deployment.yaml* into the editor and then click *UPLOAD*.  Alternatively, use the *Create From File" option to upload the contents of this file and create the Kubernetes Deployment API object.

![alt tag](./images/k8s-dash-deploy-21.PNG)

![alt tag](./images/k8s-dash-deploy-22.PNG)

![alt tag](./images/k8s-dash-deploy-23.PNG)

You can now go back to the [k8s-springboot-data-rest](https://github.com/ganrad/k8s-springboot-data-rest#accessing-the-purchase-order-microservice-rest-api) GitHub project and follow the instructions for testing the **po-service** microservice application.

### Deploy All Kubernetes API Objects
1.  Update the file **k8s-scripts/deploy-app.yaml**.  The *image* attribute should point to **your** ACR instance.  This will ensure AKS pulls the application container image from the correct registry.  Substitute the correct value for the ACR *registry name* in the *image* attribute (highlighted in yellow) within the deployment API object (*containers section*) as shown in the screenshot below.

![alt tag](./../../images/D-01.PNG)

2.  Use the Kubernetes Dashboard (Web UI) to deploy the Springboot application resources on Kubernetes.  In the **Overview** page of the Kubernetes Dashboard UI, click on **CREATE** link on the top.  Cut and paste the contents of file *./k8s-scripts/deploy-app.yaml* into the editor and click *UPLOAD*.  Alternatively, you can also use the *Create From File* option to upload the contents of this file and create the Configmap API object.

![alt tag](./images/k8s-dash-deploy-25.PNG)

![alt tag](./images/k8s-dash-deploy-21.PNG)

![alt tag](./images/k8s-dash-deploy-22.PNG)

![alt tag](./images/k8s-dash-deploy-23.PNG)

You can now go to the [k8s-springboot-data-rest](https://github.com/ganrad/k8s-springboot-data-rest#accessing-the-purchase-order-microservice-rest-api) GitHub project and follow the steps for testing the **po-service** microservice application.
