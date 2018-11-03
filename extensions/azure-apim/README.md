## Use Azure API Manager to manage the lifecycle of Web API's

**Prerequisites:**
1.  Before working on the hands-on labs in this project, readers are required to complete all hands-on labs (Sections) in the [parent project](https://github.com/ganrad/k8s-springboot-data-rest).  In case you have come to this project directly, go back and finish the lab exercises in the parent project.

**Description:**

In a nutshell, you will work on the following tasks.
1. Define a *Product and API's* in **Azure API Management** PaaS to expose the *po-service* API 

**Workflow:**

For easy and quick reference, readers can refer to the following on-line resources as needed.
- [Azure API Management](https://docs.microsoft.com/en-us/azure/api-management/api-management-key-concepts)

**Important Notes:**

### Expose the Springboot Java Microservice APIs (po-service) using Azure API Management Service
**Approx. time to complete this section: 1 Hour**

In this section, we will configure and expose the **po-service** microservice API's to external consumers using Azure API Management Service.

1. Login to [Azure Portal](https://portal.azure.com/) and create an *API Management Service*.

   Click on **All Services** in the left navigational panel and search for text **API**, then select the star besides APi Management Services as shown in the screenshot below.  This will add the API Management Services link to the navigational panel.

   ![alt tag](./images/A-01.PNG)

   Click on **API Management Services** in the left navigational panel and then click on **Create API management service** link in the detail pane (blade on the right).  See the screenshot below.

   ![alt tag](./images/A-02.PNG)

   In the API Management service definition web page, specify values as shown in the screenshot below.  The value for field **Name** has to be unique across all APIM services in Azure.  For field **Organization name**, provide a fictious value and select *Developer (No SLA)* for **Pricing tier**.  The Organization name will be used in the title of the **Developer Portal** (Website) exposed by Azure APIM.

   ![alt tag](./images/A-03.PNG)

   Click on **Create**.  The APIM service will take a few minutes to get provisioned.

2. Create and Publish an API Product
   A *Product* is used to group a set of API's offered by a department, a group (organizational unit) or a line of business within a given organization.  A Product can also be used to group API's for a specific product (or product group) manufactured and sold by a company.
   
   Click on the APIM service and then click on **Products** in the navigational menu on the left to display the **Products** page.  Then click on **Add**.  See Screenshot below.

   ![alt tag](./images/A-04.PNG)

   Specify a name for the API in the **Display name** field.  For **State**, leave **Not Published** selected.  API Products have to be published before they can be invoked.  Un-published products can only be invoked and viewed by members of the **Administrators** group.  Check **Require Subscription** as we want clients to subscribe to an API Product before they can start consuming it.  Leave **Requires approval** unchecked as we don't want to approve subscription requests from API consumers.  Do not click on the **Select API** link as we will create an API for the **po-service** in the next step.  Click **Create**.

   ![alt tag](./images/A-05.PNG)


   You have now successfully completed this lab.  Congrats!

   To recap, during this lab you completed the following steps -

