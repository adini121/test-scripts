#! /bin/bash

# Description: Test script for jenkins, takes as input : User, Jenkins version, Tomcat Port on which Jenkins will run, Test instance
# Author: Aditya


usage(){
        echo "Usage: $0 <OPTIONS>"
        echo ".........................................."
        echo " WITHOUT EXTRACT AND RECORD"
        echo ".........................................."
        echo "Required options:"
        echo "  -u <UID>                user name (e.g. adi)"
        echo "  -v <JenkinsVersion>     Jenkins version - Git Tag (e.g. 1.600, 1.615)"
        echo "  -s <startupPort>        Tomcat startup port (e.g. 8082)"
        echo " 	-i <TestInstance>		Jenkins Test Repository Instance (e.g. first, second, third)	"
        exit 1
}

downloadJenkinsTestSuite(){
echo "..............................................createJenkinsHome.............................................."

JENKINS_Test_DIR="/home/$user/jenkinsTests"

if [ ! -d $JENKINS_Test_DIR ]; then
	echo 'no jenkins Test directory found.'
    mkdir JENKINS_Test_DIR
	echo 'created Jenkins Test directory'
fi 

if [ ! -d $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance ]; then
    git -C $JENKINS_Test_DIR clone -b 1.596-ath --single-branch git@github.com:adini121/acceptance-test-harness.git Jenkins_1.596_ath_$TestInstance
else
    rm -rf $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance
    git -C $JENKINS_Test_DIR clone -b 1.596-ath --single-branch git@github.com:adini121/acceptance-test-harness.git Jenkins_1.596_ath_$TestInstance
fi

}

gatherTestReports(){

	if [ ! -f /home/nisal/Dropbox/TestResults/Jenkins/1.596_ath_reports_"$JenkinsVersion".log ];then
			touch /home/nisal/Dropbox/TestResults/Jenkins/1.596_ath_reports_"$JenkinsVersion".log
	fi
}

exportEnvironmentVariables(){
export MAVEN_OPTS="-Xmx1024M"
export PATH=$PATH:$JAVA_HOME
}

runJenkinsTests(){
echo "..............................................runJenkinsTests.............................................."
export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
export JAVA_OPTS="-Xms512m -Xmx2048m -server -XX:MaxPermSize=512m"
cd $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance
TYPE=existing BROWSER=seleniumgrid JENKINS_URL=http://134.96.235.47:$startupPort/jenkins$JenkinsVersion/ mvn test 2>&1 | tee /home/nisal/Dropbox/TestResults/Jenkins/1.596_ath_reports_"$JenkinsVersion".log
}


while getopts ":u:v:s:i:" i; do
        case "${i}" in
        u) user=${OPTARG}
        ;;
		v) JenkinsVersion=${OPTARG}
		;;
        s) startupPort=${OPTARG}
		;;
		i) TestInstance=${OPTARG}

        esac
done

shift $((OPTIND - 1))

if [[ $user == "" || $JenkinsVersion == "" || $startupPort == "" || $TestInstance == "" ]]; then
        usage
fi

#..........................................function calls...................................

downloadJenkinsTestSuite

gatherTestReports

exportEnvironmentVariables

runJenkinsTests

