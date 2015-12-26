#! /bin/bash

# Description: Test script for jenkins, takes as input : User, Jenkins version, Tomcat Port on which Jenkins will run, Test instance
# Author: Aditya


usage(){
        echo "Usage: $0 <OPTIONS>"
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

if [ ! -d $JENKINS_Test_DIR/Jenkins_1.580_ath_$TestInstance ]; then
    git -C $JENKINS_Test_DIR clone -b 1.580-ath --single-branch git@github.com:adini121/acceptance-test-harness.git Jenkins_1.580_ath_$TestInstance
else
    rm -rf $JENKINS_Test_DIR/Jenkins_1.580_ath_$TestInstance
    git -C $JENKINS_Test_DIR clone -b 1.580-ath --single-branch git@github.com:adini121/acceptance-test-harness.git Jenkins_1.580_ath_$TestInstance
fi

}

gatherTestReports(){

	if [ ! -f /home/nisal/Dropbox/TestResults/Jenkins/core_1.580_ath_reports_"$JenkinsVersion".log ];then
			touch /home/nisal/Dropbox/TestResults/Jenkins/core_1.580_ath_reports_"$JenkinsVersion".log
	fi
	#if [ ! -f /home/nisal/Dropbox/TestResults/Jenkins/plugins_1.580_ath_reports_"$JenkinsVersion".log ];then
	#		touch /home/nisal/Dropbox/TestResults/Jenkins/plugins_1.580_ath_reports_"$JenkinsVersion".log
#	fi
}


runJenkinsTests(){
echo "..............................................runJenkinsTests.............................................."
export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
cd $JENKINS_Test_DIR/Jenkins_1.580_ath_$TestInstance
TYPE=existing BROWSER=seleniumGrid JENKINS_URL=http://134.96.235.47:$startupPort/jenkins$JenkinsVersion/ mvn -Dtest=**/core/*Test test 2>&1 | tee /home/nisal/Dropbox/TestResults/Jenkins/core_1.580_ath_reports_"$JenkinsVersion".log
#TYPE=existing BROWSER=seleniumGrid JENKINS_URL=http://134.96.235.47:$startupPort/jenkins$JenkinsVersion/ mvn -Dtest=**/plugins/*Test test 2>&1 | tee /home/nisal/Dropbox/TestResults/Jenkins/plugins_1.580_ath_reports_"$JenkinsVersion".log
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

runJenkinsTests

