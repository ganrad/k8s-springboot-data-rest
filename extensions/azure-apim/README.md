## Use Azure API Management to manage the lifecycle of Web API's

The overall goal of this sub-project (extension) is summarized below.

- Demonstrate the use of **Azure API Management** (APIM) to secure and manage the lifecyle of Web API's.

  An API managemnet platform provides core capabilities to engage application developers, secure API's, retrieve business insights and analyze API usage, reduce latency and many other value add features.  This project will demonstrate use of many of these features.
- Demonstrate how to deploy a AKS cluster in a private virtual network and route Web traffic to services deployed on the cluster thru an **Ingress Controller** and internal **Load Balancer**.
- Demonstrate the use of **Helm** (CLI) for deploying containerized applications on Kubernetes (AKS).

  Helm is a package manager for Kubernetes and is a part of [CNCF](https://www.cncf.io/). Helm is used for managing Kubernetes packages called *Charts*.  In layman's terms, a chart is a bundle of Kubernetes manifest files necessary to create an instance of a Kubernetes application.
- Demonstrate how to secure API's using keys and encrypt payloads using TLS/SSL

**Prerequisites:**
1.  Before beginning to work on this project, readers are required to complete all hands-on labs (Sections) in the [parent project](https://github.com/ganrad/k8s-springboot-data-rest).  In case you have come to this project directly, go back and finish the lab exercises in the parent project.
2.  Readers are required to have prior experience working with Linux systems
3.  Readers are advised to refer to the CLI documentation for **kubectl** & **helm** as needed.  Links to documentation are provided below.

**Description:**

In a nutshell, you will work on the following tasks.
1. Configure a private virtual network and two subnets.  Deploy an AKS cluster and configure it to use the private virtual network.
2. Deploy an internal (private) load balancer (ALB) and ingress controller (NGINX) to provide a single point of entry for all web traffic destined to microservices deployed on the AKS cluster.
3. Provision an APIM service and configure it to use the private virtual network. 
4. Deploy the po-service microservice on AKS using Helm
5. Configure proxy API's on APIM and expose backend microservices deployed on the AKS cluster. Examine various features and capabilities supported by APIM.

**Functional Architecture:**

![alt tag](./images/azure-apim.jpg)

For easy and quick reference, readers can refer to the following on-line resources as needed.
- [Kubernetes Documentation](https://kubernetes.io/docs/home/?path=browse)
- [kubectl CLI](https://kubernetes.io/docs/reference/kubectl/overview/)
- [Helm Documentation](https://docs.helm.sh/)
- [Azure API Management](https://docs.microsoft.com/en-us/azure/api-management/api-management-key-concepts)
- [Azure Load Balancer](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-overview)

**Important Notes:**

### A] Provision a new AKS cluster and configure advanced networking (Azure CNI)
**Approx. time to complete this section: 45 Minutes**

By default, AKS clusters use *Basic* networking which creates and configures a virtual network and subnet for the cluster nodes.  For this project, we will deploy an AKS cluster with *Advanced* networking option to allow us to configure APIM Service on the same VNET as the cluster.   The advanced networking option configures Azure CNI (Container networking interface) for the AKS cluster.  The end result is that Azure networking assigns IP addresses for all cluster nodes and pods.

Login to [Azure Portal](https://portal.azure.com/).

1. Create a */24* virtual network *aks-cluster-vnet* and a */25* subnet *aks-cluster-subnet*.

   The subnet *aks-cluster-subnet* will be used to allocate IP addressses for the AKS cluster nodes and pods.  See screenshot below.

   ![alt tag](./images/A-01.PNG)

   Click **Create**.  Check to make sure the virtual network was provisioned ok.

   ![alt tag](./images/A-02.PNG)

   Next, click on the VNET *aks-cluster-vnet* and create another */27* subnet *apim-subnet*.  This subnet will be used to allocate IP addresses for the APIM services.  See screenshots below.

   ![alt tag](./images/A-03.PNG)

   ![alt tag](./images/A-04.PNG)

   Click **OK**.  There should be two subnets in the *aks-cluster-vnet* VNET as shown in the figure below.

   ![alt tag](./images/A-05.PNG)

2. Get the resource ID for subnet *aks-cluster-subnet*

   The AKS cluster nodes will be deployed within the subnet *aks-cluster-subnet*, created in the previous step.

   Login to the Linux VM (Bastion Host) for issuing all Azure CLI commands.

   ```
   # Substitute correct values for 'Resource Group' and 'VNET' name
   $ az network vnet subnet list --resource-group myResourceGroup --vnet-name aks-cluster-vnet --query [].id --output tsv
   #
   ```

   Save the resource ID for subnet **aks-cluster-subnet**.  We will need it in the next step.

3. Create the AKS Cluster with *Advanced networking* (Azure CNI) option

   Refer to the command snippet below to provision an AKS cluster *aks-cluster-apim*.  Specify **azure** for the *--network-plugin* option to create an AKS cluster with advanced networking option (Azure CNI).  Also, make sure to specify the subnet resource ID value for parameter *--vnet-subnet-id*, the value which you saved in the previous step.

   ```
   # Retrieve k8s versions
   $ az aks get-versions
   #
   # Substitute correct values for 'Resource Group', 'Cluster Name' and '--vnet-subnet-id'.  Deploy ks8 v1.11.3 or specify another version.
   $ az aks create --resource-group myResourceGroup --name aks-cluster-apim --network-plugin azure --vnet-subnet-id <subnet-id> --docker-bridge-address 172.17.0.1/16 --dns-service-ip 10.2.0.10 --service-cidr 10.2.0.0/24 --node-count 1 --kubernetes-version "1.11.4" --dns-name-prefix akslab2 --location westus --disable-rbac
   #
   ```

   The AKS cluster provisioning process will take approx. 5-10 minutes to complete.  Once the AKS cluster is up, there should be 1 node deployed within the cluster.  Use the command snippet below to connect and view the status of the cluster.

   ```
   # Verify state of aks-cluster-apim AKS cluster
   $ az aks show -g myResourceGroup -n aks-apim-cluster --output table
     Name              Location    ResourceGroup     KubernetesVersion    ProvisioningState    Fqdn
     ----------------  ----------  ----------------  -------------------  -------------------  -------------------------------------
     aks-cluster-apim  westus      mtcs-dev-grts-rg  1.11.3               Succeeded            akslab2-a70564cc.hcp.westus.azmk8s.io
   #
   # Connect to the AKS cluster.  Substitute correct values for 'Resource Group' and 'AKS Cluster Name'
   $ az aks get-credentials --resource-group myResourceGroup --name aks-cluster-apim
   #
   # Retrieve cluster info.
   $ kubectl cluster-info
   #
   # Verify no. of nodes in cluster
   $ kubectl get nodes
     NAME                       STATUS    ROLES     AGE       VERSION
     aks-nodepool1-15652387-0   Ready     agent     10m       v1.11.3
   #
   ```

### B] Deploy an internal (Private) *Ingress Controller* and *Load Balancer*
**Approx. time to complete this section: 30 Minutes**

An internal ingress controller makes Web API's deployed on a Kubernetes cluster accessible only to applications running in the same virtual network as the cluster.  As part of the ingress controller deployment, an internal Azure Load Balancer (ALB) instance is also provisioned.  An available private IP address from the virtual network subnet is assigned to the ALB instance's frontend.  The *Backend pool* of the ALB instance is configured to point to the AKS cluster node.  Load balancing rules are configured to direct traffic (HTTP/HTTPS) from the frontend IP to the backend pool.

The internal ingress controller will expose ports 80 and 443 and provide a single point of entry for all web traffic destined to all services deployed within the AKS cluster.

1. Initialize *Helm* by installing *Tiller* on the AKS cluster

   Helm will be used to deploy the ingress controller.  Refer to the command snippet below to install *Tiller* on the AKS cluster and initialize the client.

   ```
   # Initialize Helm client and install 'Tiller' on AKS cluster
   $ helm init
   #
   # Verify 'Tiller' is running in the 'kube-system' namespace.  Output should list a pod ('tiller-deploy...') in 'RUNNING' state.
   $ kubectl get pods -n kube-system
     NAME                                    READY     STATUS    RESTARTS   AGE
     azure-cni-networkmonitor-wqv7r          1/1       Running   0          9m
     heapster-7b74498c4b-ht69z               2/2       Running   0          5m
     kube-dns-v20-54f74f4458-2zjjf           3/3       Running   0          14m
     kube-dns-v20-54f74f4458-k9kfs           3/3       Running   0          14m
     kube-proxy-wlg2d                        1/1       Running   0          9m
     kube-svc-redirect-86xpd                 2/2       Running   0          9m
     kubernetes-dashboard-5845b66748-gfmt2   1/1       Running   1          14m
     metrics-server-76f76c6bfd-qrs7j         1/1       Running   1          14m
     tiller-deploy-597c48f967-bmf5w          1/1       Running   0          23s
     tunnelfront-b595dc468-tjvwz             1/1       Running   0          14m
   #
   ```

2. Create an ingress controller and ALB

   Review the helm parameter values file `./k8s-resources/internal-ingress.yaml`.  This file will be passed in to the helm *install* command.  Refer to the command snippet below to deploy the ingress controller.
  
   ```
   # Make sure you are in the 'azure-apim' extension sub directory
   $ cd ./extensions/azure-apim
   #
   # Deploy the k8s service for internal lb.
   $ helm install stable/nginx-ingress --namespace kube-system -f ./k8s-resources/internal-ingress.yaml
   #
   # List the helm releases
   $ helm list
     $ helm ls
     NAME            REVISION        UPDATED                         STATUS          CHART                   NAMESPACE
     iced-zorse      1               Tue Nov  6 16:30:16 2018        DEPLOYED        nginx-ingress-0.30.0    kube-system
   #
   # List the services deployed in 'kube-system' namespace.  The ALB's IP address should be listed under column
   # 'EXTERNAL-IP' and the ingress controller's service IP should be under column 'CLUSTER_IP'.
   $ kubectl get svc -n kube-system
     NAME                                       TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
     heapster                                   ClusterIP      10.2.0.142   <none>        80/TCP                       3h
     iced-zorse-nginx-ingress-controller        LoadBalancer   10.2.0.17    10.0.0.35     80:32598/TCP,443:30758/TCP   3m
     iced-zorse-nginx-ingress-default-backend   ClusterIP      10.2.0.44    <none>        80/TCP                       3m
     kube-dns                                   ClusterIP      10.2.0.10    <none>        53/UDP,53/TCP                3h
     kubernetes-dashboard                       ClusterIP      10.2.0.246   <none>        80/TCP                       3h
     metrics-server                             ClusterIP      10.2.0.48    <none>        443/TCP                      3h
     tiller-deploy                              ClusterIP      10.2.0.136   <none>        44134/TCP                    2h
   #
   ```

   The ingress controller's *Service* IP address is listed under column **CLUSTER-IP**.  A private IP address from the *aks-cluster-subnet* is assigned to the *Azure Load Balancer* as listed under the **EXTERNAL-IP** column in the command output above.  Note down the ALB's external (Private IP) IP address.  We will use this IP address to test the *po-service* later in Section [E].


   Use the *Load Balancers* blade in the Azure Portal to view all the properties of the internal ALB.  See screenshots below.

   ![alt tag](./images/B-01.PNG)

   ![alt tag](./images/B-02.PNG)

### C] Provision an Azure API Management (APIM) Service
**Approx. time to complete this section: 45 Minutes**

In this section, we will provision and configure an Azure API Management Service.

1. Create the APIM Service

   Click on **All Services** in the left navigational panel and search for text **API**, then select the star besides API Management Services as shown in the screenshot below.  This will add the API Management Services link to the navigational panel.

   ![alt tag](./images/C-01.PNG)

   Click on **API Management Services** in the left navigational panel and then click on **Create API management service** link in the detail pane (blade on the right).  See the screenshot below.

   ![alt tag](./images/C-02.PNG)

   In the API Management service definition web page, specify values as shown in the screenshot below.  The value for field **Name** has to be unique across all APIM services in Azure.  For field **Organization name**, provide a fictious value and select *Developer (No SLA)* for **Pricing tier**.  The Organization name will be used in the title of the **Developer Portal** (Website) exposed by Azure APIM.  For **Location** field, specify the same *Region* in which you deployed the AKS cluster in Section [B].

   ![alt tag](./images/C-03.PNG)

   Click on **Create**.  The APIM service will take a few minutes to get provisioned.

2. Connect APIM Service to the AKS Virtual Network subnet *apim-subnet*

   The APIM service has to be deployed in the AKS virtual network (VNET), so it can access the API's exposed by the *po-service* microservice.

   Click on the APIM service and then click on **Virtual network** under **Settings** in the navigational menu on the left.  See screenshot below.

   ![alt tag](./images/C-04.PNG)

   Click on the **External** button.  Verify and make sure the **Location** field displays the *Region* in which the AKS cluster is deployed.  Click on the field below **VIRTUAL NETWORK** and select the VNET **aks-cluster-vnet** and subnet **apim-subnet** created in Section [A].  Click **Apply**.  See screenshot below.

   ![alt tag](./images/C-05.PNG)

   Then click **Save** as shown in the screenshot below.

   ![alt tag](./images/C-06.PNG)
   
   It will take approx. 10-15 minutes for the APIM service to get updated.  

### D] Deploy the *po-service* microservice on AKS
**Approx. time to complete this section: 20 Minutes**

In this section, we will use *Helm* to deploy the *po-service* microservice on AKS.  Review the Helm charts under directory `./po-service`.

1. Configure AKS to pull application container images from ACR (configured in parent project).

   In the Linux VM terminal window, update the shell script `./shell-scripts/acr-auth.sh` with correct values for the following variables.

   Variable | Description
   ----------------- | -------------------
   AKS_RESOURCE_GROUP | Name of the AKS resource group
   AKS_CLUSTER_NAME | Name of the AKS cluster instance
   ACR_RESOURCE_GROUP | Name of the ACR resource group
   ACR_NAME | Name of ACR instance

   Then execute this shell script.  Refer to the command snippet below.
   ```
   # chmod 700 ./shell-scripts/acr-auth.sh
   #
   # Update the shell script and then run it
   $ ./shell-scripts/acr-auth.sh
   # 
   ```

2. Use *Helm* to deploy the *po-service* microservice to AKS cluster (`aks-cluster-apim`)

   Substitute the correct value of your image repository (ACR) in the *helm install* command as shown in the command snippet below.
   ```
   # Make sure you are in the 'azure-apim' extension sub directory
   $ pwd
   # 
   # Remember to substitute the correct value of the ACR in the install command below
   $ helm install ./po-service --namespace development --set image.repository=xxxx.azurecr.io/po-service
   # 
   # Check status of Pods.  Should be in 'RUNNING' state
   $ kubectl get pods -n development
     NAME                                     READY     STATUS    RESTARTS   AGE
     jolly-moth-mysql-85bccdf47b-bjhfw        1/1       Running   0          1m
     jolly-moth-po-service-57465485dd-hlgpr   1/1       Running   3          1m
   #
   ```

3. Test the *po-service* microservice by accessing the internal load balancer (ALB)

   Create a test pod (Debian Linux) and attach a terminal session to it.  See below.
   ```
   # Create a test pod running Debian Linux and attach a terminal session.  When the command completes, you should
   # be logged in to the debian container.
   $ kubectl run -it --rm po-service-test --image=debian
   #
   # Update binaries and install 'curl'
   $ apt-get update && apt-get install -y curl
   #
   ```

   Use `curl` command to access the ALB IP address.  You should have saved this IP address in Section [B].
   ```
   # Curl to the ALB IP address and access the po-service end-point at '/bcc'.
   # The HTTP call should return JSON data with HTTP response status code 200
   $ curl -L -v http://<ALB IP address>/bcc/orders
   #
   ```

### E] Expose the Springboot Java Microservice *po-service* APIs using Azure API Management Service
**Approx. time to complete this section: 2 Hours**

In this section, we will create an API for *Purchase Order Management* and examine built-in features provided by Azure APIM.

1. Create and Publish an API for a *Product*

   A *Product* is used to group a set of API's offered by a department, a group (organizational unit) or a line of business within a given organization.  For this project, we will create a *Product* to expose an API for *Purchase Order Management*.
   
   Click on the APIM service and then click on **Products** in the navigational menu on the left to display the **Products** page.  Then click on **Add**.  See Screenshot below.

   ![alt tag](./images/D-01.PNG)

   Specify name **PO-Service** for the API in the **Display name** field.  For **State**, leave **Not Published** selected.  API Products have to be published before they can be invoked.  Un-published products can only be invoked and viewed by members of the **Administrators** group.  Check **Require Subscription** as we want clients to subscribe to an API Product before they can start consuming it.  Leave **Requires approval** unchecked as we don't want to approve subscription requests from API consumers.  Do not click on the **Select API** link as we will create an API for the **po-service** in the next step.  Click **Create**.

   ![alt tag](./images/D-02.PNG)

   Click on **APIs** in the navigational panel on the left.  Then click on **Add API** and select **Blank API** tab on the right.  See screenshot below.

   ![alt tag](./images/D-03.PNG)

   Use the table below to fill in the values on the **Create a blank API** form.

   Field | Value   | Description
   ----- | ------- | ------------
   Display name | po-service-api |
   Name | po-service-api |
   Description | Secures and tracks usage of the po-service API's
   Web service URL | http://10.0.0.35/bcc | Use the private IP address of the Azure Load Balancer which you saved in Section [B]
   API URL suffix | bcc |
   Products | PO-Service | Select the **PO-Service** product which you created in the previous step

   After filling the values, click on **Create** as shown in the screenshot below.

   ![alt tag](./images/D-04.PNG)

2. Add API Operations

   In the **Design** tab, click on **+ Add Operation** and fill out the field values as shown in the screenshot below.  Then click **Save**.

   ![alt tag](./images/D-05.PNG)

   Test the **GET-POs** operation of the **po-service-api**.  Click on the **Test** tab, then click on the **GET GET-POs** operation and hit **Send**.  See screenshow below.

   ![alt tag](./images/D-06.PNG)

   Scroll down to view the **Request URL**, **HTTP request** and **HTTP response**.  See screenshot below.

   ![alt tag](./images/D-07.PNG)

3. Mock a response for an API Operation

   In this step, we will examine the Web API *response mocking* feature in APIM.  With this feature, consumers of API's and producer's (authors/developers) of the API's can work independently with little to no dependency on one another.  As soon as the development team publishes the API specification (interface) in APIM, the consumer's of the API's can start testing their applications with test data.  Azure APIM also provides a *Developer Portal* to allow application development teams to quickly read API documentation, create an account and subsribe to get API access keys, analyze API usage etc. 

   Add another API Operation for retrieving the details of a *Purchase Order* by it's ID.

   In the **Design** tab, click on **+ Add Operation** and fill out the field values as shown in the screenshot below.  Click on the *Responses* tab and then click **+ Add response**.  Select **200 OK** from the response drop down box.  Next, Click on **+ Add representation** and fill out the data as shown in the screenshot below.  Use the sample JSON response data for the mock response.
   
   ```
   {
    "item": "Test Breakfast Blend",
    "price": 80.5,
    "quantity": 2,
    "description": "Testing the Breakfast blend coffee",
    "cname": "Ashley's Coffee Corner",
    "dcode": "7.5",
    "origin": "Web",
    "_links": {
        "self": {
            "href": "http://xyz.com/orders/1"
        },
        "purchaseOrder": {
            "href": "http://xyz.com/orders/1"
        }
    }
   }
   ```

   Click on **Save**.  See screenshot below.

   ![alt tag](./images/D-08.PNG)

   Next, select the **GET-PO-By-ID** operation and then click on the **Design** tab.  In the **Inbound processing** window, click on **Add policy**.  Select **Mock responses** tile from the gallery.  In the **API Management response** textbox, select **200 OK, application/json**.  This is the mock response which we just defined.  Click on Save.  See screenshots below.

   ![alt tag](./images/D-09.PNG)

   ![alt tag](./images/D-10.PNG)

   ![alt tag](./images/D-11.PNG)

   Click **Save**.

   Switch to the **Test** tab, select the **GET-PO-By-ID** operation and hit **Send**.  You should see the mock HTTP response as shown in the screenshot below.

   ![alt tag](./images/D-12.PNG)

   ![alt tag](./images/D-13.PNG)

   You will also notice there is a message **Mocking is enabled** just below the **Test** tab.

   To delete the mock response, go back to the **Design** tab, select the **GET-PO-By-ID** operation, click on the ellipses (...) beside the **mock-response** field in the **Inbound processing** window.  Then select **Delete**.  See screenshot below.
 
   ![alt tag](./images/D-14.PNG)

   Click **Save**.

   Click on the **Test** tab and click **Send**.  You should now hit the backend *po-service* microservice and get the actual JSON response.

   ![alt tag](./images/D-15.PNG)

4. Examine built-in transformation features in APIM

   Hide backend API URL's in the HTTP response (payload) and replace them with APIM gateway URL.  We will replace the original backend (microservice) URL contained in the body of the API's HTTP response and redirect users to the APIM Gateway.

   In the **Design** tab, select the **GET-PO-By-ID** operation and click on **</>** icon in the **Outbound processing** window as shown in the screenshot below.

   ![alt tag](./images/D-16.PNG)

   In the *policy* editor, position the cursor below the **outbound** element and click on **Find and replace string in body** under **Transformation policies** on the right panel.  See screenshot below.

   ![alt tag](./images/D-17.PNG)

   Update the **from** and **to** URL's and then click on **Save** as shown in the screenshot below.  The **from** URL should point to the internal (private) ALB IP address and the **to** URL should point to your APIM Gateway.  Copy the APIM Gateway URL from the APIM service **Overview** tab (value of **Gateway URL**).

   ![alt tag](./images/D-18.PNG)

   Next, protect an API operation by adding rate limit policy (throttling).  We will protect the backend (*po-service*) API by configuring **rate limits**.  For demo purposes and to highlight this feature, we will limit the number of calls to the **GET-PO-By-ID** operation to 3 calls in 20 seconds.  If this operation is called more than 3 times in 20 seconds, the APIM Gateway will return a HTTP Status Code 429 (**Too many requests**).

   In the **Design** tab, select the **GET-PO-By-ID** operation and click on **</>** icon in the **Inbound processing** window as shown in the screenshot below.

   ![alt tag](./images/D-19.PNG)

   In the *policy* editor, position the cursor below the **inbound** element and click on **Limit call rate per key** under **Access restriction policies** on the right panel.  See screenshot below.

   ![alt tag](./images/D-20.PNG)

   Update the values for attributes **calls**, **renewal-period** and **counter-key** as shown in the screenshot below.  Then Click **Save**.

   ![alt tag](./images/D-21.PNG)

   The **Design** window should now contain the inbound and outbound policies as shown in the screenshot below.

   ![alt tag](./images/D-22.PNG)

   Finally, test the transformations.

   Test the replaced URL.  Select the **po-service-api**, click on the **Test** tab and select the **GET-PO-By-ID** operation.  Then, click on **Send**.  

   ![alt tag](./images/D-23.PNG)

   The URL in the API response (payload) should have been replaced with the APIM Gateway URL.

   Test the rate limit (throttling).  Select the **po-service-api**, click on the **Test** tab and select the **GET-PO-By-ID** operation.  Then, click on **Send** 4 times in a row.  You should get a **429 Too many requests** response.  See screenshot below.

   ![alt tag](./images/D-24.PNG)

   Wait for 20 seconds and hit **Send** again.  This time you should get a **200 OK** response.

5. Test the built-in API response *Caching* feature

   Add an API operation **GET-PO-By-ITEM** to retrieve all PO's for a *Coffee Bean* type.  In the **Design** tab, click on **+ Add Operation** and fill out the field values as shown in the screenshot below. 

   ![alt tag](./images/D-25.PNG)

   Click **Save**.  Test the API operation as shown in the screenshot below.

   ![alt tag](./images/D-26.PNG)

   Add an API operation **ADD-PO** to add a PO.  In the **Design** tab, click on **+ Add Operation** and fill out the field values as shown in the screenshot below. 

   ![alt tag](./images/D-27.PNG)

   Click **Save**.

   Next, load 10 to 15 PO's for coffee bean type *Colombia* using the shell script `./shell-scripts/post-orders.sh`.  Before running this script, update the values for HTTP headers **Ocp-Apim-Trace** and **Ocp-Apim-Subscription-Key**.  Also, update the API **End-point URI** to point to your APIM instance.  Run the shell script.
   ```
   # Make sure you are in the 'azure-apim' extension directory
   $ ./shell-scripts/post-orders.sh
   #
   ```
   After the shell script has posted a few PO's, click cancel (Control-C).  Click on the **Overview** tab of the APIM service to view the **Requests**, **Capacity** and **Latency** graphs.

   ![alt tag](./images/D-28.PNG)

   Use the **Developer Portal** to test the **GET-PO-By-ITEM** operation. Click on the **Developer portal** link below the APIM service name.

   ![alt tag](./images/D-29.PNG)

   The developer portal will open in a new browser tab.  Click on **APIS** on the top navigational panel.

   ![alt tag](./images/D-30.PNG)

   Click on *po-service-api* and then click on **GET-PO-By-ITEM** operation.

   ![alt tag](./images/D-31.PNG)

   ![alt tag](./images/D-32.PNG)

   Click on **Try it**.  Enter *Colombia* for **item** and click on **Send** a few times.

   ![alt tag](./images/D-33.PNG)

   Take a note of the **Response latency**.

   Switch back to the Azure Portal.  In the **Design** tab, click on operation **GET-PO-By-ITEM**.  Then click on **+ Add policy** link in the **Inbound processing** window.

   ![alt tag](./images/D-34.PNG)

   Next, click on the **Cache responses** tile as shown in the screenshot below.

   ![alt tag](./images/D-35.PNG)

   Specify **30 seconds** as the cache duration and click on the **Full** link to expose the cache settings.  Update the cache settings as shown in the screenshot below.  The APIM service will cache the response of an API request for upto 30 seconds before evicting it from the cache.  The first API request (within a 30 sec window) will retrieve data from the backend *po-service* API and all subsequent requests will be served from the cache resulting in much higher throughput and low latency.  

   ![alt tag](./images/D-36.PNG)

   Click **Save**.

   Switch back to the **Developer portal** and invoke the **GET-PO-By-ITEM** operation a few times and observe the **Response latency**.  Within a given 30 second window, the first API invokation will take a few milliseconds to hit the backend **po-service** microservice and return the response.  However, subsequent HTTP calls will execute much faster as they serve the data from the internal cache resulting in higher throughput, reduced response latency and improved performance.

This brings us to the end of this project.  We have only scratched the surface in terms of exploring the built-in features offered by Azure APIM.  Adding the **UD** operations to the **po-service-api** API is left as an exercise to readers.

Congrats!  You have now successfully completed all sections in this sub-project.  Feel free to go back to the [parent project](https://github.com/ganrad/k8s-springboot-data-rest) to work on other sub-projects.
