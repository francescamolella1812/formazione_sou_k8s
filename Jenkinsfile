pipeline {

    // Nodo su cui gira la pipeline (la VM)
    agent { label 'manual agent' }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        IMAGE_NAME = "francesca1812/myimage"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/francescamolella1812/formazione_sou_k8s',
                        credentialsId: 'github-credentials'
                    ]]
                ])
            }
        }

        stage('Determine Tag') {
            steps {
                script {
                    def rawBranch = env.GIT_BRANCH ?: sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    def branch = rawBranch.replaceFirst(/^origin\//, "")
                    def tag = sh(script: "git describe --tags --exact-match 2>/dev/null || true", returnStdout: true).trim()
                    def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()

                    if (tag) {
                        env.IMAGE_TAG = tag
                    } else if (branch == "main" || branch == "master") {
                        env.IMAGE_TAG = "latest"
                    } else if (branch == "develop") {
                        env.IMAGE_TAG = "develop-${commit}"
                    } else {
                        env.IMAGE_TAG = "${branch}-${commit}"
                    }

                    echo "Docker image tag will be: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Build Docker image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Push to DockerHub') {
            steps {
                sh """
                  echo "${DOCKERHUB_CREDENTIALS_PSW}" | docker login -u "${DOCKERHUB_CREDENTIALS_USR}" --password-stdin
                  docker push ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy on manual agent') {
            steps {
                sh """
                  docker pull ${IMAGE_NAME}:${IMAGE_TAG}
                  docker stop flask-app || true
                  docker rm flask-app || true
                  docker run -d --name flask-app -p 5000:8000 ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy to Kubernetes with Helm') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-kind-dev', variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        echo ">>> Using kubeconfig from Jenkins credentials"
                        export KUBECONFIG=$KUBECONFIG_FILE

                        kubectl create namespace formazione-sou --dry-run=client -o yaml | kubectl apply -f -

                        helm upgrade --install flask-release charts/flask-example \
                            -n formazione-sou \
                            --set image.repository=docker.io/${IMAGE_NAME} \
                            --set image.tag=${IMAGE_TAG}

                        echo "Deploy completed on Kubernetes namespace formazione-sou"
                    """
                }
            }
        }

    } // fine stages

    post {
        success {
            echo "Application successfully deployed!"
        }
        failure {
            echo "Build or deploy failed. Check logs."
        }
    }

} // fine pipeline

