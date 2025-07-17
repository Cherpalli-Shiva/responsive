pipeline {
    agent any

    environment {
        IMAGE_NAME = 'my-docker-image'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        NEXUS_REPO = 'https://nexus.example.com/repository/docker-hosted'
        NEXUS_CREDENTIALS = credentials('nexus-credentials')
        SONARQUBE_ENV = 'sonarqube'
    }

    tools {
        gradle 'gradle'
        jdk 'jdk17'
    }
    
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }
        stage('SonarQube Scan') {
            steps {
                script {
                    withSonarQubeEnv(SONARQUBE_ENV) {
                        sh './gradlew sonarqube -Dsonar.projectKey=gradle-app'
                    }
                }
            }
        }
        stage('OWASP Dependency Check') {
            steps {
                sh '''
                    ./gradlew dependencyCheckAnalyze \
                    -PdependencyCheckFormat=XML \
                    -PdependencyCheckOutputDirectory=build/reports/dependency-check
                '''
            }
        }
        stage('Gradle clean') {
            steps {
                sh './gradlew clean'
            }
        
        stage('Gradle Test') {
            steps {
                sh './gradlew test'
            }
        }
        stage('Gradle Build') {
            steps {
                sh './gradlew clean build'
            }
        }
        stage('Upload to Nexus') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS, usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh '''
                            ./gradlew publish \
                            -PnexusUsername=$NEXUS_USER \
                            -PnexusPassword=$NEXUS_PASS \
                            -PnexusUrl=$NEXUS_REPO
                        '''
                    }
                }
            }
        }
        stage('Docker Build') {
            steps {
                sh 'docker build -t $IMAGE_NAME .'
            }
        }
        stage('Trivy Scan') {
            steps {
                sh 'trivy image --exit-code 1 --severity HIGH,CRITICAL $IMAGE_NAME || true'
            }
        }   
        stage('Docker Push to DockerHub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                            docker push $IMAGE_NAME
                        '''
                    }
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh '''
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                    '''
                }
            }
        }
        stage('Sync with ArgoCD') {
            steps {
                script {
                    sh '''
                        argocd app sync my-app
                        argocd app wait my-app --health
                    '''
                }
            }
        }
    }
    post {
        always {
            junit '**/build/test-results/test/*.xml'
            archiveArtifacts artifacts: '**/build/libs/*.jar', fingerprint: true
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