#! /bin/bash

# Description: Selenium tests script for Moodle, takes as input : 
# Author: Aditya
# ChangeLog: 
# Date: 1.09.15

usage(){
        echo "Usage: $0 <OPTIONS>"
        echo "Required options:"
        echo "  -u $USER               USER name"
        echo "  -v <MoodleVersion>     Moodle version for database and moodle home (eg 270, 281 etc)"
        echo "  -m <moodleInstance>    Eg moodle_second, moodle_third"
        exit 1
}

installMoodleCode(){
	echo "................................installing moodle code......................................."
		mkdir -p /home/$USER/moodle-selenium-tests
		
		if [ ! -d /home/$USER/moodle-selenium-tests/$moodleInstance_tests ]; then
			BASE_TEST_DIR="/home/$USER/moodle-selenium-tests/"
			git -C $BASE_TEST_DIR clone https://github.com/adini121/moodle-selenium-tests.git $moodleInstance_tests
		fi
 
	git -C $BASE_TEST_DIR/$moodleInstance_tests pull
	
}

configureMoodleTests(){
echo "................................configuring moodle test-properties......................................."
#CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
sed -i 's|.*moodleHomePage=.*|moodleHomePage=http://localhost/'$moodleInstance'|g' $BASE_TEST_DIR/$moodleInstance_tests/properties/runParameters.properties

}

runMoodletests(){
	mkdir -p $BASE_TEST_DIR/moodle-test-reports
	touch $BASE_TEST_DIR/moodle-test-reports/$MoodleVersion_test.reports
	ant -Dbasedir=$BASE_TEST_DIR/$moodleInstance_tests -f $BASE_TEST_DIR/$moodleInstance_tests/build.xml 2>&1 | tee $BASE_TEST_DIR/moodle-test-reports/$MoodleVersion_test.reports
}

pushTestReportsToRemoteRepo(){
	git -C $BASE_TEST_DIR/moodle-test-reports init
	git -C $BASE_TEST_DIR/moodle-test-reports remote add origin git@github.com:adini121/test-reports.git
	git -C $BASE_TEST_DIR/moodle-test-reports fetch
	git -C $BASE_TEST_DIR/moodle-test-reports pull origin moodle-test-reports
	git -C $BASE_TEST_DIR/moodle-test-reports add .
	git -C $BASE_TEST_DIR/moodle-test-reports commit -m "test report $MoodleVersion_test.reports for version $MoodleVersion"
	git -C $BASE_TEST_DIR/moodle-test-reportspush https://adini121:adsad1221@github.com/adini121/test-reports.git moodle-test-reports

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

installMoodleCode
