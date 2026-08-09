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
        SSH_KEY = '/home/ubuntu/terraform-key.pem'
    }

    stages { 
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
        SSH_KEY = '/home/ubuntu/terraform-key.pem'
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
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }

        stage('Get EC2 IP') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                script {
                    env.EC2_IP = sh(
                        script: "terraform output -raw public_ip",
                        returnStdout: true
                    ).trim()

                    echo "EC2 Public IP: ${env.EC2_IP}"
                }
            }
        }

        stage('Create Ansible Inventory') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sh '''
                cat > inventory.ini << EOF
                [servers]
                ${EC2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY}
                EOF

                cat inventory.ini
                '''
            }
        }

        stage('Install Java Using Ansible') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sh '''
                cat > java-install.yml << EOF
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
                EOF

                ansible-playbook -i inventory.ini java-install.yml
                '''
            }
        }

        stage('Verify Java') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sh 'ansible -i inventory.ini servers -m shell -a "java -version"'
            }
        }

        stage('Destroy Infrastructure') {
            when {
                expression { params.ACTION == 'DESTROY' }
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
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }

        stage('Get EC2 IP') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                script {
                    env.EC2_IP = sh(
                        script: "terraform output -raw public_ip",
                        returnStdout: true
                    ).trim()

                    echo "EC2 Public IP: ${env.EC2_IP}"
                }
            }
        }

        stage('Create Ansible Inventory') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sh '''
                cat > inventory.ini << EOF
                [servers]
                ${EC2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY}
                EOF

                cat inventory.ini
                '''
            }
        }

        stage('Install Java Using Ansible') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sh '''
                cat > java-install.yml << EOF
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
                EOF

                ansible-playbook -i inventory.ini java-install.yml
                '''
            }
        }

        stage('Verify Java') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sh 'ansible -i inventory.ini servers -m shell -a "java -version"'
            }
        }

        stage('Destroy Infrastructure') {
            when {
                expression { params.ACTION == 'DESTROY' }
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
