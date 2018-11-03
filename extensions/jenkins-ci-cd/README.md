## Use Azure DevOps to deploy Jenkins CI/CD on AKS and implement a Jenkins *Continuous Delivery* pipeline

**Prerequisites:**
1.  Before working on the hands-on labs in this project, readers are required to complete all hands-on labs (Sections) in the [parent project](https://github.com/ganrad/k8s-springboot-data-rest).  In case you have come to this project directly, go back and finish the lab exercises in the parent project.
2.  Readers are required to be familiar with basic Linux commands.  Experience working in Linux environments will definitely be helpful.
3.  In this hands-on lab, readers will be working with two of the commonly used and popular **DevOps** tools - *Azure DevOps (VSTS)* and *Jenkins*. Hence readers are assumed to have some level of exposure to these tools.

**Description:**

In a nutshell, you will work on the following tasks.
1. Implement a *Azure DevOps Build and Release Pipeline* to deploy Jenkins CI/CD on AKS (Section [A])

   **Result:** A Jenkins CI/CD cluster (1-executor) deployed on Azure Kubernetes Service (AKS)
2. Implement a *Continuous Delivery Pipeline* in Jenkins to build and re-deploy *po-service* Springboot Java microservice on AKS (Section [B])

   **Result:** A **Continuous Delivery** pipeline deployed in Jenkins which will be used to re-deploy the *po-service* microservice on AKS (previously deployed to AKS in the parent project).

**Workflow:**

![alt tag](./images/Jenkins-cicd-workflow.jpg)

For easy and quick reference, readers can refer to the following on-line resources as needed.
- [Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/?view=vsts)
- [Jenkins](https://jenkins.io/doc/)
- [Helm](https://docs.helm.sh/)

**Important Notes:**
- Keep in mind that this is an **Advanced** lab targeted towards experienced Kubernetes users who are familiar with CLI (`kubectl`) and the API model.
- For deploying the Jenkins container on AKS, we will be using **Helm** in the Azure DevOps release (CD) pipeline.  Helm is a package manager for Kubernetes and has become the de-facto tool for managing the lifecycle of containerized applications on Kubernetes.  With Helm, Kubernetes resources for a given application are packaged within a *Chart*.  When a Chart is deployed to Kubernetes, Helm creates a new release.  A given Chart can be updated and deployed multiple times.  Each deployment creates a new *Revision* for the release.  A specific deployment can also be rolled back to a previous revision and/or deleted.  A Chart can also be deployed multiple times (multiple releases).  We won't be going into the details of Helm and it's internals as it is beyond the scope of this project.  Refer to the Helm documentation (links provided above) for details.

### A] Implement Azure DevOps pipelines to deploy Jenkins CI/CD on AKS
**Approx. time to complete this section: 1 Hour**

In this section, we will implement a CI and CD pipeline in *Azure DevOps* in order to build and deploy *Jenkins* on the AKS cluster deployed in the parent project labs.

1. In this step we will implement a CI pipeline in Azure DevOps to build and push a custom *Jenkins* container image into ACR.

   Log into your Azure DevOps account and create a new project.  Give a meaningful name to the project. Click **Create**.  See screenshot below.

   ![alt tag](./images/A-01.PNG)

   Click on **Pipelines** on the top menu and then select **Builds**.  If you have turned on **Preview Features** in your account, the top menu will appear in the left navigational panel.  Then click on **New pipeline**.  See screenshot below.

   ![alt tag](./images/A-02.PNG)

   In the **Select a source** page, select **GitHub**, specify a **Connection name** and use your credentials to authenticate to GitHub. You can use OAuth or a PAT Token to authenticate to GitHub.  Then select this GitHub repository (your forked repo.) and click on **Continue**.  See image below.

   ![alt tag](./images/A-03.PNG)

   In the **Select a template** page, click on **Empty Job**.  Next, select the **Default** *Agent pool* or other agent pool which you might have created in the parent project labs.  Then click on the **+** symbol besides **Agent job 1**.  See screenshot below.

   ![alt tag](./images/A-04.PNG)

   Under **Add tasks**, search for text **Docker Compose** and add this task to the CI pipeline.  This task will be used to build a *Custom* Jenkins container image containing Jenkins Plugins, Docker client and Kubernetes CLI installed on it.  Review the **Dockerfile** in the GitHub repository to view which binaries will be installed in the container image once it is built.

   ![alt tag](./images/A-05.PNG)

   Click on **Docker Compose** task in the left panel and update all field values marked with a **blue** checkmark as shown in the screenshot below.

   ![alt tag](./images/A-06.PNG)

   Add another **Docker Compose** task to the CI pipeline.  This task will be used to push the built custom Jenkins container image into the ACR (Azure Container Repository).   This ACR should have been provisioned in the parent project labs.  Click on this task in the left panel and update all field values marked with a **blue** checkmark as shown in the screenshot below.

   ![alt tag](./images/A-07.PNG)

   Search for task **Copy files** and add it to the CI pipeline.  This task will be used to copy the Helm chart folder to a staging directory.

   Configure this task as shown in the screenshot below.

   ![alt tag](./images/A-19.PNG)

   Search for task **Publish Build Artifacts** and add it to the CI pipeline.  This task will be used to publish the Helm chart folder from the staging directory to a **drop** location which would be accessible in the CD (Release) pipeline.

   Configure the task as shown in the images below.

   ![alt tag](./images/A-20.PNG)

   ![alt tag](./images/A-21.PNG)

   Click on **Save** in the tab panel (on top) to save the build definition.  Then run a build by clicking on **Queue** in the tab panel on top as shown in the image below.  Alternatively, click **Save and Queue** in the tab panel to save the build definition and queue it for execution on the build agent.

   ![alt tag](./images/A-17.PNG)

   The build will take approx. 10-15 mins to finish.  Proceed with the next step when the build finishes Ok.

   ![alt tag](./images/A-18.PNG)

2. In this step we will implement the CD (Continuous Deployment) pipeline in Azure DevOps to deploy Jenkins on AKS.

   Before proceeding, review the Helm Chart artifacts in directory `./jenkins-chart`.

   We will use the new Azure DevOps UI for completing this step.  Click on your account name in the top panel then select *Preview features* in the drop down menu and enable the features as shown in the screenshots below.

   ![alt tag](./images/A-08.PNG)

   ![alt tag](./images/A-09.PNG)

   Click on **Releases** in the left panel and then click on **New Pipeline**.  Select an **Empty job** in the **Select a template** panel.  In the field **Stage name**, specify a meaningful value (eg., AKS-Dev-Deploy) and click on the *X* to clear the panel.  See screenshot below.

   ![alt tag](./images/A-10.PNG)

   Change the name of the CD pipeline as shown in the image below.

   ![alt tag](./images/A-13.PNG)

   Under **Artifacts**, click on **Add an artifact** and select **Build** as the **Source type**.  Specify values as shown in the image below.  Remember to select the build pipeline which was implemented in the previous step in field **Source**.  Click on **Add**.

   ![alt tag](./images/A-11.PNG)

   With this configuration, the CD pipeline will be triggered and executed when the CI pipeline completes OK.

   Under **Stages**, click on **1 job, 0 task**.  Then click on **Agent job** and make sure the **Agent pool** which was created in the parent project lab (Default) is selected as shown in the image below.

   ![alt tag](./images/A-12.PNG)

   Click on the + sign besides **Agent job** to add a new release *Task*. Search for text **Helm** in the search field besides **Add tasks**.  And **Add** the **Helm tool installer** task.

   ![alt tag](./images/A-14.PNG)

   In the task configuration panel, uncheck checkboxes for **Check for latest version of Helm** and **Install Kubectl** as shown below.

   ![alt tag](./images/A-15.PNG)

   Click on the + sign besides **Agent job** and search for text **Helm** again.  Add the task named **Package and deploy Helm charts** to the release pipeline.  See screenshot below.

   ![alt tag](./images/A-16.PNG)

   Click on the **Helm** task you just added and configure values as shown in the screenshots below.  Provide correct values for all fields marked with a blue tick mark.

   ![alt tag](./images/A-22.PNG)

   ![alt tag](./images/A-23.PNG)

   After updating all values, click on **Save**.  You can now run the CD pipeline by creating a new **Release** and deploying it or by re-running the **CI** (Build) pipeline.

   Proceed with Section [B] when the CD pipeline completes OK.  See screenshot below.

   ![alt tag](./images/A-24.PNG)

### B] Implement a Continuous Delivery (CD) pipeline for *po-service* microservice in Jenkins
**Approx. time to complete this section: 1 Hour**

1. Open a terminal window and connect to the Bastion host (Linux VM) via SSH.  Use the command below to ascertain the IP address of the **Jenkins** service.  The value under column *EXTERNAL-IP* is the host IP.
   ```
   gradhakr@garadha-surface:~/git-repos/k8s-springboot-data-rest/extensions/jenkins-ci-cd$ kubectl get svc -n jenkins
   NAME                              TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
   amber-nightingale-jenkins-chart   LoadBalancer   10.0.115.162   104.42.121.82   80:31573/TCP   11h
   ```
   Use to web browser to access the Jenkins UI.  
   **NOTE:** For the purposes of this lab, security in Jenkins has been disabled.

2. In this step, add a global variable *ACR_LOGINSERVER' which will be used in the CD pipeline.

   Click on **Manage Jenkins** on the left nav panel.  See image below.
  
   ![alt tag](./images/B-01.PNG)
  
   Then click on **Configure System**.  In the configuration web page, check the box for **Environment variables** under **Global properties**.  Add an environment variable named **ACR_LOGINSERVER**.  Specify the variable value to be the name of your ACR which you deployed in the parent project.  It should be of the form **xxxx**.azurecr.io, where *xxxx* is the name of your registry.  Also, under *Build Timestamp*, change the value of *Pattern* to only include the year, month and day (yyyy-MM-dd).  See screenshot below.

   ![alt tag](./images/B-02.PNG)

   Click **Save**.

3. Store the ACR SP credentials (created in parent project) in Jenkins Credential vault.

   This credential will be used to access ACR in the CD pipeline.

   Click on **Credentials** on the left nav panel.  See image below.  

   ![alt tag](./images/B-03.PNG)

   Click on **Jenkins** link under **Stored scoped to Jenkins** as shown in the image below.

   ![alt tag](./images/B-04.PNG)

   Click on **Global credentials (unrestricted)** link. Then click on **Add Credentials** link as shown in the image below.

   ![alt tag](./images/B-05.PNG)

   In the next web page, provide the details as shown in the image below.  For **Username**, specify the Azure Service Principal (SP) **appId** value and for **Password** specify the SP **password**.  Recall that you created a SP for ACR in the parent lab (Section [B], Step 3) and the SP **appId** and **password** should have been saved in a file **SP_ACR.txt** in the project directory.  For **ID**, specify the value `acr-credentials`.  These values are needed for pushing the built *po-service* container image into ACR.

   ![alt tag](./images/B-06.PNG)

   Click **OK**.

4. Store the AKS credentials (Kube Config) in Jenkins Credential vault.

   This credential will be used to deploy the *po-service* microservice on AKS in the CD pipeline.

   Click on **Add Credentials** link again.  Provide the values as shown in the image below.  In the dropdown box for **Kind**, select value `Secret file`.  Click on **Choose File** and select the *Kubernetes Config* file which you saved in the parent project labs.  Specify value `aks-credentials` for field **ID** and enter a short description for this credential in the **Description** field.

   ![alt tag](./images/B-14.PNG)

   Click **OK**.  Then click on the **Jenkins** link on the top nav panel as shown in the image below.

   ![alt tag](./images/B-07.PNG)

5. Next, define a CD Pipeline.

   Click on **New Item** in the left nav panel OR click on **create new jobs** link.

   ![alt tag](./images/B-08.PNG)

   Give the CD pipeline a meaningful name and select the **Pipeline** project as shown in the image below.

   ![alt tag](./images/B-09.PNG)

   Click **OK**.  On the configuration web page and in the **Description** field, provide a brief description for this pipeline.  In the **General** section, select the checkbox besides **GitHub Project** and specify the URL for the GitHub project which you forked in the parent project.  Make sure the URL is the URL for your forked GitHub repository.  See screenshot below.

   ![alt tag](./images/B-10.PNG)

   Under **Build Triggers**, click the checkbox besides **GitHub hook trigger for GITScm polling**.

   ![alt tag](./images/B-11.PNG)

   Under **Pipeline**, besides **Definition** select *Pipeline script from SCM*.  In the drop down box for **SCM**, select *Git* and specify this GitHub URL (Your forked repo.) for field **Repository URL**.  For field **Script Path**, specify value `extensions/jenkins-ci-cd/Jenkinsfile`.  Leave other field values as is.  Click **Save** when you are done.  See screenshot below.

   ![alt tag](./images/B-12.PNG)

5. In the next page, click **Build Now** in the left nav panel.

   ![alt tag](./images/B-13.PNG)

   The *Pipeline Stage View* plugin will display the progress of the pipeline execution.  See below.

   ![alt tag](./images/B-15.PNG)

   While waiting for the pipeline execution to finish, open `./Jenkinsfile` and go thru the *Pipeline* stages and steps.

   All the pipeline stages should complete OK (green box) as shown in the image below.

   ![alt tag](./images/B-16.PNG)
    
   To review the pipeline execution log and/or troubleshoot problems when any of the pipeline stages fail, click on the **Build #** under **Build History** and then click on **Console Output**.  Alternatively, you can also click on **Pipeline Steps** to review the details (log output) of each step executed during each stage.

   ![alt tag](./images/B-17.PNG)


   You have now successfully completed this lab.  Congrats!

   To recap, during this lab you completed the following steps -
   - Defined a **Build (CI)** and **Release (CD)** pipeline in *Azure DevOps* to build a custom Jenkins container image and then deployed Jenkins on *Azure Kubernetes Service*
   - Defined and executed a **Continuous Delivery** pipeline in Jenkins and re-deployed the *po-service* microservice on *Azure Kubernetes Service*.

   You can return to the [parent project](https://github.com/ganrad/k8s-springboot-data-rest) to work on another sub-project.  Happy Kubernet'ing!
