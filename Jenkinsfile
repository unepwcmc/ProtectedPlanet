pipeline {
   agent any
   options {
        // Number of build logs to keep
        // @see https://www.jenkins.io/doc/book/pipeline/syntax/
        buildDiscarder(logRotator(numToKeepStr: '5'))
        //Pipeline speed, much faster, Greatly reduces disk I/O - requires clean shutdown to save running pipelines
        durabilityHint('PERFORMANCE_OPTIMIZED')
        // Disallow concurrent executions of the Pipeline. Can be useful for preventing simultaneous accesses to shared resources
        disableConcurrentBuilds()
   }
   triggers {
        // Accepts a cron-style string to define a regular interval at which Jenkins should check for new source changes 
	// If new changes exist, the Pipeline will be re-triggered
        pollSCM 'H/5 * * * *'
   }
   environment {
        SLACK_TEAM_DOMAIN = "wcmc"
        SLACK_TOKEN = credentials('slack-token-pp')
        SLACK_CHANNEL = "#jenkins-cicd-pp"
        COMPOSE_FILE = "docker-compose.yml"
	GIT_COMMIT_MSG = sh (script: 'git log -1 --pretty=%B ${GIT_COMMIT}', returnStdout: true).trim()
	SNYK_URL = "https://app.snyk.io/org/informatics.wcmc/projects"
        jenkinsConsoleUrl = "$env.JOB_URL" + "$env.BUILD_NUMBER" + "/consoleText"
        DIR = "$JENKINS_HOME/workspace"
   }
   stages {
        stage ('Start') {
            steps {
                slackSend(
                    teamDomain: "${env.SLACK_TEAM_DOMAIN}",
                    token: "${env.SLACK_TOKEN}",
                    channel: "${env.SLACK_CHANNEL}",
                    color: "#FFFF00",
                    message: "*>_BUILD STARTED_* Source/Change Branch to be merged: `${env.CHANGE_BRANCH}`\n Git Commit message: `'${env.GIT_COMMIT_MSG}'` *_>NEW PULL REQUEST_* PR Title: `${env.CHANGE_TITLE}`\n PR-ID: `${env.JOB_BASE_NAME}`\n Author: `'${env.CHANGE_AUTHOR}'`\n Target Branch: _`[${env.CHANGE_TARGET}]`_\n Job: `${env.JOB_NAME} - [${env.BUILD_NUMBER}]` \n Build link: [(<${env.BUILD_URL} | View >)]"
                )
	    }
       	}
	stage("Build") {
            steps { 
	        script {
	            CI_ERROR = "Build Failed at stage: docker-compose build"
                    buildProject()
	        }
	    }
        }
        stage("Prepare") {
            steps {
                script {
                    CI_ERROR = "Build Failed at stage: Prepare - Run docker-compose yarn install"
                    prepare()
                }
            }
        }
        stage("Test DB") {
            steps { 
		script {
		    CI_ERROR = "Build Failed at stage: Test DB - Running docker-compose db create and migrate"
                    prepareDatabase() 
		}
	    }
        }
        stage("Test") {
            steps {
                script {
                    CI_ERROR = "Build Failed at stage: Rake test - Run docker-compose run RAILS_ENV=test web rake test"
                   echo "rakeTest()"
                }
            }
        }
        stage('Scan for vulnerabilities') {
            when{
                expression {
                    return env.CHANGE_BRANCH ==~ /(develop|master|((build|ci|feat|fix|perf|test|refresh)\/.*))/
                }
            }
	    steps {
		script {
	            CI_ERROR = "Build Failed at stage:: Snyk vulnerability scan failed for this project, check the snyk site for details, ${env.SNYK_URL}"
		}
                echo 'Scanning...'
                snykSecurity(
        		snykInstallation: 'snyk@latest', snykTokenId: 'wcmc-snyk',
		    	severity: 'critical', failOnIssues: true,
		    	additionalArguments: '--all-projects --detection-depth=4', 
			)
	    }
	    post {
                success{
                    slackSend color: "good", message: "Snyk scan successful, visit ${env.SNYK_URL} for detailed report", teamDomain: "${env.SLACK_TEAM_DOMAIN}", token: "${env.SLACK_TOKEN}", channel: "${env.SLACK_CHANNEL}"
                }
                failure{
                    slackSend color: "danger", message: "Snyk scan failed, visit ${env.SNYK_URL} to get detailed report", teamDomain: "${env.SLACK_TEAM_DOMAIN}", token: "${env.SLACK_TOKEN}", channel: "${env.SLACK_CHANNEL}"
                }
            }
    	}
    }
    post {
        always {
	     script {
               	BUILD_STATUS = currentBuild.currentResult
		if (currentBuild.currentResult == 'SUCCESS') { 
			CI_ERROR = "NA" 
		}
		dockerImageCleanup()
                }
        }
	 success {
            slackSend(
                teamDomain: "${env.SLACK_TEAM_DOMAIN}",
                token: "${env.SLACK_TOKEN}",
                channel: "${env.SLACK_CHANNEL}",
                color: "good",
                message: "*Job*:  ${env.JOB_NAME} of Build `${env.BUILD_NUMBER}` Completed\n Status: *SUCCESS* \n Result: Pipeline has finished build successfully for *${currentBuild.fullDisplayName}* :white_check_mark:\n Run Duration: [${currentBuild.durationString}]\n View Build: [(<${JOB_DISPLAY_URL} | View >)]\n Logs path and Details: [(<${jenkinsConsoleUrl} | here >)] \n"
            )
        }
        failure {
            slackSend(
                teamDomain: "${env.SLACK_TEAM_DOMAIN}",
                token: "${env.SLACK_TOKEN}",
                channel: "${env.SLACK_CHANNEL}",
                color: "danger",
                message: "*Job*:  ${env.JOB_NAME}\n Status: *FAILURE* \n Result: Pipeline has failed for *${currentBuild.fullDisplayName}*❗\n Error description: ${CI_ERROR}\n Run Duration: [${currentBuild.durationString}]\n View Build: [(<${JOB_DISPLAY_URL} | View >)]\n Logs path and Details: [(<${jenkinsConsoleUrl} | here >)] \n"
            )
        }
        cleanup {
	    cleanWs()
	    deleteWorkspace()
	}
    }
}


