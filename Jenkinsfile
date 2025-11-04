pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'lorenzotomo'    
        IMAGE_NAME = 'flask-app-example'           
        REGISTRY = 'docker.io'                     
        IMAGE_TAG = ''                        
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Determine Docker Tag') {
            steps {
                script {
                    def gitBranch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    def gitTag = sh(script: "git describe --tags --exact-match || true", returnStdout: true).trim()
                    def gitCommit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()

                    if (gitTag) {
                        env.IMAGE_TAG = gitTag
                    } else if (gitBranch == 'master') {
                        env.IMAGE_TAG = 'latest'
                    } else if (gitBranch == 'develop') {
                        env.IMAGE_TAG = "develop-${gitCommit}"
                    } else {
                        env.IMAGE_TAG = "${gitBranch}-${gitCommit}"
                    }

                    echo "Docker tag scelto: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${REGISTRY}/${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin ${REGISTRY}"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh "docker push ${REGISTRY}/${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            sh "docker logout ${REGISTRY} || true"
        }
    }
}

