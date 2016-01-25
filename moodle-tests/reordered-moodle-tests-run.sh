#! /bin/bash

# Description: Selenium tests script for Moodle, takes as input : 
# Author: Aditya
# ChangeLog: 
# Date: 1.09.15

usage(){
        echo "Usage: $0 <OPTIONS>"
        echo "Required options:"
        echo "  -u <USER>              User name"
        echo "  -v <MoodleVersion>     Moodle version for database and moodle home (eg 270, 281 etc)"
        echo "  -m <moodleInstance>    Eg moodle_second, moodle_third"
        echo "  -i <moodle_ip>			Eg 134.96.222.14"
        exit 1
} 


mkdir -p /home/$USER/Moodle_Selenium_Tests
BASE_TEST_DIR="/home/$USER/Moodle_Selenium_Tests/"

installTestingCode(){
echo "................................installing moodle code......................................."
			
echo "moodle test dir will be reordered_tests_$moodleInstance"
if [ -d $BASE_TEST_DIR/reordered_tests_$moodleInstance ]; then
	rm -rf $BASE_TEST_DIR/reordered_tests_$moodleInstance
fi

git -C $BASE_TEST_DIR clone -b reordered-tests-macmini --single-branch git@github.com:adini121/moodle-selenium-tests.git reordered_tests_$moodleInstance

}

gatherTestReports(){
REPORTS_DIR=/home/$USER/Dropbox/TestResults/Moodle_reordered

	if [ ! -f $REPORTS_DIR/moodle_"$MoodleVersion".log ];then
		touch $REPORTS_DIR/moodle_"$MoodleVersion".log
	fi

	if [ ! -f BrowserIdList_"$MoodleVersion".log ];then
		touch $REPORTS_DIR/BrowserIdList_"$MoodleVersion".log
	fi
}

configureMoodleTests(){
mysql -u root << EOF
use reordered_moodle_sessionIDs;
DROP TABLE IF EXISTS sessionids_$MoodleVersion;
EOF
echo "................................configuring moodle test-properties......................................."
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sed -i 's|.*moodleHomePage=.*|moodleHomePage=http://'$moodle_ip':8000/'$moodleInstance'|g' $BASE_TEST_DIR/reordered_tests_$moodleInstance/properties/runParameters.properties
sed -i 's|test_session_ids|sessionids_'$MoodleVersion'|g' $BASE_TEST_DIR/reordered_tests_$moodleInstance/src/com/moodle/test/TestRunSettings.java
sed -i 's|.*FileWriter fileWriter.*|			FileWriter fileWriter = new FileWriter("'$REPORTS_DIR'/BrowserIdList_'$MoodleVersion'.log", true);|g' $BASE_TEST_DIR/reordered_tests_$moodleInstance/src/com/moodle/test/TestRunSettings.java
}

runMoodletests(){
cd $BASE_TEST_DIR/reordered_tests_$moodleInstance
ant 2>&1 | tee $REPORTS_DIR/moodle_"$MoodleVersion".log
}

backupJUNITresults(){
cp -r junit-results $REPORTS_DIR/junit_results_$MoodleVersion
echo "Done JUNIT results backup at "$REPORTS_DIR" "
}


while getopts ":u:v:m:i:" i; do
    case "${i}" in
        u) USER=${OPTARG}
        ;;
		v) MoodleVersion=${OPTARG}
		;;
		m) moodleInstance=${OPTARG}
		;;
		i) moodle_ip=${OPTARG}
    esac
done

shift $((OPTIND - 1))

if [[ $USER == "" || $MoodleVersion == "" || $moodleInstance == "" || $moodle_ip = "" ]]; then
        usage
fi

#..........................................function calls...................................

installTestingCode

gatherTestReports

configureMoodleTests

runMoodletests

backupJUNITresults

# pushTestReportsToRemoteRep