pipeline {
agent any

options {
    timestamps()
    disableConcurrentBuilds()
}

environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
    TF_IN_AUTOMATION = 'true'
}

stages {
    stage('Checkout GitHub') {
        steps {
            checkout scm
        }
    }

    stage('Check Tools and Files') {
        steps {
            sh '''
                set -e
                git --version
                terraform -version
                aws --version

                test -f main.tf
                test -f website/index.html

                echo "Required tools and website files found."
            '''
        }
    }

    stage('Verify AWS IAM Role') {
        steps {
            sh '''
                set -e
                aws sts get-caller-identity
            '''
        }
    }

    stage('Terraform Init') {
        steps {
            sh 'terraform init -input=false'
        }
    }

    stage('Terraform Validate and Plan') {
        steps {
            sh '''
                set -e
                terraform fmt -check
                terraform validate
                terraform plan -input=false -out=tfplan
            '''
        }
    }

    stage('Approve Deployment') {
        steps {
            input message: 'Review the Terraform plan in Console Output. Approve deployment to AWS S3?'
        }
    }

    stage('Deploy to AWS') {
        steps {
            sh '''
                set -e
                terraform apply -input=false -auto-approve tfplan
                terraform output
            '''
        }
    }
}

post {
    success {
        echo 'Portfolio infrastructure deployment completed successfully.'
    }

    failure {
        echo 'Pipeline failed. Check Console Output for the error.'
    }

    always {
        deleteDir()
    }
}
}
