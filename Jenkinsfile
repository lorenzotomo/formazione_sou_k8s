pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'lorenzotomo'             
        IMAGE_NAME = 'flask-hello-world'  
        REGISTRY = 'docker.io'                      
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Clonazione repository..."
                checkout scm
            }
        }

        stage('Determine Docker Tag') {
            steps {
                script {
                    def gitBranch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    def gitTag = sh(script: "git describe --tags --exact-match || true", returnStdout: true).trim()
                    def gitCommit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()

                    if (gitBranch == "HEAD") {
                        echo "Jenkins in detached HEAD, recupero branch da GIT_BRANCH env..."
                        gitBranch = env.GIT_BRANCH?.replaceFirst(/^origin\//, '') ?: "unknown"
                    }

                    def imageTag = ""

                    if (gitTag) {
                        imageTag = gitTag
                    } else if (gitBranch == 'master' || gitBranch == 'main') {
                        imageTag = 'latest'
                    } else if (gitBranch == 'develop') {
                        imageTag = "develop-${gitCommit}"
                    } else {
                        imageTag = "${gitBranch}-${gitCommit}"
                    }

                    env.IMAGE_TAG = imageTag
                    echo "Docker tag scelto: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Check Docker Installation') {
            steps {
                echo "Verifica disponibilità Docker..."
                sh 'docker --version'
                sh 'docker info || true'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Build dell'immagine Docker..."
                sh "docker build -t ${REGISTRY}/${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Login to Docker Hub') {
            steps {
                echo "Login a Docker Hub..."
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin ${REGISTRY}"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "Push dell'immagine su Docker Hub..."
                sh "docker push ${REGISTRY}/${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            echo "Pulizia finale..."
            sh "docker logout ${REGISTRY} || true"
        }
    }
}

