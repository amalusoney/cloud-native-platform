pipeline {
    agent any

    environment {
        AWS_REGION        = 'us-east-1'
        AWS_ACCOUNT_ID    = '810299942488'
        ECR_REPO          = 'cloud-native-app'
        ECR_REGISTRY      = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_NAME        = "${ECR_REGISTRY}/${ECR_REPO}"
        EKS_CLUSTER_NAME  = 'cloud-native-eks'
        PATH              = "/usr/local/bin:/usr/bin:/bin:${env.PATH}"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo 'Checking out source code from Git...'
                checkout scm
            }
        }

        stage('Lint & Quality Check') {
            steps {
                echo 'Running Python code linting with flake8...'
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install --upgrade pip
                    pip install -r app/requirements.txt
                    flake8 app/ --count --select=E9,F63,F7,F82 --show-source --statistics
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                echo 'Running automated Pytest suite...'
                sh '''
                    . .venv/bin/activate
                    PYTHONPATH=app pytest app/test_main.py -v
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image ${IMAGE_NAME}:${BUILD_NUMBER}..."
                sh """
                    docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} -t ${IMAGE_NAME}:latest ./app
                """
            }
        }

        stage('Trivy Security Scan') {
            steps {
                echo 'Scanning container image with Trivy for CVE vulnerabilities...'
                sh """
                    if command -v trivy >/dev/null 2>&1; then
                        trivy image --severity HIGH,CRITICAL --exit-code 0 ${IMAGE_NAME}:${BUILD_NUMBER}
                    else
                        echo 'Trivy not installed locally, running via Docker container...'
                        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --exit-code 0 ${IMAGE_NAME}:${BUILD_NUMBER}
                    fi
                """
            }
        }

        stage('Push to Amazon ECR') {
            steps {
                echo 'Authenticating with Amazon ECR using AWS IAM Role...'
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Deploy to Amazon EKS') {
            steps {
                echo "Deploying application to EKS cluster: ${EKS_CLUSTER_NAME}..."
                sh """
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                    kubectl apply -f k8s/
                    kubectl rollout status deployment/cloud-native-app -n default --timeout=120s || true
                    kubectl get pods -l app=cloud-native-app -o wide
                    kubectl get svc cloud-native-app-service
                """
            }
        }
    }

    post {
        always {
            echo 'Cleaning up temporary virtualenv and dangling Docker images...'
            sh '''
                rm -rf .venv
                docker image prune -f || true
            '''
        }
        success {
            echo 'Pipeline completed successfully! New version deployed to EKS.'
        }
        failure {
            echo 'Pipeline failed! Check stage logs for details.'
        }
    }
}
