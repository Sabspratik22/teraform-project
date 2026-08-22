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
        AWS_REGION     = 'us-east-2'
        ECR_REPO_NAME  = 'my-app-repo'
        AWS_ACCOUNT_ID = '425034746613'
        IMAGE_TAG      = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Sabspratik22/teraform-project.git'
            }
        }

        stage('Pre-build Cleanup') {
            steps {
                sh '''
                echo "Disk usage before cleanup:"
                df -h /
                docker system prune -af --volumes || true
                echo "Disk usage after cleanup:"
                df -h /
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-creds'
                ]]) {
                    sh 'terraform init -input=false -reconfigure'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-creds'
                ]]) {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            when { expression { params.ACTION == 'APPLY' } }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-creds'
                ]]) {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            when { expression { params.ACTION == 'APPLY' } }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-creds'
                ]]) {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Get EC2 IP') {
            when { expression { params.ACTION == 'APPLY' } }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-creds'
                ]]) {
                    script {
                        env.EC2_IP = sh(
                            script: 'terraform output -raw public_ip',
                            returnStdout: true
                        ).trim()
                        echo "EC2 Public IP: ${env.EC2_IP}"
                    }
                }
            }
        }

        stage('Wait For SSH Ready') {
            when { expression { params.ACTION == 'APPLY' } }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'key-id', keyFileVariable: 'SSH_KEY_FILE')]) {
                    sh """
                    echo "Waiting for SSH on \${EC2_IP}..."
                    for i in \$(seq 1 20); do
                        if ssh -i "\$SSH_KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 ubuntu@${EC2_IP} 'echo connected' 2>/dev/null; then
                            echo "SSH is up"
                            exit 0
                        fi
                        echo "Attempt \$i failed, retrying in 10s..."
                        sleep 10
                    done
                    echo "SSH never became available"
                    exit 1
                    """
                }
            }
        }

        stage('Ansible Setup and Run') {
            when { expression { params.ACTION == 'APPLY' } }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'key-id', keyFileVariable: 'SSH_KEY_FILE')]) {
                    sh """
                    cat > inventory.ini <<EOF
[servers]
${EC2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_FILE} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF
                    cat inventory.ini

                    cat > java-install.yml <<'EOF'
---
- name: Install Java 21
  hosts: servers
  become: yes

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install OpenJDK 21
      apt:
        name: openjdk-21-jdk
        state: present

    - name: Verify Java Version
      command: java -version
      register: java_output
      ignore_errors: yes

    - debug:
        var: java_output.stderr_lines
EOF

                    ansible-playbook -i inventory.ini java-install.yml
                    ansible -i inventory.ini servers -m shell -a "java -version"
                    """
                }
            }
        }

        stage('ECR Login') {
            when { expression { params.ACTION == 'APPLY' } }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-creds'
                ]]) {
                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }

        stage('Docker Build') {
            when { expression { params.ACTION == 'APPLY' } }
            steps {
                sh """
                docker build -t ${ECR_REPO_NAME}:${IMAGE_TAG} .
                docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest
                """
            }
        }

        stage('Docker Push to ECR') {
            when { expression { params.ACTION == 'APPLY' } }
            steps {
                sh """
                docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest
                """
            }
        }

        stage('Destroy Plan') {
            when { expression { params.ACTION == 'DESTROY' } }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-creds'
                ]]) {
                    sh 'terraform plan -destroy -out=destroy.tfplan'
                }
            }
        }

        stage('Confirm Destroy') {
            when { expression { params.ACTION == 'DESTROY' } }
            steps {
                input message: "Confirm DESTROY of infrastructure? This cannot be undone.", ok: "Yes, destroy it"
            }
        }

        stage('Terraform Destroy') {
            when { expression { params.ACTION == 'DESTROY' } }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-creds'
                ]]) {
                    sh 'terraform apply -auto-approve destroy.tfplan'
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline ${params.ACTION} completed successfully."
        }
        failure {
            echo "Pipeline ${params.ACTION} failed."
        }
        always {
            sh 'docker system prune -af --volumes || true'
        }
    }
}
