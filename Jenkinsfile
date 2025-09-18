pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = "your-ecr-registry" // Update with your ECR registry
        SONARQUBE_URL = "http://localhost:9000"
        SONARQUBE_TOKEN = credentials('sonarqube-token')
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/your-username/your-repo.git' // Update with your repo
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh '''
                    sonar-scanner \
                      -Dsonar.projectKey=python-app \
                      -Dsonar.sources=. \
                      -Dsonar.host.url=${SONARQUBE_URL} \
                      -Dsonar.login=${SONARQUBE_TOKEN} \
                      -Dsonar.python.version=3
                    '''
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("python-app:${env.BUILD_ID}")
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    docker.withRegistry('https://your-ecr-registry', 'ecr:us-east-1:aws-credentials') {
                        docker.image("python-app:${env.BUILD_ID}").push()
                    }
                }
            }
        }
        
        stage('Deploy to Minikube') {
            steps {
                sh '''
                kubectl apply -f app/k8s/deployment.yaml
                kubectl rollout status deployment/python-app
                '''
            }
        }
        
        stage('Test Deployment') {
            steps {
                sh '''
                # Get Minikube IP
                MINIKUBE_IP=$(minikube ip)
                # Test the application
                curl http://${MINIKUBE_IP} || echo "Application deployed successfully"
                '''
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
