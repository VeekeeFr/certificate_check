node {
	properties([
		[$class: 'GitLabConnectionProperty', gitLabConnection: 'git@github.com:VeekeeFr/certificate_check.git'],
		buildDiscarder(logRotator(artifactDaysToKeepStr: '7', artifactNumToKeepStr: '30', daysToKeepStr: '7', numToKeepStr: '30')),
		pipelineTriggers([cron('H 2 * * *')]),
		disableConcurrentBuilds(),
		parameters([
			string(name: "THRESHOLD", defaultValue: "81", description: "Alert threshold")
		])
	])

	environment {
	}

	timestamps
	{
		def workspace = pwd()

		checkout scm

		def certChecker = load "${workspace}/certcheck.groovy"

		certChecker.processFile("${workspace}/cert_list.csv", THRESHOLD);
	}
}
