# Ci-CD Pipeline

## Findings

We have been facing pipeline recurrence issues with npm install commands on the given dependencies which required npm resolutions fixing.
Through our research on the usage of the given dependencies, we have come to realization of that most dependencies specified are not necessarily neither being made use in the pipeline nor the policy code analysis thus making them redundant.

`package json` content given below

```json
{
  "name": "mocha-tests-demo",
  "version": "1.0.0",
  "description": "a demo for running mocha tests",
  "resolutions": {
 "tough-cookie": "4.1.3"
 },
  "scripts": {
 "preinstall": "npx npm-force-resolutions",
    "test": "mocha --reporter mocha-xunit-reporter --reporter dot",
    "coverage": "nyc --reporter html --reporter cobertura --reporter text npm test"
  },
  "author": "",
  "license": "ISC",
  "dependencies": {
    "JSONPath": "^0",
    "is-my-json-valid": "^2",
    "path": "^0",
    "prettyjson": "^1",
    "request": "^2",
    "swagger-tools": "^0",
    "@xmldom/xmldom": "^0",
    "xpath.js": "^1",
    "apickli": "latest"
  },
  "devDependencies": {
    "chai": "^4.1.2",
    "expect.js": "*",
    "mocha": "^4.0.1",
    "mocha-xunit-reporter": "^1.1.0",
    "nyc": "^14.1.1",
    "rewire": "*",
    "sinon": "*",
    "cucumber": "^5",
    "eslint": "^5",
    "eslint-config-google": "^0",
    "cucumber-html-reporter": "^4",
    "fs-extra": "^7",
    "argv": "^0"
  }
}
```

From the above, we realize that the particular dependencies are usually used to do javascript testing, coverage reports, json validations, xml validations all these in javascript codes. Given this information and putting the process of apigee into consideration, we observe that we are not doing javascript testing on the proxies.

We are doing apigee lint policy code analysis and the required dependencies are being installed on the fly in the `Jenkins` pipeline file.

Also on newman integration tests, the required dependencies are being installed on the fly in the `integrations.sh` script.

## Resolutions

We proceeded to remove the sections requiring `npm resolutions` from the pipeline and the dependencies section in the package json file thus ending up with the following files updates. this has increased the pipeline speed as no extra unused dependencies being installed and also the security risks always reported on the veracode scans.

`package.json`

```json
{
  "name": "mocha-tests-demo",
  "version": "1.0.0",
  "description": "a demo for running mocha tests",
  "resolutions": {},
  "scripts": {},
  "author": "",
  "license": "ISC",
  "dependencies": {},
  "devDependencies": {}
}
```

and `Jenkinsfile`