def buildProject() {
    sh 'echo "Building Project.............."'
    sh "cp .env-jenkins-docker .env"
    sh "docker-compose -f ${COMPOSE_FILE} --project-name=${JOB_NAME} build web db redis sidekiq elasticsearch kibana webpacker"
}

def prepare() {
    sh "docker-compose --project-name=${JOB_NAME} run web yarn install"
}

def prepareDatabase() {
    COMMAND = "rake db:create db:migrate db:seed"
    sh "docker-compose --project-name=${JOB_NAME} run -e RAILS_ENV=test web ${COMMAND}"
}

def rakeTest() {
    COMMAND = "rake test"
    sh "docker-compose --project-name=${JOB_NAME} run -e RAILS_ENV=test web ${COMMAND}"
}

def deploy() {
    sh '''#!/bin/bash -l
        eval $(ssh-agent)
        ssh-add /tmp/id_deploy
        git checkout develop
        rvm use $(cat .ruby-version) --install
        bundle install
        bundle exec cap staging deploy
    '''
}

def dockerImageCleanup() {
    sh "docker-compose --project-name=${JOB_NAME} stop &> /dev/null || true &> /dev/null"
    sh "docker-compose --project-name=${JOB_NAME} rm --force &> /dev/null || true &> /dev/null"
    sh "docker stop `docker ps -a -q -f status=exited` &> /dev/null || true &> /dev/null"
    sh "docker-compose --project-name=${JOB_NAME} down --volumes &> /dev/null || true &> /dev/null"
    sh '''#!/bin/bash
	docker ps -a --no-trunc  | grep "pp" | awk '{print $1}' | xargs -r --no-run-if-empty docker stop
	docker ps -a --no-trunc  | grep "pp" | awk '{print $1}' | xargs -r --no-run-if-empty docker rm -f
	docker images --no-trunc | grep "pp" | awk '{print $3}' | xargs -r --no-run-if-empty docker rmi -f
        docker images --no-trunc | grep "<none>" | awk '{print $3}' | xargs -r --no-run-if-empty docker rmi -f
    '''    
}

def deleteDeployDir() {
    sh "sudo rm -r $DIR/deploypp*"
}

def deleteWorkspace() {
    sh "sudo rm -rf ${workspace}_ws-*"
}
