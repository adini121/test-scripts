#! /bin/bash

# Description: Test script for jenkins, takes as input : User, Jenkins version, Tomcat Port on which Jenkins will run, Test instance
# Author: Aditya

# Checklist:
# Jenkins commitHash,getopts,case,call to usage function,usage function options,
usage(){
echo "Usage: $0 <OPTIONS>"
echo "Required options:"
echo "  -u <UID>                user name (e.g. adi)"
echo "  -v <JenkinsVersion>     Jenkins version - Git Tag (e.g. 1.600, 1.615)"
echo "  -s <startupPort>        Tomcat startup port (e.g. 8082)"
echo " 	-i <TestInstance>		Jenkins Test Repository Instance (e.g. first, second, third)	"
echo "  -c <CommitHash>         Jenkins tests CommitHash"
echo "  -d <JenkinsVersion>     Database SessionIDs Version (e.g. 1_600, 1_615)"
exit 1
}

downloadJenkinsTestSuite(){
echo "..............................................createJenkinsHome.............................................."

JENKINS_Test_DIR="/home/$user/jenkinsTests"

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
git -C $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance checkout -b infinity-cherry-pick-branch
git -C $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance cherry-pick 7348ab40ffb159c83982b18380c3d516cc99a507
git -C $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance cherry-pick 89a59d4bd2a22575690bde8f1f2d4e5cb6d9056d
}

gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
REPORTS_DIR="/home/nisal/Dropbox/TestResults/Jenkins/Plugins"
if [ ! -f $REPORTS_DIR/plugins_1.596_ath_reports_"$JenkinsVersion".log ];then
    	touch $REPORTS_DIR/plugins_1.596_ath_reports_"$JenkinsVersion".log
fi
if [ ! -f $REPORTS_DIR/plugins_1.596_ath_BrowserIdList_"$JenkinsVersion".log ];then
		touch $REPORTS_DIR/plugins_1.596_ath_BrowserIdList_"$JenkinsVersion".log
fi
mysql -u root << EOF
use jenkins_plugins_sessionIDs;
DROP TABLE IF EXISTS sessionids_$DatabaseSessionIDsVersion;
EOF
TestsDir="$JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance/src/main/java/org/jenkinsci/test/acceptance"
sed -i 's|jenkins_core_sessionIDs|jenkins_plugins_sessionIDs|g' $TestsDir/utils/SeleniumGridConnection.java
sed -i 's|\"record\", false|\"record\", true|g' $TestsDir/FallbackConfig.java
sed -i 's|\"extract\", false|\"extract\", true|g' $TestsDir/FallbackConfig.java
sed -i 's|FIREFOX_30_WINDOWS_8_64|PHANTOMJS_198_MACOS_10.11_64|g' $TestsDir/FallbackConfig.java
sed -i 's|test_session_ids|sessionids_'$DatabaseSessionIDsVersion'|g' $TestsDir/utils/SeleniumGridConnection.java
sed -i 's|.*FileWriter fileWriter.*|            FileWriter fileWriter = new FileWriter("'$REPORTS_DIR'/plugins_1.596_ath_BrowserIdList_'$JenkinsVersion'.log", true);|g' $TestsDir/utils/SeleniumGridConnection.java
}

runJenkinsTests(){
echo "..............................................runJenkinsTests.............................................."
cd $JENKINS_Test_DIR/Jenkins_1.596_ath_$TestInstance
TYPE=existing BROWSER=seleniumGrid JENKINS_URL=http://134.96.235.47:$startupPort/jenkins$JenkinsVersion/ mvn \
-Dmaven.test.skip=false -Dtest=BuildTimeoutPluginTest,JobParameterSummaryPluginTest,HtmlPublisherPluginTest,MailWatcherPluginTest,\
CoberturaPluginTest,PlotPluginTest,MultipleScmsPluginTest,JavadocPluginTest,DescriptionSetterPluginTest,\
NestedViewPluginTest,CompressArtifactsPluginTest,\
DashboardViewPluginTest,ProjectDescriptionSetterPluginTest,BatchTaskPluginTest,WsCleanupPluginTest,\
EnvInjectPluginTest,PostBuildScriptPluginTest,MatrixReloadedPluginTest,SubversionPluginNoDockerTest,\
MailerPluginTest,ViolationsPluginTest,UpstreamDownstreamColumnPluginTest,\
OwnershipPluginTest test 2>&1 | tee $REPORTS_DIR/plugins_1.596_ath_reports_"$JenkinsVersion".log
}

# cleanup(){
# echo "_________Cleaning all processes and directories left behind by this jenkins instance____________"
# sleep 5
# kill $(ps aux | grep -E 'nisal.*java -jar /tmp*' | awk '{print $2}')
# kill $(ps aux | grep -E 'nisal.*slave*' | awk '{print $2}')
# kill $(ps aux | grep -E '/usr/lib/jvm/java.*TomcatInstance'$startupPort'*' | awk '{print $2}')
# echo "Deleting Jenkins TMP directory"
# cd /tmp
# rm -rf $(ls -la | grep nisal | awk '{print $9}')
# echo "done"
# }

while getopts ":u:v:s:i:d:c:" i; do
    case "${i}" in
        u) user=${OPTARG}
        ;;
        v) JenkinsVersion=${OPTARG}
        ;;
        s) startupPort=${OPTARG}
        ;;
        i) TestInstance=${OPTARG}
        ;;
        d) DatabaseSessionIDsVersion=${OPTARG}
        ;;
        c) CommitHash=${OPTARG}
    esac
done
shift $((OPTIND - 1))

if [[ $user == "" || $JenkinsVersion == "" || $startupPort == "" || $TestInstance == "" || $DatabaseSessionIDsVersion == "" || $CommitHash == "" ]]; then
        usage
fi

#..........................................function calls...................................

downloadJenkinsTestSuite

gatherTestReports

runJenkinsTests

# cleanup
