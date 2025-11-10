pipeline {
    agent { label 'manual' }

    environment {
        DOCKER_IMAGE = "francesca1812/myimage"
    }

    stages {

        stage('Checkout SCM') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/francescamolella1812/formazione_sou_k8s.git',
                        credentialsId: 'jenkins-ssh-key'
                    ]]
                ])
            }
        }

        stage('Determine Tag') {
            steps {
                script {
                    IMAGE_TAG = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
                    echo "Docker image tag will be: ${IMAGE_TAG}"
                }
            }
        }

        stage('Build Docker image') {
            steps {
                sh """
                docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} .
                docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:latest
                """
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', 
                    usernameVariable: 'DOCKERHUB_USER', 
                    passwordVariable: 'DOCKERHUB_PASS')]) {

                    sh """
                    echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin
                    docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy on manual agent') {
            steps {
                sh """
                docker pull ${DOCKER_IMAGE}:latest
                docker stop flask-app || true
                docker rm flask-app || true
                docker run -d --name flask-app -p 5000:8000 ${DOCKER_IMAGE}:latest
                """
            }
        }

        stage('Deploy to Kubernetes with Helm') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-kind-dev', variable: 'KUBECONFIG_FILE')]) {

                    sh """
                    echo ">>> Using kubeconfig"
                    
                    # Test cluster access
                    kubectl --kubeconfig=$KUBECONFIG_FILE --insecure-skip-tls-verify=true get nodes

                    # Ensure namespace exists
                    kubectl --kubeconfig=$KUBECONFIG_FILE --insecure-skip-tls-verify=true \
                        create namespace formazione-sou --dry-run=client -o yaml | \
                    kubectl --kubeconfig=$KUBECONFIG_FILE --insecure-skip-tls-verify=true apply -f -

                    # Apply manifest (simple deploy)
                    kubectl --kubeconfig=$KUBECONFIG_FILE --insecure-skip-tls-verify=true apply -f kubernetes/deploy.yaml
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "Build or deploy failed. Check logs."
        }
    }
}

