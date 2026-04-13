pipeline {
    agent any

    environment {
        // We will configure these secure passwords in Jenkins shortly
        DOCKER_HUB_CREDS = 'docker-hub-credentials'
        AWS_CREDS = 'AWS-credentials'
        
        
        DOCKER_IMAGE = "pradeev812/java-maven-app:latest"
    }

    stages {
        stage('1. Build Java App & Docker Image') {
            steps {
                script {
                    echo "Compiling Java and Building Docker Image..."
                    // Our multi-stage Dockerfile handles the Maven compile AND the Docker build!
                    bat "docker build -t ${DOCKER_IMAGE} ."
                }
            }
        }

        stage('2. Push to Docker Hub') {
            steps {
                script {
                    echo "Logging into Docker Hub and pushing image..."
                    withCredentials([usernamePassword(credentialsId: env.DOCKER_HUB_CREDS, passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        // Securely log in and push
                        bat "echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin"
                        bat "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }

        stage('3. Provision AWS EC2 (Terraform)') {
            steps {
                script {
                    echo "Asking AWS for a new server..."
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDS, accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                        bat "terraform init"
                        // Build the server automatically without asking for yes/no confirmation
                        bat "terraform apply -auto-approve"
                        
                        // Extract the new Public IP address from Terraform and save it as a variable
                        bat "terraform output -raw server_public_ip > ip.txt"
                        env.EC2_IP = readFile('ip.txt').trim()
                    }
                }
            }
        }

        stage('4. Deploy Application') {
            steps {
                script {
                    echo "Waiting 60 seconds for the new EC2 server to boot up and install Docker..."
                    sleep time: 60, unit: 'SECONDS'
                    
                    echo "Deploying to New EC2 Instance at ${env.EC2_IP}..."
                    
                    withCredentials([sshUserPrivateKey(credentialsId: 'aws-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                        
                        // THE FIX: Lock down the temporary file so OpenSSH accepts it!
                        bat "icacls \"%SSH_KEY%\" /inheritance:r /grant:r sspra:F"
                        
                        // Copy the docker-compose file
                        bat "scp -o StrictHostKeyChecking=no -i \"%SSH_KEY%\" docker-compose.yaml %SSH_USER%@%EC2_IP%:/home/ubuntu/"
                        
                        // SSH into the server and start the app
                        bat """
                        ssh -o StrictHostKeyChecking=no -i \"%SSH_KEY%\" %SSH_USER%@%EC2_IP% "export DOCKER_IMAGE=${DOCKER_IMAGE} && sudo docker-compose up -d"
                        """
                    }
                }
            }
        }
    }
}
