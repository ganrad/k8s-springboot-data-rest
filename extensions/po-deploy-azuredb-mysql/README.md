## Use *Azure Database for MySQL* (PaaS) as the persistent data store for the po-service microservice application.

The overall goal of this project (extension) is summarized below.
- Demonstrate the use of **Open Service Broker for Azure** to provision and deploy a managed MySQL database server (instance) on Azure. OSBA is an implementation of **Open Service Broker API* specification and is used to expose public cloud services (PaaS) on container platforms such as AKS.  Applications deployed on container platforms can then seamlessly provision and consume public cloud (PaaS) services from DevOps pipelines.
- Demonstrate the use of **Helm** (CLI) for deploying containerized applications on Kubernetes (AKS).  Helm is a package manager for Kubernetes and is a part of [CNCF](https://www.cncf.io/). Helm is used for managing Kubernetes packages called *Charts*.  In layman's terms, a chart is a bundle of Kubernetes manifest files necessary to create an instance of a Kubernetes application.
- Demonstrate how to secure a microservice (REST API) end-point using **SSL/TLS** (HTTPS transport) and expose it thru the AKS Ingress Controller.

**Prerequisites:**
1.  Before working on the hands-on labs in this project, readers are required to complete all hands-on labs (Sections) in the [parent project](https://github.com/ganrad/k8s-springboot-data-rest).  In case you have come to this project directly, go back and finish the lab exercises in the parent project.
2.  Readers are required to be familiar with basic Linux commands.  Experience working in Linux environments will definitely be helpful.
3.  **Helm** CLI will be used to deploy the **Service Catalog**, **Open Service Broker for Azure** and the **po-service** microservice on AKS. Additionally, the **Service Catalog CLI** will be used to deploy a **Managed MySQL Database Server** on Azure.  Readers are advised to refer to the CLI documentation as needed.  Links to documentation are provided below.

**Description:**

In this project, we will first deploy a managed MySQL database server on Azure using **Open Service Broker for Azure** (OSBA).  Following that, we will configure MySQL database as the backend data store for the **po-service** microservice.

In a nutshell, you will work on the following tasks.
1. Install **Service Catalog** and **Open Service Broker for Azure (OSBA)** on AKS (Section [A])

   These components will be used to deploy managed PaaS services on Azure.

2. Deploy the **Azure Database for MySQL** instance (Section [B])

   The Service Catalog CLI will be used to provision a managed instance of MySQL on Azure.  The CLI will communicate with the OSBA API server on AKS to provision the managed PaaS service (MySQL) on Azure.

3. Redeploy the **po-service** microservice using Helm package manager (Section [C])

   The microservice will use the managed MySQL instance on Azure to persist *Purchase Orders*.

For easy and quick reference, readers can refer to the following on-line resources as needed.
- [Helm](https://docs.helm.sh/)
- [Open Service Broker API](https://www.openservicebrokerapi.org/)
- [Install Service Catalog CLI](https://svc-cat.io/docs/install/#installing-the-service-catalog-cli)
- [Azure Service Catalog CLI Documentation](https://github.com/Azure/service-catalog-cli)

**Important Notes:**
- Keep in mind that this is an **Advanced** lab for experienced Kubernetes users.  Before starting to work on the hands-on labs in this project, complete all sections in the parent project.

### A] Install *Service Catalog* and *Open Service Broker for Azure* (OSBA) on AKS
**Approx. time to complete this section: 45 mins to an hour**

Open a terminal window and use SSH to login to the Linux VM (Bastion Host) which you provisioned on Azure in the parent project.

1.  Add **Service Catalog** chart to the Helm repository.
    ```
    $ helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
    ```
    Run Helm to install **Service Catalog** containers on AKS.  The command below assumes the AKS cluster is not RBAC-enabled.  If your cluster is RBAC enabled, do not specify the *rbacEnable* flag when running the command.
    ```
    # If your cluster is not RBAC-enabled, run this command.
    $ helm install svc-cat/catalog --name catalog --namespace catalog --set rbacEnable=false --set controllerManager.healthcheck.enabled=false
    # If your cluster is RBAC-enabled, use the command below.
    # helm install svc-cat/catalog --name catalog --namespace catalog --set controllerManager.healthcheck.enabled=false
    ```
    The Service Catalog containers (Pods) will be deployed in the **catalog** namespace on AKS.  Use the command below to verify the catalog API service is installed.
    ```
    $ kubectl get apiservice
    ```
    The output of the above command should be as listed below (truncated for brevity).  The **v1beta1.servicecatalog.k8s.io** API service should be listed in the output. 
    ```
    NAME                                    AGE
    v1.                                     31d
    v1.apps                                 31d
    v1.authentication.k8s.io                31d
    v1.authorization.k8s.io                 31d
    v1.autoscaling                          31d
    ....
    v1beta1.servicecatalog.k8s.io           6d
    v1beta1.storage.k8s.io                  31d
    v1beta2.apps                            31d
    v2beta1.autoscaling                     31d
    ```

2.  Add **Open Service Broker for Azure** chart to the Helm repository.
    ```
    $ helm repo add azure https://kubernetescharts.blob.core.windows.net/azure
    ```
    Create an Azure Service Pricipal (SP) and assign `Contributor` role access to this SP.  This SP will be used by Open Service Broker for Azure component (containers) to provision PaaS services (MySQL) on Azure.  Use the provided shell script to create the SP.
    ```
    $ ./shell-scripts/create-sp-sub.sh
    ```
    The shell script should output a JSON and also save the output in a txt file *SP_SUB.txt* in the current directory.  Next, set environment variables by substituting the correct values as output by the SP creation command and run Helm to install the **Open Service Broker for Azure** containers on AKS.
    ```
    # Replace correct values for all environment variables before running this shell script !!!!
    #
    # Set the Azure client ID
    $ AZURE_CLIENT_ID=<appId>
    #
    # Set the Azure client secret
    $ AZURE_CLIENT_SECRET=<password>
    #
    # Set the Azure AD tenant ID
    $ AZURE_TENANT_ID=<tenant>
    #
    # Retrieve and set the user's Azure subscription ID in a variable
    $ AZURE_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
    #
    # Install the Open Service Broker for Azure components using Helm.
    $ helm install azure/open-service-broker-azure --name osba --namespace osba \
      --set azure.subscriptionId=$AZURE_SUBSCRIPTION_ID \
      --set azure.tenantId=$AZURE_TENANT_ID \
      --set azure.clientId=$AZURE_CLIENT_ID \
      --set azure.clientSecret=$AZURE_CLIENT_SECRET
    #
    ```
    The Open Service Broker for Azure containers (Pods) will be deployed in the **osba** namespace on AKS.

3.  List the Pods for *Service Catalog* and *Open Service Broker for Azure* services (containers).  Ensure all *Pods* have a status of `Running` before proceeding with the next step.
    ```
    # List the Service Catalog Pods
    $ kubectl get pods -n catalog 
    #
    # List the OSBA Pods
    $ kubectl get pods -n osba 
    #
    ```

4.  Use the Service Catalog CLI to list all service brokers.
    **NOTE:** The Service Catalog CLI should have been on the Linux VM (Bastion Host) in the parent project.

    ```
    # List service brokers running on the AKS instance
    $ svcat get brokers
    #
    ```
    The output of the above command should be as listed below.
    ```
      NAME                                URL                                STATUS
    +------+---------------------------------------------------------------+--------+
      osba   https://osba-open-service-broker-azure.osba.svc.cluster.local   Ready
    ```
    List the available service classes and plans.
    ```
    # List the service classes
    $ svcat get classes
    #
    # List the service plans
    $ svcat get plans
    #
    ```

### B] Deploy the *Azure Database for MySQL* instance
**Approx. time to complete this section: 30-45 mins**

1.  Create a new namespace **dev-azure-mysql** using Kubernetes CLI.  This namespace will be used to deploy another instance of **po-service** microservice.  The important thing to bear in mind here is that this microservice instance will use a managed instance of MySQL running on Azure to persist Purchase Orders.  
    ```
    # Create a new namespace to deploy the 'po-service' microservice
    $ kubectl create namespace dev-azure-mysql
    #
    # List the namespaces
    $ kubectl get namespaces
    #
    ```
    
2.  Install an instance of **Azure Database for MySQL** using Kubernetes CLI.

    Edit the file `k8s-resources/mysql-dbms-instance.yaml` and review the **ServiceInstance** API object definition for the managed database server instance.  Ensure the **resourceGroup** attribute value in the API object specifies the name of the Azure *Resource Group* which you provisioned in the parent project.  Also, specify a unique value for attribute **alias**.  The deployment of the PaaS service will fail if this value is a duplicate of another service.

    Use Kubernetes CLI to create the managed MySQL database server instance on Azure as shown in the command snippet below.
    ```
    # Provision the managed MySQL database server instance on Azure
    $ kubectl create -f ./k8s-resources/mysql-dbms-instance.yaml
    #
    ```

    Before proceeding, make sure the MySQL database server got provisioned and has a status of **Ready**.  Use the command below to check the status of the **Service Instance**.

    ```
    # List the deployed service instances. Verify the service is in 'Ready' state
    $ svcat get instances -n dev-azure-mysql
               NAME                   NAMESPACE             CLASS           PLAN    STATUS
    +--------------------------------+-----------------+----------------------+-------+--------+
    po-service-mysql-dbms-instance   dev-azure-mysql   azure-mysql-5-7-dbms   basic   Ready
    #
    ```

    Note that for this project, we will be provisioning the managed MySQL server in a **basic** service plan (a.k.a Pricing Tier).  The **Basic** service plan supports a maximum of 2 vCPUs, 1TB of storage and up to 35 days of data retention.  You can view the available service plans for all Azure managed services exposed by OSBA using `svcat` CLI.   You can also use the **Azure Portal** to view the various plans supported by *Azure Database for MySQL* PaaS service.

    Edit the file `k8s-resources/mysql-database-instance.yaml` and review the **ServiceInstance** API object definition for the database instance.  In this file, update the value for *parentAlias* attribute by specifying the same value which you specified for *alias* attribute in the MySQL database server API definition.  The *alias* attribute value in the database server definition and *parentAlias* attribute value in the database definition should match and be the same.

    Use Kubernetes CLI to create the database instance on the MySQL server as shown in the command snippet below.

    ```
    # Provision the database instance on the MySQL server
    $ kubectl create -f ./k8s-resources/mysql-database-instance.yaml
    #
    ```

    Initially, the *Service Instance* will have a status of **Provisioning** and it will take a few minutes for the database to get provisioned.  Before proceeding, make sure the MySQL database got provisioned and has a status of **Ready**.

    Use the command below to check the status.

    ```
    # List the deployed service instances.  This command should show both the service instances which we have provisioned using OSBA.
    $ svcat get instances -n dev-azure-mysql
                 NAME                     NAMESPACE               CLASS               PLAN     STATUS
    +------------------------------------+-----------------+--------------------------+----------+--------+
    po-service-mysql-database-instance   dev-azure-mysql   azure-mysql-5-7-database   database   Ready
    po-service-mysql-dbms-instance       dev-azure-mysql   azure-mysql-5-7-dbms       basic      Ready
    #
    ```

    Login to the Azure Portal and verify the MySQL database server instance got created OK.  See screenshot below.

    ![alt tag](./images/B-01.PNG)

    Also, verify the MySQL database got created.  The database name will be an arbitary name chosen by Azure.  See screenshot below.

    ![alt tag](./images/B-02.PNG)

    Open the file `k8s-resources/mysql-database-binding.yaml` and review the **ServiceBinding** API object definition.  A *Service Binding* creates a Kubernetes **Secret** object containing the connection details for the managed MySQL database instance on Azure.  The *Secret* object contains data tuples (name=value) for the database URI, database name, username, password & port information.  The MySQL database connection information will be injected as environment variables into the **po-service** microservice (next Section).

    Use Kubernetes CLI to create the database service binding (Secret) as shown in the command snippet below.

    ```
    # Create the 'ServiceBinding' API object.  This will create the 'mysql-secret' Secret object containing the MySQL database connection information.
    $ kubectl create -f ./k8s-resources/mysql-database-binding.yaml
    # List the secrets in the 'dev-azure-mysql' namespace
    $ kubectl get secrets -n dev-azure-mysql
    #
    # View the data stored in the 'mysql-secret' Secret object
    $ kubectl describe secret mysql-secret -n dev-azure-mysql
    #
    ```

### C] Redeploy the *po-service* microservice using Helm package manager
**Approx. time to complete this section: 1.5 Hour**

1.  Enable **HTTP application routing** addon on the AKS cluster.

    When a AKS cluster is created using the Azure Portal, **HTTP application routing** can be selected in the 'Networking' tab.  You can skip this step if you had enabled this option while creating the AKS cluster.
    Use the command below to enable this addon on the AKS cluster.   Remember to specify correct values for the Azure resource group and AKS cluster names.
    ```
    # Specify correct values for RESOURCE GROUP name and AKS CLUSTER name !!!!
    $ az aks enable-addons --resource-group myResourceGroup --name akscluster --addons http_application_routing
    ```
    NOTE:  This feature makes it easy to access web applications deployed in the AKS cluster by creating publicly accessible DNS names for application end-points.  Selecting this option, creates a DNS Zone in the Azure subscription.  This feature should NOT be used in a production AKS deployment!  For deploying ingress controllers in a production AKS cluster, refer to the [AKS documentation](https://docs.microsoft.com/en-us/azure/aks/ingress-tls).

2.  Retrieve the DNS Zone name for the AKS cluster.
    ```
    $ az aks show -g myResourceGroup -n akscluster --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName -o table
    ```
    Save the DNS Zone name in a text file.  This name will be needed to deploy applications to AKS cluster in subsequent steps.

3.  Update the `./po-service/values.yaml` file in Helm Chart directory.

    Specify correct value for container image repository (ACR Name).  This is the ACR which you deployed in the parent project.

    Specify the correct value for the **Ingress and TLS host names**.  This is the DNS Zone name which you retrieved in the previous step.

    See below.  Substitute correct values between the place holders denoted by `<<VALUE>>`.  (Do not include the angle brackets).
    ```
    image:
      repository: <<mtcslabtest.azurecr.io>>/po-service
    ...
    ingress:
      enabled: true
      ...
      hosts:
        - po-service.<<xyz.westus.aksapp.io>>
      tls:
        - secretName: po-ssh-secret
          hosts:
            - po-service.<<xyz.westus.aksapp.io>>
    ```
    Make a note of the **Ingress Host Name** (value of **hosts** attribute) as we will need this value to generate the SSL Key pair.

4.  Create an SSL key pair and store it in a **Secret**

    Generate a self-signed SSL key pair using `openssl` utility as shown in the command snippet below.  Specify value of **Ingress Host Name** (the value which you noted in the previous step) in parameter **-subj**.
    ```
    # Before running this command, substitute the correct value for the 'Ingress Host Name' !!
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj '/CN=<<Ingress Host Name>>'
    # Print certificate and verify subject value; should point to the Ingress host name
    $ openssl x509 -in tls.crt -text -noout
    #
    ```
    Store the SSL keys in a Secret.  See command snippet below.
    ```
    # Create the secret 'po-ssh-secret' of Type = tls !!
    $ kubectl create secret tls po-ssh-secret --key tls.key --cert tls.crt -n dev-azure-mysql
    # Get the secret data
    $ kubectl get secret po-ssh-secret -n dev-azure-mysql -o yaml
    #
    $ kubectl get secrets -n dev-azure-mysql
    NAME                  TYPE                                  DATA      AGE
    default-token-x7l9r   kubernetes.io/service-account-token   3         2h
    mysql-secret          Opaque                                8         2h
    po-ssh-secret         kubernetes.io/tls                     2         13s
    #
    ```

5.  Deploy the **po-service** microservice using Helm
