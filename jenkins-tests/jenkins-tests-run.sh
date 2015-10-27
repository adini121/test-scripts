#! /bin/bash

# Description: Test script for jenkins, takes as input : User, Jenkins version, Tomcat Port on which Jenkins will run, Test instance
# Author: Aditya


usage(){
        echo "Usage: $0 <OPTIONS>"
        echo "Required options:"
        echo "  -u <UID>                user name (e.g. adi)"
        echo "  -v <JenkinsVersion>     Jenkins version - Git Tag (e.g. 1.600, 1.615)"
        echo "  -s <startupPort>        Tomcat startup port (e.g. 8082)"
        echo " 	-i <Test_Instance>		Jenkins Test Repository Instance (e.g. first, second, third)	"
        echo "  -g <Grid_Address>       Selenium GRID URL Address e.g. 192.168.2.3, infinity.st.cs.uni-saarland.de"
        echo "  -g <Grid_Port>          Selenium GRID port e.g. 4444, 6666"
        echo "  -b <Browser_Name>       Browser_Name e.g. firefox"
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

if [ ! -d $JENKINS_Test_DIR/Jenkins_$Test_Instance ]; then
    git -C $JENKINS_Test_DIR clone --recursive https://github.com/adini121/JenkinsTestHarnessMirror.git Jenkins_$Test_Instance
fi

git -C $JENKINS_Test_DIR/Jenkins_$Test_Instance pull

}

configureTestProperties(){
sed -i 's|.*gridHubURL=.*|gridHubURL=http://'$Grid_Address':'$Grid_Port'/wd/hub|g' $JENKINS_Test_DIR/Jenkins_$Test_Instance/src/main/resources/infinity.properties
sed -i 's|.*browserval=.*|browserval='$Browser_Name'|g' $JENKINS_Test_DIR/Jenkins_$Test_Instance/src/main/resources/infinity.properties

}

gatherTestReports(){
mkdir -p $JENKINS_Test_DIR/Jenkins-test-reports
	if [ ! -f $JENKINS_Test_DIR/Jenkins-test-reports/test_reports_"$JenkinsVersion".log ] || [ ! -f $JENKINS_Test_DIR/Jenkins-test-reports/test_log_from_SeNode_"$JenkinsVersion".log ] || [ ! -f $JENKINS_Test_DIR/Jenkins-test-reports/selenium-hub-Jenkins-output.log ];
		then
			touch $JENKINS_Test_DIR/Jenkins-test-reports/test_reports_"$JenkinsVersion".log
			touch $JENKINS_Test_DIR/Jenkins-test-reports/test_log_from_SeNode_"$JenkinsVersion".log
			touch $JENKINS_Test_DIR/Jenkins-test-reports/selenium-hub-Jenkins-output.log
	fi
}

# startJenkins_SeleniumHub(){
# echo "starting tmux session selenium-hub-Jenkins "
# tmux kill-session -t selenium-hub-Jenkins
# tmux new -d -A -s selenium-hub-Jenkins '
# export DISPLAY=:0.0
# sleep 3
# /usr/bin/java -jar /home/'$USER'/selenium-server-standalone-2.47.1.jar -role hub -hub http://localhost:4444/grid/register 2>&1 | tee '$JENKINS_Test_DIR'/Jenkins-test-reports/selenium-hub-Jenkins-output.log
# sleep 2
# tmux detach'
# # sleep 5
# # echo "exiting tmux session selenium_hub"
# }

# startJenkins_SeleniumNode(){
# 	echo "starting tmux session selenium-node-Jenkins"
# 	tmux kill-session -t selenium-node-Jenkins
# 	tmux new -d -A -s selenium-node-Jenkins '
# 	export DISPLAY=:0.0
# 	sleep 3
# 	/usr/bin/java -jar /home/'$USER'/selenium-server-standalone-2.47.1.jar -role node -hub http://localhost:4444/grid/register -browser browserName=firefox -platform platform=LINUX 2>&1 | tee '$JENKINS_Test_DIR'/Jenkins-test-reports/test_log_from_SeNode_'$JenkinsVersion'.log
# 	sleep 2
# 	tmux detach'
# 	# sleep 5
# 	# echo "exiting tmux session selenium-node-Jenkins"
# }

exportEnvironmentVariables(){
export MAVEN_OPTS="-Xmx1024M"
export PATH=$PATH:$JAVA_HOME
}

runJenkinsTests(){
echo "..............................................runJenkinsTests.............................................."
cd $JENKINS_Test_DIR/Jenkins_$Test_Instance
TYPE=existing BROWSER=infinity JENKINS_URL=http://localhost:$startupPort/jenkins$JenkinsVersion/ mvn -e -DTest=CopyJobTest test 2>&1 | tee $JENKINS_Test_DIR/Jenkins-test-reports/test_reports_"$JenkinsVersion".log
}


while getopts ":u:v:s:i:g:" i; do
        case "${i}" in
        u) user=${OPTARG}
        ;;
		v) JenkinsVersion=${OPTARG}
		;;
        s) startupPort=${OPTARG}
		;;
		i) Test_Instance=${OPTARG}
        ;;
        g) Grid_Address=${OPTARG}
        ;;
        p) Grid_Port=${OPTARG}
        ;;
        b) Browser_Name=${OPTARG}
        esac
done

shift $((OPTIND - 1))

if [[ $user == "" || $JenkinsVersion == "" || $startupPort == "" || $Test_Instance == "" || $Grid_Address == "" || $Grid_Port == "" || $Browser_Name == "" ]]; then
        usage
fi

#..........................................function calls...................................

downloadJenkinsTestSuite

configureTestProperties

gatherTestReports

# startJenkins_SeleniumHub

# startJenkins_SeleniumNode

exportEnvironmentVariables

runJenkinsTests

