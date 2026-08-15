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

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Sabspratik22/teraform-project.git'
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
            when { expression { params.ACTION == 'APPLY' } }
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Terraform Apply') {
            when { expression { params.ACTION == 'APPLY' } }
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }

        stage('Wait For EC2') {
            when { expression { params.ACTION == 'APPLY' } }
            steps {
                sh 'sleep 60'
            }
        }

        stage('Get EC2 IP') {
            when { expression { params.ACTION == 'APPLY' } }
            steps {
                script {
                    env.EC2_IP = sh(
                        script: 'terraform output -raw public_ip',
                        returnStdout: true
                    ).trim()
                    echo "EC2 Public IP: ${env.EC2_IP}"
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

        stage('Destroy Infrastructure') {
            when { expression { params.ACTION == 'DESTROY' } }
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