```groovy
#!groovy
def stable_revision = 'initial_value' 
def access_token = 'initial_value'
pipeline {
    agent any
    tools {
        maven 'M3'
        nodejs 'nodejs-update'
    }
    environment {
 
  ProxyName = 'apigee-standard-template'
  ENV = 'apistg-fs-general'
  org = 'sfc-kenya-hybrid-non-prod'
  developer = 'umairhanif@test.com'
  app = 'UmairApp'
  Newman_Target_Collection = 'test-call-integration-sfc-kenya.postman_collection.json'
        base64encoded_apikey = credentials('base64encoded_apikey')
  
  }

    stages{ 
   stage('Main') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'develop' || env.BRANCH_NAME == 'preprod' || env.BRANCH_NAME == 'feature' ) {
                        stage('Initial-Checks') {
       
        office365ConnectorSend webhookUrl: "https://safaricomo365.webhook.office.com/webhookb2/1f198d4b-1b75-49e8-8032-d4441104de46@19a4db07-607d-475f-a518-0e3b699ac7d0/JenkinsCI/57b04be56f004ad8936b7859ab072e67/dfc7bf82-7b0d-4e0a-b2ff-9b9d4eee8548",
        message: "Started Pipeline/Job: ${env.JOB_NAME} Build Number: ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
        
        sh "node -v"
        sh "npm -v"
        sh "mvn -v"
        sh "cd $WORKSPACE && npm install -g force-resolutions && npm install"
        
        script{
        if (env.org == 'sfc-kenya-hybrid-prod')

          { 
         access_token = sh(script: 'curl -k -H "apikey: $base64encoded_apikey" "https://apistg.safaricom.co.ke/sfc_mangtapiaccesstoken/sfcprod" | jq -r ".access_token"', returnStdout: true).trim()
         env.access_token = access_token
         }

        else if (env.org == 'sfc-kenya-hybrid-non-prod')
         
         { 
         access_token = sh(script: 'curl -k -H "apikey: $base64encoded_apikey" "https://apistg.safaricom.co.ke/sfc_mangtapiaccesstoken/sfcnonprod" | jq -r ".access_token"', returnStdout: true).trim()
         env.access_token = access_token
         } 
        }       
       
        echo "access_token: ${access_token}"
        
        script{
        try{
        stable_revision = sh(script: 'curl -k -H "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$org/environments/$ENV/apis/$ProxyName/deployments" | jq -r ".deployments[].revision"', returnStdout: true).trim()
        } catch (e) {
        stable_revision = null
         }
        }
        env.stable_revision = stable_revision 
        echo "Stable Revision: ${stable_revision}"
        //echo "Stable Revision: ${env.stable_revision}"
       
      } 

      stage('Veracode SCA scan') {
          withCredentials([string(credentialsId: 'SRCCLR_API_TOKEN', variable: 'SRCCLR_API_TOKEN')]) {
          sh 'curl -sSL https://download.sourceclear.com/ci.sh | sh'
          }
       
      }

      stage('Policy-Code Analysis') {

                                        script {
                                            try {
                                            sh "cd $WORKSPACE && npm install -g apigeelint && apigeelint -V"
                                            sh "cd $WORKSPACE && apigeelint -s $ProxyName/apiproxy -f html.js --excluded BN003 > ./reports/index.html"
                                            } catch (e) {
                                                throw e
                                            } finally {
                                            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './reports', reportFiles: 'index.html', reportName: 'Apigee Lint Report', reportTitles: 'Apigee Lint Report'])
                                            }
                                    }

                        }

      
      stage('Deploy to Apigee') {
        //deploy using maven plugin

        sh "mvn clean install -f $WORKSPACE/${ProxyName}/pom.xml -P$ENV -Dorg=${env.org} -Dbearer=${access_token}"
      } 

     /* stage('Integration Test Newman') {
        script {
         try {
          sh "cd $WORKSPACE/scripts && sh && sh integration.sh"
         } catch (e) {
          //if tests fail, I have used an shell script which has 3 APIs to undeploy, delete current revision & deploy previous stable revision
          rev_num = sh(script: 'curl -k -H "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$org/environments/$ENV/apis/$ProxyName/deployments" | jq -r ".deployments[].revision"', returnStdout: true).trim()
          env_name = sh(script: 'curl -k -H "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$org/environments/$ENV/apis/$ProxyName/deployments" | jq -r ".deployments[].environment"', returnStdout: true).trim()
          echo "rev_num: $rev_num"
          echo "env_name: $env_name"
          sh "cd $WORKSPACE/scripts && sh && sh undeploy.sh $stable_revision $rev_num $env_name"
          throw e
         } 
         finally {
        publishHTML([allowMissing: true,
        alwaysLinkToLastBuild: true,
        keepAll: true,
        reportDir: './test/integration/reports',
        reportFiles: 'Newman_Integration_Tests_Report_$BUILD_NUMBER.html',
        reportName: 'Newman_Integration_Tests_Report',
        reportTitles: ''])
         }
        }
      } */
                    }  else {
      
      stage('Initial-Checks') {
       
        office365ConnectorSend webhookUrl: "https://safaricomo365.webhook.office.com/webhookb2/1f198d4b-1b75-49e8-8032-d4441104de46@19a4db07-607d-475f-a518-0e3b699ac7d0/JenkinsCI/57b04be56f004ad8936b7859ab072e67/dfc7bf82-7b0d-4e0a-b2ff-9b9d4eee8548",
        message: "Started Pipeline/Job: ${env.JOB_NAME} Build Number: ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
        
        sh "node -v"
        sh "npm -v"
        sh "mvn -v"
        sh "cd $WORKSPACE  && npm install"
       
      }
      
                        stage('Veracode SCA scan') {
       
          withCredentials([string(credentialsId: 'SRCCLR_API_TOKEN', variable: 'SRCCLR_API_TOKEN')]) {
          sh 'curl -sSL https://download.sourceclear.com/ci.sh | sh'
          }
       
       }

      stage('Policy-Code Analysis') {

                                        script {
                                            try {
                                            sh "cd $WORKSPACE && npm install -g apigeelint && apigeelint -V"
                                            sh "cd $WORKSPACE && apigeelint -s $ProxyName/apiproxy -f html.js --excluded BN003 > ./reports/index.html"
                                            } catch (e) {
                                                throw e
                                            } finally {
                                            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './reports', reportFiles: 'index.html', reportName: 'Apigee Lint Report', reportTitles: 'Apigee Lint Report'])
                                            }
                                    }

                        }
                     }
                    }
            }
        }
     
  
   
 }


 post {
    success {
     //Sending MS Teams Notifications about Pipeline/Job Success!
     office365ConnectorSend webhookUrl: "https://safaricomo365.webhook.office.com/webhookb2/1f198d4b-1b75-49e8-8032-d4441104de46@19a4db07-607d-475f-a518-0e3b699ac7d0/JenkinsCI/57b04be56f004ad8936b7859ab072e67/dfc7bf82-7b0d-4e0a-b2ff-9b9d4eee8548",
     message: "Pipeline/Job: ${env.JOB_NAME} Build Number: ${env.BUILD_NUMBER} completed successfully!",
     status: "Success"
    }
    failure {
      //Sending MS Teams Notifications about Pipeline/Job Failure!
     office365ConnectorSend webhookUrl: "https://safaricomo365.webhook.office.com/webhookb2/1f198d4b-1b75-49e8-8032-d4441104de46@19a4db07-607d-475f-a518-0e3b699ac7d0/JenkinsCI/57b04be56f004ad8936b7859ab072e67/dfc7bf82-7b0d-4e0a-b2ff-9b9d4eee8548",
     message: "Pipeline/Job: ${env.JOB_NAME} Build Number: ${env.BUILD_NUMBER} failed!",
     status: "Failure"
    }
 } 
} 
```

**N/B**: No update made to the `integrations.sh` and all the other files.

If there is anything we might have overlooked with regard to the dependencies, let me know.
