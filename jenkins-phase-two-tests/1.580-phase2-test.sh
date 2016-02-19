#! /bin/bash

# Description: Test script for jenkins, takes as input : User, Jenkins version, Tomcat Port on which Jenkins will run, Test instance
# Author: Aditya

# Checklist:
# Jenkins commitHash,getopts,case,call to usage function,usage function options,
# sessionID-database-name,
# sessionID-table-name
# Reports directory
# 
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

if [ ! -d $JENKINS_Test_DIR/Jenkins_phase2_ath_$TestInstance ]; then
    git -C $JENKINS_Test_DIR clone git@github.com:adini121/acceptance-test-harness.git Jenkins_phase2_ath_$TestInstance
else
    rm -rf $JENKINS_Test_DIR/Jenkins_phase2_ath_$TestInstance
    git -C $JENKINS_Test_DIR clone git@github.com:adini121/acceptance-test-harness.git Jenkins_phase2_ath_$TestInstance
fi
git -C $JENKINS_Test_DIR/Jenkins_phase2_ath_$TestInstance checkout $CommitHash
git -C $JENKINS_Test_DIR/Jenkins_phase2_ath_$TestInstance checkout -b infinity-cherry-pick-branch
git -C $JENKINS_Test_DIR/Jenkins_phase2_ath_$TestInstance cherry-pick 7348ab40ffb159c83982b18380c3d516cc99a507
git -C $JENKINS_Test_DIR/Jenkins_phase2_ath_$TestInstance cherry-pick 89a59d4bd2a22575690bde8f1f2d4e5cb6d9056d
}

modifyPOMxml(){
sleep 5
increment_variable=0
file_name="$JENKINS_Test_DIR/Jenkins_phase2_ath_$TestInstance/pom.xml"
for i in $(awk '/<artifactId>maven-surefire-plugin<\/artifactId>/ {print FNR}' $file_name); do
        echo "Line" $i
        #awk 'NR >= "'$i'" && NR <= "'$i'"+4' $file_name
        var1=$(sed "$((${i}+${increment_variable}+1))q;d" $file_name | awk '{$1=$1};1')
        echo "Var1="$var1
        if [ "<version>2.17</version>" == "$var1" ]; then
                echo "another match founded"
                                var2=$(sed "$((${i}+${increment_variable}+2))q;d" $file_name | awk '{$1=$1};1')
                                echo "Var2="$var2
                                var3=$(sed "$((${i}+${increment_variable}+3))q;d" $file_name | awk '{$1=$1};1')
                                echo "Var3="$var3
                                var4=$(sed "$((${i}+${increment_variable}+4))q;d" $file_name | awk '{$1=$1};1')
                                echo "Var4="$var4
                                if [[ "<configuration>" == "$var2" && "<includes>" == "$var3" ]]; then
                                        echo "Adding a line"
                                        echo "Insert line here"
                                        adding_position=$((${i}+${increment_variable}+3))
                                        sed -i "$adding_position i\             <runOrder>alphabetical</runOrder>" $file_name
                                        increment_variable=$(($increment_variable+1))
                                elif [[ "<configuration>" == "$var2" && "<runOrder>alphabetical</runOrder>" = "$var3" ]] && [[ "<includes>" = "$var4" ]]; then
                                        echo "====================================ALREADY PRESENT!===================================="
                                elif  [[ "<configuration>" == "$var2" && "<includes>" != "$var3" ]] || [[ "<configuration>" == "$var2" && "<runOrder>alphabetical</runOrder>" = "$var3" ]]; then
                                        echo "====================================ERROR!===================================="
                                fi
        fi
done
}

gatherTestReports(){
sleep 2
currentTime=$(date "+%Y.%m.%d-%H.%M")
REPORTS_DIR="/home/nisal/Dropbox/PhaseTwoTestResults/Jenkins/Core"
if [ ! -f $REPORTS_DIR/Core_phase2_ath_reports_"$JenkinsVersion".log ];then
    	touch $REPORTS_DIR/Core_phase2_ath_reports_"$JenkinsVersion".log
fi
if [ ! -f $REPORTS_DIR/Core_phase2_ath_BrowserIdList_"$JenkinsVersion".log ];then
		touch $REPORTS_DIR/Core_phase2_ath_BrowserIdList_"$JenkinsVersion".log
fi
mysql -u root << EOF
use phase_two_jenkins_Core_sids;
DROP TABLE IF EXISTS sessionids_phase2_$DatabaseSessionIDsVersion;
EOF
TestsDir="$JENKINS_Test_DIR/Jenkins_phase2_ath_$TestInstance/src/main/java/org/jenkinsci/test/acceptance"
sed -i 's|jenkins_core_sessionIDs|phase_two_jenkins_Core_sids|g' $TestsDir/utils/SeleniumGridConnection.java
sed -i 's|\"record\", false|\"record\", true|g' $TestsDir/FallbackConfig.java
sed -i 's|\"extract\", false|\"extract\", false|g' $TestsDir/FallbackConfig.java
sed -i 's|\"extract\", true|\"extract\", false|g' $TestsDir/FallbackConfig.java
# sed -i 's|FIREFOX_30_WINDOWS_8_64|PHANTOMJS_198_MACOS_10.11_64|g' $TestsDir/FallbackConfig.java
sed -i 's|test_session_ids|sessionids_phase2_'$DatabaseSessionIDsVersion'|g' $TestsDir/utils/SeleniumGridConnection.java
sed -i 's|.*FileWriter fileWriter.*|            FileWriter fileWriter = new FileWriter("'$REPORTS_DIR'/Core_phase2_ath_BrowserIdList_'$JenkinsVersion'.log", true);|g' $TestsDir/utils/SeleniumGridConnection.java
}

runJenkinsTests(){
echo "..............................................runJenkinsTests.............................................."
cd $JENKINS_Test_DIR/Jenkins_phase2_ath_$TestInstance
TYPE=existing BROWSER=seleniumGrid JENKINS_URL=http://134.96.235.47:$startupPort/jenkins$JenkinsVersion/ mvn \
-Dmaven.test.skip=false -Dtest=CreateSlaveTest,ArtifactsTest,ViewTest,ScriptTest,MatrixTest,CredentialsTest,InternalUsersTest test 2>&1 | tee $REPORTS_DIR/Core_phase2_ath_reports_"$JenkinsVersion".log
}

cleanup(){
echo "_________Cleaning all processes and directories left behind by this jenkins instance____________"
sleep 5
kill $(ps aux | grep -E 'nisal.*java -jar /tmp*' | awk '{print $2}')
kill $(ps aux | grep -E 'nisal.*slave*' | awk '{print $2}')
# kill $(ps aux | grep -E '/usr/lib/jvm/java.*TomcatInstance'$startupPort'*' | awk '{print $2}')
echo "Deleting Jenkins TMP directory"
cd /tmp
rm -rf $(ls -la | grep -E 'nisal.*slave*' | awk '{print $9}')
rm -rf $(ls -la | grep -E '*nisal*.*._.*' | awk '{print $9}')
rm -rf $(ls -la | grep -E '*nisal*.*tool*' | awk '{print $9}')
rm -rf tmp*
kill $(ps aux | grep -E 'nisal.*java -jar /tmp*' | awk '{print $2}')
kill $(ps aux | grep -E 'nisal.*slave*' | awk '{print $2}')
echo "done"
}

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

modifyPOMxml

gatherTestReports

runJenkinsTests

cleanup
