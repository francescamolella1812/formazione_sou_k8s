pipeline {

    // L'agent su cui eseguire la pipeline.
    // 'manual agent' è il nodo remoto dove abbiamo Docker.
    agent { label 'manual agent' }

    environment {
        // Recupera le credenziali DockerHub salvate in Jenkins (ID = dockerhub-credentials).
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')

        // Nome base dell'immagine che costruiremo e pubblicheremo.
        IMAGE_NAME = "francesca1812/myimage"
    }

    stages {

        stage('Checkout') {
            steps {
                // Clona il repository da GitHub usando credenziali private.
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']], // Traccia il branch main
                    userRemoteConfigs: [[
                        url: 'https://github.com/francescamolella1812/formazione_sou_k8s',
                        credentialsId: 'github-credentials' // GitHub token salvato in Jenkins
                    ]]
                ])
            }
        }

        stage('Determine Tag') {
            steps {
                script {
                    // Nome del branch corrente
                    def branch = env.GIT_BRANCH ?: sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()

                    // Verifica se il commit è esattamente su un tag git
                    def tag = sh(script: "git describe --tags --exact-match 2>/dev/null || true", returnStdout: true).trim()

                    // Recupera lo SHORT commit SHA (es. "a3f92d1")
                    def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()

                    // Logica di tagging: come nominiamo l'immagine?
                    if (tag) {
                        // Se è stato eseguito un build su un tag Git → usa quel tag
                        env.IMAGE_TAG = tag
                    } else if (branch == "main" || branch == "master") {
                        // Se si è in main → si usa latest
                        env.IMAGE_TAG = "latest"
                    } else if (branch == "develop") {
                        // Se si è nel branch develop → use "develop-SHA"
                        env.IMAGE_TAG = "develop-${commit}"
                    } else {
                        // Qualsiasi altro branch → "nomebranch-SHA"
                        env.IMAGE_TAG = "${branch}-${commit}"
                    }

                    echo "Docker image tag will be: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Build Docker image') {
            steps {
                // Costruisce l'immagine Docker usando il Dockerfile presente nella repo
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Push to DockerHub') {
            steps {
                sh """
                  // Login a DockerHub usando le credenziali
                  echo "${DOCKERHUB_CREDENTIALS_PSW}" | docker login -u "${DOCKERHUB_CREDENTIALS_USR}" --password-stdin

                  // Push dell'immagine appena buildata
                  docker push ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy on manual agent') {
            steps {
                sh """
                  // Assicura di avere l'ultima versione dell'immagine dal registry
                  docker pull ${IMAGE_NAME}:${IMAGE_TAG}

                  // Ferma il container se già esiste
                  docker stop flask-app || true

                  // Rimuove il container se esiste
                  docker rm flask-app || true

                  // Avvia il nuovo container esponendo la porta 5000 dell'host verso la 8000 del container
                  docker run -d --name flask-app -p 5000:8000 ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        success {
            echo "Application successfully deployed! Visit: http://192.168.50.111:5000"
        }
        failure {
            echo "Build or deploy failed. Check logs."
        }
    }
}

