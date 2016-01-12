#! /bin/bash

# Description: Test script for jenkins, takes as input : Jenkins version, Tomcat Port on which Jenkins will run, Test instance directory
# Author: Aditya

usage(){
echo "Usage: $0 <OPTIONS>"
echo "Required options:"
echo "  -v <JenkinsVersion>     Jenkins version - Git Tag (e.g. 1.600, 1.615)"
echo "  -s <startupPort>        Tomcat startup port (e.g. 8082)"
echo " 	-i <TestInstance>       Jenkins Test Repository Instance (e.g. first, second, third)	"
echo "  -c <CommitHash>         Jenkins tests CommitHash"
# echo "  -d <JenkinsVersion>     Database SessionIDs Version (e.g. 1_600, 1_615)"
exit 1
}

downloadJenkinsTestSuite(){
echo "..............................................createJenkinsHome.............................................."

JENKINS_Test_DIR="/home/nisal/jenkinsTests"

if [ ! -d $JENKINS_Test_DIR ]; then
	echo 'no jenkins Test directory found.'
    mkdir $JENKINS_Test_DIR
	echo 'created Jenkins Test directory'
fi 

if [ ! -d $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance ]; then
    git -C $JENKINS_Test_DIR clone git@github.com:adini121/acceptance-test-harness.git Jenkins_1.596_ath_$TestInstance
else
    rm -rf $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance
    git -C $JENKINS_Test_DIR clone git@github.com:adini121/acceptance-test-harness.git Jenkins_1.596_ath_$TestInstance
fi

git -C $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance checkout $CommitHash
git -C $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance checkout -b cherry-branch
git -C $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance cherry-pick 3b0ccb5f774fc985237bdc6c775e7f1d80134f3a
}

gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
REPORTS_DIR="/home/nisal/Dropbox/TestResults/Jenkins/Jenkins_Temp"
if [ ! -f $REPORTS_DIR/plugins_1.596_ath_reports_"$CommitHash"_"$JenkinsVersion".log ];then
        touch $REPORTS_DIR/plugins_1.596_ath_reports_"$CommitHash"_"$JenkinsVersion".log
fi
# if [ ! -f $REPORTS_DIR/"$currentTime"_BrowserIdList_"$JenkinsVersion".log ];then
# 		touch $REPORTS_DIR/"$currentTime"_BrowserIdList_"$JenkinsVersion".log
# fi
# mysql -u root << EOF
# use jenkins_plugins_sessionIDs;
# DROP TABLE IF EXISTS sessionids_$DatabaseSessionIDsVersion;
# EOF
TestsDir=$JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance/src/main/java/org/jenkinsci/test/acceptance
sed -i 's|\"record\", true|\"record\", false|g' $TestsDir/FallbackConfig.java
sed -i 's|\"extract\", true|\"extract\", false|g' $TestsDir/FallbackConfig.java
#sed -i 's|test_session_ids|sessionids_'$DatabaseSessionIDsVersion'|g' $TestsDir/utils/SeleniumGridConnection.java
#sed -i 's|.*FileWriter fileWriter.*|            FileWriter fileWriter = new FileWriter("'$REPORTS_DIR'/'$currentTime'_BrowserIdList_'$JenkinsVersion'.log", true);|g' $TestsDir/utils/SeleniumGridConnection.java
}


runJenkinsTests(){
echo "..............................................runJenkinsTests.............................................."
cd $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance
TYPE=existing BROWSER=seleniumGrid JENKINS_URL=http://134.96.235.47:$startupPort/jenkins$JenkinsVersion/ mvn -Dtest=**/plugins/*Test \
test 2>&1 | tee $REPORTS_DIR/plugins_1.596_ath_reports_"$CommitHash"_"$JenkinsVersion".log
}

# cleanup(){
# echo "_________Cleaning all processes and directories left behind by this jenkins instance____________"
# sleep 5
# kill $(ps aux | grep -E 'nisal.*java -jar /tmp*' | awk '{print $2}')
# kill $(ps aux | grep -E 'nisal.*slave*' | awk '{print $2}')
# kill $(ps aux | grep -E '/usr/lib/jvm/java.*TomcatInstance'$startupPort'*' | awk '{print $2}')
# echo "Deleting Jenkins TMP directory"
# cd /tmp/
# rm -rf tmp*
# rm -rf $(ls -la | grep -E 'nisal.*slave*' | awk '{print $9}')
# rm -rf $(ls -la | grep -E '*nisal*.*._.*' | awk '{print $9}')
# echo "done"
# }

while getopts ":v:s:i:c:" i; do
        case "${i}" in
        v) JenkinsVersion=${OPTARG}
        ;;
        s) startupPort=${OPTARG}
        ;;
        i) TestInstance=${OPTARG}
        ;;
        c) CommitHash=${OPTARG}
        # ;;
        # d) DatabaseSessionIDsVersion=${OPTARG}
        esac
done

shift $((OPTIND - 1))

if [[ $JenkinsVersion == "" || $startupPort == "" || $TestInstance == "" || $CommitHash == "" ]]; then
        usage
fi

#..........................................function calls...................................

downloadJenkinsTestSuite

gatherTestReports

runJenkinsTests

# cleanup
