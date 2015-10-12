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

gatherTestReports(){

	mkdir -p $BASE_TEST_DIR/moodle-test-reports
	touch $BASE_TEST_DIR/moodle-test-reports/test_reports_"$MoodleVersion".log
	touch $BASE_TEST_DIR/moodle-test-reports/test_log_from_SeNode_"$MoodleVersion".log
}

startMoodle_SeleniumHub(){
	echo "starting tmux session selenium-hub "
	tmux new -A -s selenium-hub '
	export DISPLAY=:0.0
	sleep 3
	/usr/bin/java -jar $BASE_TEST_DIR/test_$moodleInstance/lib/selenium-2.47.1/selenium-server-standalone-2.47.1.jar -role hub -hub http://localhost:4444/grid/register
	tmux detach'
	# sleep 5
	# echo "exiting tmux session selenium_hub"
}

startMoodle_SeleniumNode(){
	echo "starting tmux session selenium-node"
	tmux new -d -A -s selenium-node '
	export DISPLAY=:0.0
	sleep 2
	/usr/bin/java -jar $BASE_TEST_DIR/test_$moodleInstance/lib/selenium-2.47.1/selenium-server-standalone-2.47.1.jar -role node -hub http://localhost:4444/grid/register 2>&1 | tee $BASE_TEST_DIR/moodle-test-reports/test_log_from_SeNode_"$MoodleVersion".log
	tmux detach'
	# sleep 5
	# echo "exiting tmux session selenium-node"
}

configureMoodleTests(){
echo "................................configuring moodle test-properties......................................."
#CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
sed -i 's|.*moodleHomePage=.*|moodleHomePage=http://localhost/'$moodleInstance'|g' $BASE_TEST_DIR/test_$moodleInstance/properties/runParameters.properties

}

runMoodletests(){
	export DISPLAY=:0.0
	cd $BASE_TEST_DIR/test_$moodleInstance
	ant 2>&1 | tee $BASE_TEST_DIR/moodle-test-reports/test_reports_"$MoodleVersion".log
	#ant -Dbasedir=$BASE_TEST_DIR/test_$moodleInstance -f $BASE_TEST_DIR/test_$moodleInstance/build.xml 2>&1 | tee $BASE_TEST_DIR/moodle-test-reports/test_reports_"$MoodleVersion".log
}

# pushTestReportsToRemoteRepo(){
# 	git config --global url."https://adini121@github.com"
# 	git -C $BASE_TEST_DIR/moodle-test-reports init
# 	git -C $BASE_TEST_DIR/moodle-test-reports config remote.origin.url https://adini121:adsad1221@github.com/adini121/test-reports.git
# 	git -C $BASE_TEST_DIR/moodle-test-reports add .
# 	git -C $BASE_TEST_DIR/moodle-test-reports commit -m "commit before fetch and pull for report test_reports_"$MoodleVersion".log"
# 	git -C $BASE_TEST_DIR/moodle-test-reports fetch
# 	git -C $BASE_TEST_DIR/moodle-test-reports pull origin moodle-test-reports
# 	git -C $BASE_TEST_DIR/moodle-test-reports add .
# 	git -C $BASE_TEST_DIR/moodle-test-reports commit -m "test report test_reports_"$MoodleVersion".log for version $MoodleVersion"
# 	git -C $BASE_TEST_DIR/moodle-test-reports push https://adini121:adsad1221@github.com/adini121/test-reports.git moodle-test-reports

# }

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

startMoodle_SeleniumHub

startMoodle_SeleniumNode

configureMoodleTests

runMoodletests

# pushTestReportsToRemoteRepo
