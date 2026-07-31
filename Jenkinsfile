pipeline {
    agent {
        label 'agent-server'
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['APPLY', 'DESTROY'],
            description: 'Choose Terraform Action'
        )
    }

    environment {
        AWS_DEFAULT_REGION = 'eu-north-1'
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Sabspratik22/teraform-project.git'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            when {
                expression {
                    params.ACTION == 'APPLY'
                }
            }
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Build Infrastructure') {
            when {
                expression {
                    params.ACTION == 'APPLY'
                }
            }
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }

        stage('Destroy Infrastructure') {
            when {
                expression {
                    params.ACTION == 'DESTROY'
                }
            }
            steps {
                sh 'terraform destroy -auto-approve'
            }
        }
    }

    post {
        success {
            echo "Terraform ${params.ACTION} completed successfully."
        }

        failure {
            echo "Terraform ${params.ACTION} failed."
        }

        always {
            echo "Pipeline execution finished."
        }
    }
}
