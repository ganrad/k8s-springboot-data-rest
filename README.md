#  This project describes the steps for building and deploying a Java Springboot microservice application on Azure Kubernetes Service (AKS) running on Microsoft Azure.

In a nutshell, you will work on the following two activities.
1.  Build a Springboot Java Microservice Application (API Endpoint) using VSTS (Visual Studio Team Services and 
2.  Deploy the containerized Java microservice application in Azure Kubernetes Service (AKS) running on Azure

**Prerequisities:**
1.  A Visual Studio Team Services Account.  If required, create a free VSTS account by accessing the [Visual Studio Team Services](https://www.visualstudio.com/team-services/) website.
2.  An active Microsoft Azure subscription.  If required, you can obtain a free subscription by accessing the [Microsoft Azure](https://azure.microsoft.com/en-us/?v=18.12) website.

This Springboot application demonstrates how to build and deploy a *Purchase Order* microservice as a containerized application (po-service) on Azure Kubernetes Service (AKS) on Microsoft Azure. The deployed microservice supports all CRUD operations on purchase orders.

### A] Deploy a VSTS application build agent in a separate Azure VM
This agent is used by VSTS to run application and container builds.  Follow instructions below to create a VM and deploy the VSTS build (docker) container.


### B] Deploy Azure Container Registry (ACR) on Azure

### C] Create a new Build definition in VSTS
1.  Fork this GitHub repository.

2.  Login to VSTS using your account ID and create a new VSTS project. Name the project **sb-po-service**

![alt tag](./images/A-02.png)

3.  Click on **Build and Release** in the top menu and then click on *Builds*.  Click on **New definition**

![alt tag](./images/A-03.png)

4.  In the **Select a source** page, select *GitHub* as the source repository. Give your connection a name and then select *Authorize using OAuth* link.  Optionally, you can use a GitHub *personal access token* instead of OAuth.  When prompted, sign in to your **GitHub account**.  Then select *Authorize* to grant access to your VSTS account.

5.  Once authorized, select the **GitHub Repo** which you forked in step [1] above.  Then hit continue.

![alt tag](./images/A-05.png)

6.  Search for text *Maven* in the **Select a template** field and then select *Maven* build.  Then click apply.

![alt tag](./images/A-06.png)

7.  Select *Default* in the **Agent Queue** field.  The VSTS build agent connects to this *queue* and listens for build requests.

![alt tag](./images/A-07.png)

8.  On the top extensions menu in VSTS, click on **Browse Markplace** and then search for text *replace tokens*.  In the results list below, click on **Colin's ALM Corner Build and Release Tools**.  Then click on **Get it free** to install this extension in your VSTS account.

![alt tag](./images/A-08.png)

9.  Go back to your build definition and click on the plus symbol beside **Phase 1**.  Search by text *replace tokens* and then select the extension **Replace Tokens** which you just installed in the previous step.  Click **Add**.

![alt tag](./images/A-09.png)

10.  Click on the **Replace Tokens** task and drag it to the top of the task list.  In the **Source Path** field, select *src/main/resources* and specify *.properties in the **Target File Pattern** field.  In the **Token Regex** field, specify **__(\w+[.\w+]*)__** as shown in the screenshot below.  We will use this task to specify the target kubernetes service name and namespace name before running this build.

![alt tag](./images/A-10.png)

11.  Click on the **Variables** tab and add a new variable to specify the Kubernetes service name and namespace name as shown in the screenshot below.

![alt tag](./images/A-11.png)

12.  Switch back to the **Tasks** tab and click on the **Maven** task.  Specify values for fields **Goal(s)**, **Options** as shown in the screen shot below.  Ensure **Publish to TFS/Team Services** checkbox is enabled.

![alt tag](./images/A-12.png)

13.  Go thru the **Copy Files...** and **Publish Artifact:...** tasks.  These tasks copy the application binary artifacts (*.jar) to the **drop** location on the VSTS server.

14.  Click on the plus symbol to add a new task. Search for text *Docker Compose* and click **Add**.

![alt tag](./images/A-14.png)

15.  Click on the **Run a Docker Compose ...* task on the left.  Specify *Azure Container Registry* for **Container Registry Type**.  In the**Azure Subscription** field, select your Azure subscription.  Click on **Authorize**.  In the **Azure Container Registry** field, select the ACR which you created in step [B] above.  Check to make sure the **Docker Compose File** field is set to **/docker-compose.yml.  Enable **Qualify Image Names** checkbox.  In the **Action** field, select *Build service images* and also enable **Include Latest Tag** checkbox.  See screenshot below.

![alt tag](./images/A-15.PNG)

16.  Add another task to publish the container image built in the previous step to ACR. Search by text *Docker Compose* and click **Add**.

17.  Click on the **Run a Docker Compose ...* task on the left.  Specify *Azure Container Registry* for **Container Registry Type**.  In the**Azure Subscription** field, select your Azure subscription.  In the **Azure Container Registry** field, select the ACR which you created in step [B] above.  Check to make sure the **Docker Compose File** field is set to **/docker-compose.yml.  Enable **Qualify Image Names** checkbox.  In the **Action** field, select *Push service images* and also enable **Include Latest Tag** checkbox.  See screenshot below.

![alt tag](./images/A-17.PNG)

18.  Click **Save and Queue** to save the build definition and queue it for execution.

First, create a new project in OpenShift using the Web Console (UI).
First, create a new project in OpenShift using the Web Console (UI).
Name the project as *myproject*.
### B] Deploy a ephemeral MySql database server instance (Pod) in OpenShift.
Name the application as *mysql*.  Specify the following values for the database parameters
```
Database service name = mysql
Database name = sampledb
Database user name = mysql
Database password = password
```
### C] Deploy the *Purchase Order* microservice application on OpenShift CP.
1.  Download *mysqldb.properties* and *mysql-secret.yaml* files from this project to your local machine.
2.  For this po-service application, we will store the MySql database name in a *ConfigMap* and inject this value into our po-service application Pod.  Use the commands below to create the *mysql-db-name* ConfigMap in your project and list it's contents.
```
oc create configmap mysql-db-name --from-file=./mysqldb.properties
oc get configmaps mysql-db-name -o yaml
```
3.  We will store the MySql database user name and password in a *Secret* and inject these values into the application Pod. Next, generate a *Base64* encoded value for the MySql server user name and password. See the commands below.
```
$ echo "mysql.user=mysql" | base64 -w 0
$ echo "mysql.password=password" | base64 -w 0
```
4.  Substitute the *Base64* encoded values for the MySql server user name and password in the *mysql-secret.yaml* file as shown below.
```
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
data:
  db.username: bXlzcWwudXNlcj1teXNxbAo=
  db.password: bXlzcWwucGFzc3dvcmQ9cGFzc3dvcmQK
```
5. Create the secret API object in your project/namespace.
```
$ oc create -f mysql-secret.yaml
```
6. List the secret objects in your project/namespace.
```
$ oc get secrets
```
7. Add the *mysql-secret* secret to the default Service Account.
```
$ oc secrets add serviceaccount/default secret/mysql-secret --for=mount
```
8. Use the OpenShift Web Console (UI) to deploy the Springboot application instance (Pod) in OpenShift. Name the application as *po-service*.  Allow the application build to finish and the application Pod to come up (start).  The application Pod will start and terminate as we have not injected the secret (*mysql-secret*) containing the database user name and password into the Pod yet.  We will do this in the next step.
9.  Use the command below to mount the *mysql-db-name" ConfigMap into your appliction Pod.
```
$ oc volume dc/po-service --add --name=mysqlcm --type=configmap --configmap-name='mysql-db-name' --mount-path='/etc/config'
```
The above command will trigger a new application deployment.  Wait for the deplooyment to finish.

10.  Use the command below to mount the *mysql-secret* Secret into your application Pod.
```
$ oc volume dc/po-service --add --name=mysqlse --type=secret --secret-name='mysql-secret' --mount-path='/etc/vol-secrets'
```
The above command will trigger another application deployment.  Wait for the deployment to finish.  As soon as the deployment finishes, the *po-service* application Pod should start Ok.  The application should now be able to connect to the backend MySql database.

11.  Test the microservice by using the *scripts* in the */scripts* directory.  The microservice exposes a HATEAS API and supports all CRUD operations on purchase orders.

12.  (Optional) Use the command below to export all API objects to a (reusable) template.  This template can be used for deploying the *po-service* applicaton along with all it's dependencies (MySql server, secrets, configmaps ...) in other regions easily.
```
$ oc export is,secret,configmap,bc,dc,svc,route --as-template=springboot-po-service -o json > kubernetes.json
```

13.  (Optional) Create a project *myproject* and import the application template into this project.
```
$ oc new-project myproject
$ oc create -f kubernetes.json
```

14.  (Optional) Use the OpenShift Web Console (UI) to deploy the *mysql* database server Pod and *po-service* microservice Pod with a single click.  Select the *springboot-po-service* template in the S2I application deployment wizard. 

Congrats!  You have just built and deployed a simple Springboot microservice on OpenShift CP.
