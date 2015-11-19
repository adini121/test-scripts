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
        exit 1
} 


mkdir -p /home/$USER/Moodle_Selenium_Tests
BASE_TEST_DIR="/home/$USER/Moodle_Selenium_Tests/"

installTestingCode(){
	echo "................................installing moodle code......................................."
			
		echo "moodle test dir will be test_$moodleInstance"
		if [ ! -d $BASE_TEST_DIR/test_$moodleInstance ]; then
			git -C $BASE_TEST_DIR clone https://github.com/adini121/moodle-selenium-tests.git test_$moodleInstance
		fi
 	git -C $BASE_TEST_DIR/test_$moodleInstance stash
	git -C $BASE_TEST_DIR/test_$moodleInstance pull
	
}

gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
echo "Current Time : "$currentTime""
REPORTS_DIR=/home/$USER/Dropbox/TestResults/Moodle

	if [ ! -f $REPORTS_DIR/moodle_"$MoodleVersion".log ];then
		touch $REPORTS_DIR/"$currentTime"_moodle_"$MoodleVersion".log
	fi

	if [ ! -f $REPORTS_DIR/moodle_"$MoodleVersion".log ];then
		touch $REPORTS_DIR/"$currentTime"_BrowserIdList_"$MoodleVersion".log
	fi
}


configureMoodleTests(){
echo "................................configuring moodle test-properties......................................."
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sed -i 's|.*moodleHomePage=.*|moodleHomePage=http://134.96.235.134/'$moodleInstance'|g' $BASE_TEST_DIR/test_$moodleInstance/properties/runParameters.properties
# sed -i 's|.*gridHubURL=.*|gridHubURL=http://localhost:4444/wd/hub|g' $BASE_TEST_DIR/test_$moodleInstance/properties/runParameters.properties
sed -i 's|.*FileWriter fileWriter.*|FileWriter fileWriter = new FileWriter("/home/'$USER'/Dropbox/TestResults/Moodle/'$REPORTS_DIR'/'$currentTime'_BrowserIdList_'$MoodleVersion'.log", true);|g' $BASE_TEST_DIR/test_$moodleInstance/src/com/moodle/test/TestRunSettings.java
}

runMoodletests(){
cd $BASE_TEST_DIR/test_$moodleInstance
ant 2>&1 | tee $REPORTS_DIR/"$currentTime"_moodle_"$MoodleVersion".log
#ant -Dbasedir=$BASE_TEST_DIR/test_$moodleInstance -f $BASE_TEST_DIR/test_$moodleInstance/build.xml 2>&1 | tee $BASE_TEST_DIR/moodle-test-reports/test_reports_"$MoodleVersion".log
}

backupJUNITresults(){
cp -r junit-results $REPORTS_DIR/"$currentTime"_junit_results_$MoodleVersion
cp -r junit-reports $REPORTS_DIR/"$currentTime"_junit_results_$MoodleVersion
Echo "Done JUNIT results backup at "$REPORTS_DIR" "
}


while getopts ":u:v:m:" i; do
    case "${i}" in
        u) USER=${OPTARG}
        ;;
		v) MoodleVersion=${OPTARG}
		;;
		m) moodleInstance=${OPTARG}
    esac
done

shift $((OPTIND - 1))

if [[ $USER == "" || $MoodleVersion == "" || $moodleInstance == "" ]]; then
        usage
fi

#..........................................function calls...................................

installTestingCode

gatherTestReports

configureMoodleTests

runMoodletests

backupJUNITresults

# pushTestReportsToRemoteRep