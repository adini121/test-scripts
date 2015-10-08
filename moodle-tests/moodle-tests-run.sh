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

installTestingCode(){
	echo "................................installing moodle code......................................."
		mkdir -p /home/$USER/Moodle_Selenium_Tests
		BASE_TEST_DIR="/home/$USER/Moodle_Selenium_Tests/"
		echo "moodle dir will be test_$moodleInstance"
		if [ ! -d /home/$USER/Moodle_Selenium_Tests/test_$moodleInstance ]; then
			git -C $BASE_TEST_DIR clone https://github.com/adini121/moodle-selenium-tests.git test_$moodleInstance
		fi
 	
	git -C $BASE_TEST_DIR/test_$moodleInstance pull

	
}

configureMoodleTests(){
echo "................................configuring moodle test-properties......................................."
#CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
sed -i 's|.*moodleHomePage=.*|moodleHomePage=http://localhost/'$moodleInstance'|g' $BASE_TEST_DIR/test_$moodleInstance/properties/runParameters.properties

}

runMoodletests(){
	mkdir -p $BASE_TEST_DIR/moodle-test-reports
	touch $BASE_TEST_DIR/moodle-test-reports/test_reports_"$MoodleVersion".log
	ant -Dbasedir=$BASE_TEST_DIR/test_$moodleInstance -f $BASE_TEST_DIR/test_$moodleInstance/build.xml 2>&1 | tee $BASE_TEST_DIR/moodle-test-reports/test_reports_"$MoodleVersion".log
}

pushTestReportsToRemoteRepo(){
	git -C $BASE_TEST_DIR/moodle-test-reports init
	git -C $BASE_TEST_DIR/moodle-test-reports remote add origin https://adini121:adsad1221@github.com/adini121/test-reports.git
	git -C $BASE_TEST_DIR/moodle-test-reports fetch
	git -C $BASE_TEST_DIR/moodle-test-reports checkout moodle-test-reports
	git -C $BASE_TEST_DIR/moodle-test-reports pull origin moodle-test-reports
	git -C $BASE_TEST_DIR/moodle-test-reports add .
	git -C $BASE_TEST_DIR/moodle-test-reports commit -m "test report test_reports_"$MoodleVersion".log for version $MoodleVersion"
	git -C $BASE_TEST_DIR/moodle-test-reports push https://adini121:adsad1221@github.com/adini121/test-reports.git moodle-test-reports

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

configureMoodleTests

runMoodletests

pushTestReportsToRemoteRepo
