# Proxy-Repository-Apigee-CICD

## 1) Basic Concept
Proxy repository is the one where a proxy which has to be deployed on Apigee Hybrid, tested & undeployed in case of tests failure automatically using pipelines; Pipelines will deploy the proxy on APIGEE Hybrid UI using maven plugin.

## 2) Repository-Source Code & Branching Strategy
In Proxy repository Repository-Source Code Strategy will be as followed:
- 1 Project = 1 or more Repo(s) 
- 1 Repo = 1 proxy
- 1 branch against each logical environment
	- Let's say if you have 3 logical environment (DEV, UAT, PROD) than 3 branches will be utilized and will be used in each proxy repository
	
## 3) Directory & File Structure
There will be 3 main directories in this repository and 3 files.
- Target Proxy Directory (e.g. NoTargetProxy)
- "scripts" Directory 
- "test" Directory
- "Jenkinsfile" file
- "package.json" file
- "shared-pom.xml" file

### 3.1) Target Proxy Directory
This folder contains the target API proxy folder which has to be deployed to apigee. The name of the proxy repository should match with the name of this directory, because it is automatically set and used in the proxy pipeline. It contains following directories and files.
- "apiproxy" directory
- "pom.xml" file
- "config.json" file

#### 3.1.1) "apiproxy" directory
This folder contains the API proxy files in standard apigee API proxy directory structure. it contains the following subdirectories
- manifests directory
- policies directory
- proxies directory
- resources directory
- targets directory
- "ProxyName.xml" file e.g. NoTargetProxy.xml 

#### 3.1.2) "pom.xml" file
A Project Object Model or POM is the fundamental unit of work in Maven. It is an XML file that contains information about the project and configuration details used by Maven to build the project. It contains default values for most projects. When executing a task or goal, Maven looks for the POM in the current directory. It reads the POM, gets the needed configuration information, and then executes the goal. 
Some of the configuration that can be specified in the POM are the project dependencies, the plugins or goals that can be executed, the build profiles, and so on. Other information such as the project version, description, developers, mailing lists and such can also be specified.
This file is used in maven deployment of the proxy to apigee & it is a mandatory file for proxy deployment. It contains the important descriptions of an API proxy such as groupId, artifactId, version, name & packaging of the API proxy. It also contains the reference to the shared-pom/parent-pom which contains the shared necessary deployment configurations of the API proxy.

#### 3.1.3) "config.json" file
This files contain the Apigee Profile/Environment names and configurations.

### 3.2) "scripts" directory
This folder contains all the scripts files used in pipeline workflows which are as follows:
- integration.sh
- undeploy.sh

#### 3.2.1) integration.sh
This script is used for the integration testing of deployed proxy and execution of written integration tests in postman collection using newman.

#### 3.2.2) undeploy.sh
This script is called in case of integration tests failure, for undeploying the unstable revision and reverting back to stable revision of the target proxy.

### 3.3) "test" Directory
This folder contains “Integration” tests to be executed on the target API proxy in the form of Postman collections.

### 3.4) "Jenkinsfile" file
A Jenkinsfile is a text file that contains the definition of a Jenkins Pipeline and is checked into source control.

### 3.5) "package.json" file
The “package. json” file is the heart of any Node project. It records important metadata about a project which is required before publishing to NPM, and also defines functional attributes of a project that npm uses to install dependencies, run scripts, and identify the entry point to our package.

### 3.6) "shared-pom.xml" file
A Project Object Model or POM is the fundamental unit of work in Maven. It is an XML file that contains information about the project and configuration details used by Maven to build the project. It contains default values for most projects. When executing a task or goal, Maven looks for the POM in the current directory. It reads the POM, gets the needed configuration information, and then executes the goal. 
Some of the configuration that can be specified in the POM are the project dependencies, the plugins or goals that can be executed, the build profiles, and so on. Other information such as the project version, description, developers, mailing lists and such can also be specified.
This “shared-pom.xml” file is a reference file of “pom.xml” file which is used in proxy deployment to apigee. It contains the necessary information/tools required for the deployment.

## 4) Pipeline Workflow Execution Steps
This pipeline workflow will execute the b/m steps defined in Jenkinsfile:
- Checkout the repository to fetch source code in the Jenkins workspace
- Perform Initial checks by checking & displaying the tool versions on the console & Sending MS Teams Notifications about Pipeline/Job Start
- Perform static code analysis using Veracode
- Apigee Proxy Deployment to the desired Apigee Organization & Environment
- Running Integration Tests using Newman & genration of the HTML Report to be displayed on Jenkins Job 
- Send notification on Microsoft teams about the execution (Success & Failure) of the pipeline workflow

### 4.1) Workflow Environment Variables
Following environment variables are defined for this pipeline workflow.
- Proxy Name: Contains the name of target proxy for Deployment
- ORG: Target Apigee organization where the proxy will be deployed
- ENV: Target Apigee environment for proxy deployment. Branch name corresponds to the apigee environment as per our defined strategy
- developer: Apigee Developer Name
- app: Apigee App Name
- NEWMAN_TARGET_COLLECTION: Target API/Proxy collection containing the integration tests
