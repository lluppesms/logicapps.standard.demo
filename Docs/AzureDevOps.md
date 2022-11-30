# Azure DevOps Deployment Template Notes

## 1. Azure DevOps Template Definitions

### Environment Workflows

- **deploy-infra-only-pipeline.yml:** Deploys the main.bicep template and does nothing else.

- **deploy-app-only-pipeline.yml:** Builds the function app and then deploys the function app to the Azure Function

- **deploy-infra-and-code-pipeline.yml:** Deploys the main.bicep template, builds the function app, then deploys the function app to the Azure Function

  *Note: Typically admins will set up the either first and second option - or - the third option, but not all three jobs.*

### Design Workflows

- **design-setup-pipeline.yml:** This job creates the design environment where users can edit their workflows in the portal.

- **design-refresh-workflows-pipeline.yml:** Pipeline which design user manually triggers when they are done making changes in the portal, which will push changes into a branch of this repo and initiate a pull request.

- **design-publish-changes-pipeline.yml:** This pipeline is triggered by a change in the 'Version/workflow_version.txt' file, which is updated by the 'design-refresh-workflows-pipeline' pipeline. This pipeline publishes the workflows in the repository to the desired environments.

---

## 2. Deploy Environments

These Azure DevOps YML files were designed to run as multi-stage environment deploys (i.e. DEV/QA/PROD). Each Azure DevOps environments can have permissions and approvals defined. For example, DEV can be published upon change, and QA/PROD environments can require an approval before any changes are made.

---

## 3. Setup Steps

- [Create Azure DevOps Service Connections](https://docs.luppes.com/CreateServiceConnections/)

- [Create Azure DevOps Environments](https://docs.luppes.com/CreateDevOpsEnvironments/)

- Create Azure DevOps Variable Groups - see next step in this document (the variables are unique to this project)

- [Create Azure DevOps Pipeline(s)](https://docs.luppes.com/CreateNewPipeline/)

---

## 4. Creating the variable group "LogicAppDemo"

To create this variable groups, customize and run this command in the Azure Cloud Shell.

This example sends a text message so you will want to have a Twilio account set up if you want to test with that.

``` bash
az pipelines variable-group create 
  --organization=https://dev.azure.com/<yourAzDOOrg>/ 
  --project='<yourAzDOProject>' 
  --name LogicAppDemo
  --variables 
      appPrefix='<yourInitials>' 
      appName='logicstddemo'
      azureSubscription='<yourSubscriptionName/serviceConnectionName>' 
      region='eastus' 
      keyVaultOwnerUserId='<userSID>'
      runSecurityDevOpScan='true'
```

---

## 5. Using the Portal to Design Logic Apps

This example was designed allow the user to modify a logic app in the portal and have those changes saved and checked into source control, then deployed to other environment via an automated pipeline

See: [Update Logic App Repository](/Docs/RefreshWorkflowPipeline.md)

---

## 6. Azurite Issues?

For local development of Azure Functions, it is preferable to use local storage with Azurite.  However, there is a bug with Azurite 3.17, so currently if you have problems with it, the best way to fix this is to install an older version of Azureite via NPM:
>
> ``` bash
> npm uninstall -g azurite
> npm install -g azurite@3.16.0
> ```

To run Azureite, you may have to open a command shell in Administrator Mode and run it like this:

> ``` bash
> > cd C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\Extensions\Microsoft\Azure Storage Emulator
> > azurite.exe
> ```

[Reference: Using Azurite Local Storage](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite?toc=%2Fazure%2Fstorage%2Fblobs%2Ftoc.json&tabs=visual-studio)
