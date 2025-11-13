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
                    echo '>>> Using kubeconfig at $KUBECONFIG_FILE'
                    export KUBECONFIG="$KUBECONFIG_FILE"
		    /usr/local/bin/kubectl create namespace formazione-sou --dry-run=client -o yaml | /usr/local/bin/kubectl apply --validate=false --insecure-skip-tls-verify -f -
		    helm upgrade --install flask-app charts/flask-example \
                      --namespace formazione-sou \
  		      --set image.repository=${DOCKER_IMAGE} \
  		      --set image.tag=${IMAGE_TAG} \
		      --kube-insecure-skip-tls-verify

                    """
                }
            }
        }

        stage('check deployment') {
            steps {
                sh """
                bash ./charts/flask-example/serviceaccount.sh
                """            
            }
        }
    }

    post {
        failure {
            echo "Build or deploy failed. Check logs."
        }
    }
}

