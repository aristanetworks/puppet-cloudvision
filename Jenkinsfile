#!/usr/bin/env groovy

/**
 * Jenkinsfile for cvprac rubygem
 */

node('puppet') {

    currentBuild.result = "SUCCESS"

    try {

        stage ('Checkout') {

            checkout scm
            sh """
                #!/bin/bash -l
                [[ -s /usr/local/rvm/scripts/rvm ]] && source /usr/local/rvm/scripts/rvm
                /usr/local/rvm/bin/rvm list
                rvm use 2.3.3@cvprac-rb --create
                gem install bundler --no-ri --no-rdoc
                which ruby
                ruby --version
                export GEM_CVPRAC_VERSION='https://github.com/aristanetworks/cvprac-rb.git#feature-api'
                bundle install --path=.bundle/gems
            """
        }

        stage ('Check_style') {

            try {
                sh """
                    #!/bin/bash -l
                    source /usr/local/rvm/scripts/rvm
                    rvm use 2.3.3@cvprac-rb
                    export GEM_CVPRAC_VERSION='https://github.com/aristanetworks/cvprac-rb.git#feature-api'
                    bundle exec rake rubocop || true
                    # validate includes syntax...
                    bundle exec rake validate || true
                    # release-checks includes lint
                    bundle exec rake release_checks || true
                    bundle exec rake metadata_lint || true
                    bundle exec rake build || true
                """
            }
            catch (Exception err) {
                currentBuild.result = "UNSTABLE"
            }
            echo "RESULT: ${currentBuild.result}"
        }

        stage ('RSpec Unittests') {

            sh """
                #!/bin/bash -l
                source /usr/local/rvm/scripts/rvm
                rvm use 2.3.3@cvprac-rb
                export GEM_CVPRAC_VERSION='https://github.com/aristanetworks/cvprac-rb.git#feature-api'
                bundle exec rake ci_spec || true
            """

            step([$class: 'JUnitResultArchiver', testResults: 'results/*.xml'])

        }

        stage ('Puppet docs') {

            // wrap([$class: 'AnsiColorSimpleBuildWrapper', colorMapName: "xterm"]) {
                sh """
                    #!/bin/bash -l
                    source /usr/local/rvm/scripts/rvm
                    rvm use 2.3.3@cvprac-rb
                    export GEM_CVPRAC_VERSION='https://github.com/aristanetworks/cvprac-rb.git#feature-api'
                    bundle exec rake strings:generate || true
                """
            // }
        }

        stage ('Cleanup') {

            echo 'Cleanup'

            step([$class: 'WarningsPublisher', 
                  canComputeNew: false,
                  canResolveRelativePaths: false,
                  consoleParsers: [
                                   [parserName: 'Rubocop'],
                                   [parserName: 'Rspec']
                                  ],
                  defaultEncoding: '',
                  excludePattern: '',
                  healthy: '',
                  includePattern: '',
                  unHealthy: ''
            ])

            // publish html
            // snippet generator doesn't include "target:"
            // https://issues.jenkins-ci.org/browse/JENKINS-29711.
            publishHTML (target: [
                allowMissing: false,
                alwaysLinkToLastBuild: false,
                keepAll: true,
                reportDir: 'coverage',
                reportFiles: 'index.html',
                reportName: "RCov Report"
              ])
            publishHTML (target: [
                allowMissing: false,
                alwaysLinkToLastBuild: false,
                keepAll: true,
                reportDir: 'doc',
                reportFiles: 'index.html',
                reportName: "Puppet Module Docs"
              ])

           mail body: "${env.BUILD_URL} build successful.\n" +
                      "Started by ${env.BUILD_CAUSE}",
                from: 'eosplus-dev+jenkins@arista',
                replyTo: 'eosplus-dev@arista',
                subject: "cvprac-rb ${env.JOB_NAME} (${env.BUILD_NUMBER}) build successful",
                to: 'jere@arista.com'

        }

    }

    catch (err) {

        currentBuild.result = "FAILURE"

            mail body: "${env.JOB_NAME} (${env.BUILD_NUMBER}) cookbook build error " +
                       "is here: ${env.BUILD_URL}\nStarted by ${env.BUILD_CAUSE}" ,
                 from: 'eosplus-dev+jenkins@arista.com',
                 replyTo: 'eosplus-dev+jenkins@arista.com',
                 subject: "cvprac-rb ${env.JOB_NAME} (${env.BUILD_NUMBER}) build failed",
                 to: 'jere@arista.com'

            throw err
    }

}
