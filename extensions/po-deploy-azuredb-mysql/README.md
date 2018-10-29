## Use Azure Database for MySQL (PaaS) as the persistent data store for the po-service microservice application.

In this project, we will first deploy a managed MySQL database instance on Azure using **Open Service Broker for Azure** (OSBA).  Following that, we will configure the MySQL instance as the backend data store for the **po-service** microservice.

**Prerequisites:**
1.  Before working on the hands-on labs in this project, readers are required to complete all hands-on labs (Sections) in the [parent project](https://github.com/ganrad/k8s-springboot-data-rest).  In case you have come to this project directly, go back and finish the lab exercises in the parent project.
2.  Readers are required to be familiar with basic Linux commands.  Experience working in Linux environments will definitely be helpful.
3.  **Helm** CLI will be used to deploy the **Service Catalog**, **Open Service Broker for Azure** and the **po-service** microservice on AKS. Additionally, the **Service Catalog CLI** will be used to deploy a **Managed MySQL Database Server** on Azure.  Readers are advised to refer to the CLI documentation as needed.  Links to documentation are provided below.

**Description:**

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
- Keep in mind that this is an **Advanced** lab for experienced Kubernetes users.  Please complete all sections in the parent project before working on this lab/project.

### A] Install *Service Catalog* and *Open Service Broker for Azure* (OSBA) on AKS
**Approx. time to complete this section: 45 mins to an hour**

Open a terminal window and use SSH to login to the Linux VM (Bastion Host) which you provisioned on Azure in the parent project.

1.  Add **Service Catalog** chart to the Helm repository.
    ```
    $ helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
    ```
    Install Service Catalog with the Helm chart.  The command below assumes the AKS cluster is not RBAC-enabled.  If your cluster is RBAC enabled, do not specify the *rbacEnable* flag.
    ```
    # If your cluster is not RBAC-enabled, run this command.
    $ helm install svc-cat/catalog --name catalog --namespace catalog --set rbacEnable=false --set controllerManager.healthcheck.enabled=false
    # If your cluster is RBAC-enabled, use the command below.
    # helm install svc-cat/catalog --name catalog --namespace catalog --set controllerManager.healthcheck.enabled=false
    ```
    The Service Catalog containers will be deployed in the **catalog** namespace on AKS.  Use the command below to verify the catalog API service is installed.
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
    The shell script should output a JSON and also save the output in a txt file *SP_SUB.txt* in the current directory.  Next, set the following environment variables by substituting the correct values from the JSON output of the SP creation command.
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
    # Retrieve the user's subscription ID
    $ az account show --query id --output tsv
    #
    # Set the Azure subscription ID
    $ AZURE_SUBSCRIPTION_ID=<Your Azure Subscription ID output by the command above!>
    #
    # Install the Open Service Broker for Azure components using Helm.
    $ helm install azure/open-service-broker-azure --name osba --namespace osba \
      --set azure.subscriptionId=$AZURE_SUBSCRIPTION_ID \
      --set azure.tenantId=$AZURE_TENANT_ID \
      --set azure.clientId=$AZURE_CLIENT_ID \
      --set azure.clientSecret=$AZURE_CLIENT_SECRET
    #
    ```

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
**Approx. time to complete this section: 30 mins**


### C] Redeploy the *po-service* microservice using Helm package manager
**Approx. time to complete this section: 1 Hour**
