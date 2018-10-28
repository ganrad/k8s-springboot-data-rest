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
- [Azure Service Catalog CLI Documentation] (https://github.com/Azure/service-catalog-cli)

**Important Notes:**
- Keep in mind that this is an **Advanced** lab targeted towards experienced Kubernetes users who are familiar with CLI (`kubectl`) and the API model.

### A] Install *Service Catalog* and *Open Service Broker for Azure (OSBA)* on AKS
**Approx. time to complete this section: 1 Hour**

In this section, we will implement a CI and CD pipeline in *Azure DevOps* in order to build and deploy *Jenkins* on the AKS cluster deployed in the parent project labs.

### B] Deploy the *Azure Database for MySQL* instance
**Approx. time to complete this section: 1 Hour**


### C] Redeploy the *po-service* microservice using Helm package manager
**Approx. time to complete this section: 1 Hour**
