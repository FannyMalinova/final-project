# Budget App on AWS Using Terraform and GitHub Actions #

## Overview ##

The purpose of this project is to deploy a simple Pyhton-based application with a Postgres DB to AWS Cloud in a fully automated way. The automation includes a IaaC approach using Terraform and continuous integration and delivery using GitHub Actions. 

| Topic                     | Covered By                      |
| -------------             | --------------------------------|
| Source Control            |  Git (GitHub)                   |
| Branching Strategies      | main, release, feature branches |
| Building Pipelines        | GitHub Actions                  |
| Continuous Integration    | GitHub Actions                  |
| Continuous Delivery       | GitHub Actions                  |
| Public Cloud              | AWS                             |
| Docker                    | Docker and ECR                  |
| Infrastructure as code    | Terraform                       |
| Immutable Infrastructure  | Terraform                       |
| Observability             | CloudWatch                      |
| Secrets Management        | AWS Vault                       |
| Security                  | Snyk and Sonar scans            |

## Architecture on AWS ##

The following diagram depicts the architecture of the underlying infrastructure for the application deployment. 

![image](https://github.com/user-attachments/assets/76bdc257-27f6-4f91-bff7-9eeed1f5810d)

## Structure of the Project ##

The project includes three main folders:

### ./github/workflows ###

There are four GitHub Action workflows in total. 

| Workflow                | Trigger                   | Description                                                                     |
| :------------           |:---------------:          | :-----------------------------------------------------------------------------  |
| tests-and-checks.yml    | push to any branch      | Python and Terraform lints. Python App unit tests                                 |
| PR-checks.yml           | pull request to main      | Repeats the linting jobs and scans with Snyk and Sonar                          |
| build-and-deploy.yml    | merge to main or release  | Repeats the PR checks, runs the setup terraform project, builds the Docker      |    |                         |                           |  container, scans it with Trivy, pushes it to ECR, and deploys to ECS.          |    
|                         |                           |                                                                                 |
| destroy.yml             | manually                  | Destroys the entire infrastructure on AWS                                       |

### src ###

This is where the source code of the Budget App lives. 

| Folder  / Files           | Description                                                         |
| -------------             | --------------------------------------------------------------------|
| .py files                 | The Python source code of the application                           |
| tests                     | Tests for the Python application                                    |
| templates                 | The html templates that are served                                  |
| wait-for-postgres.sh      | A bash script that ensures the DB is available before the app runs  |

### terraform ###

#### docker-compose-terraform-setup.yml

To ensure consistency between Terraform runs from the local environment and through GitHub Actions workflows, Terraform is always run as a container, hence the need of this file. 

To speed up the deployment jobs upon pushing new code, the Terraform code is split into two separate projects.

#### setup #####

The setup project creates the long-living resources in AWS. These resources are created once and updated rarely, as opposed to the container image and the deployment.

| File                      | Covered By                                                                                                 |
| -------------             | -----------------------------------------------------------------------------------------------------------|
| variables.tf              | Variable definitions uded by the setup project                                                             |
| outputs.tf                | Outputs for the project, including those that will be used by the deploy project                           |  
| main.tf                   | Initializes the needed providers and sets the global prefix                                                |
| iam.tf                    | Creates the budget-user service account and assigns the needed permissios for intracting with AWS.         |
| ecr.tf                    | Creates the ECR repository                                                                                 |
| ecs.tf                    | Creates the ECS cluster, the log group and the security group                                              |
| network.tf                | Creates the VPC, two public, and two private subnets, gateway, ECR, SSM, CloudWatsh, and S3 endpoints      |
| ecs.tf                    | Creates the ECS cluster and sets the ingress and egress access                                             |
| dns.tf                    | Creates the DNS zone, sets the FQDN for the deployed application instance, and creates the TLS certificate |
| elb.tf                    | Creates the load balancer, its target and listeners                                                        |

#### deploy #####

| File                      | Covered By                                                                                                 |
| -------------             | -----------------------------------------------------------------------------------------------------------|
| variables.tf              | Variable definitions uded by the setup project                                                             |  
| main.tf                   | Initializes the needed providers and sets the global prefix. Loads the state file of the setup project     |
| database.tf               | Creates the DB subnet and security group, and the DB instance                                              |
| ecs.tf                    | Creates the ECS task and service definition, and definition for the container                              |

### .dockerignore and .gitignore ###

File types and folders to be ignored by Docker and Git, respectively.

### Dockerfile ###

The Dockerfile for the Budget App application. This Dockerfile is used by Terraform to build a container image, push it to ECR, and deploy a container in ECS.

### docker-compose.yml ###

Docker compose to run the Budget App locally. 

## Pre-Requisites ##

#### Accounts ####

- AWS account
- AWS user with Admin permissions but different from the root AWS user for security considerations
- GitHub account

#### Software ####

- Docker Desktop (with Docker Compose)
- AWS CLI
- AWS Vault
- AWS CLI Session Manager

#### Manually Created Resources in AWS ####

- S3 bucket to store the Terraform state file
- DynamoDB table to store the Terraform state file lock

#### GitHub Repository Variables and Secrets ####

##### Variables #####

| Variable                  | Description                                                                                                |
| -------------             | -----------------------------------------------------------------------------------------------------------|
| AWS_ACCESS_KEY_ID         | Access key for the service user created by Terraform. Available as output from the setup terraform job.    |  
| AWS_ACCOUNT_ID            | Account ID of the AWS Admin user.                                                                          |
| AWS_REGION                | Default AWS region where the AWS Admin user is creared.                                                    |
| ECR_REPO                  | Creates the ECS task and service definition, and definition for the container. Available as output.        |

##### Secrets #####

| Variable                  | Description                                                                                                |
| -------------             | -----------------------------------------------------------------------------------------------------------|
| AWS_SECRET_ACCESS_KEY     | Secret key of the service account created by Terraform. Available as sensitive output from setup.          |  
| APP_SECRET_KEY            | Secret key required by the Postgres database. Set manually.                                                |
| SNYK_TOKEN                | Token for interacting with Snyk.                                                                           |
| SONAR_TOKEN               | Tokem for interacting with Sonar Cloud.                                                                    |

## Execution ##

After the pre-requisites are met, any code changes should be done in a feature local branch. Pushing the feature branch to the GitHub repository triggers the Test and Checks GitHub Actions workflow. Once the job is successful, a pull request to the main branch is issued. The pull request triggers the PR Checks workflow that repeats the previous workflow and scans the code with Snyk and Sonar. 

In this project, the Terraform workspace feature is leveraged and for a better isolation, two separate workspaces are used - **staging** and **release**.

**_NOTE_**: Setup has to be run once locally - once for staging, and once for release, in order to trigger the creation of the local account and the assignment of the needed permissions. Later, on any update, a conditional change triggers its execution from the Build and Deploy GitHub Actions workflow.

If this job succeeds, a merge request to the main branch triggers the Build and Deploy workflow. It creates a deployment in a Terraform workspace called **staging** and prefixes all resources with a *staging* prefix. 

The public FQDN of the staging deployment of the Budget App application is: [budget-app-staging.fanislava.com](https://budget-app-staging.fanislava.com).

A merge into the release branch triggers a deployment in the release Terraform workspace and prefixes all created AWS resources with *release*, with the exeption of the public FQDN of the application that has no flags, but is simply [budget-app.fanislava.com](https://budget-app.fanislava.com).

## Future Improvements ##

The project needs optimization and a few improvements:
- the Tests and Checks workflow to be enhanced with conditional steps that trigger the Python and Terraform linting only when there have been changes in the corresponding folders. This will speed up the execution 
- a more consistent of the variables naming is required
- the Terraform projects should be restructured to use modules, as this will make the code more readable and intuitive
- the creation of the AWS service account should be decoupled from the setup and deploy projects and it should be the only thing ran locally, all the rest should go through the Github Actions workflows
- refactor the Dockerfile to use the *wait-for-postgres.sh* as an entry point
