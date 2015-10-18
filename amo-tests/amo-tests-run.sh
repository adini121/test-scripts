# /bin/sh

# Description: Selenium tests script for AMO
# Author: Aditya

usage(){
        echo "Usage: $0 <OPTIONS>"
        echo "Required options:"
        echo "  -u $USER            user name"
        echo "  -t <AMOGitTag>      AMO git tag eg: 2015.09.08 | 2015.09.15 | 2015.09.22"
        echo "  -m <AMOInstance>    Eg AMO_first, AMO_second"
        echo "  -p <AMOPort>        Eg 8088, 8089"
        exit 1
}


mkdir -p /home/$USER/AMOHome
AMOBaseDir="/home/$USER/AMOHome"

installTestingCode(){
echo "................................installing AMO test code......................................."
			
	echo "AMO dir will be test_$AMOInstance"
		if [ ! -d $AMOBaseDir/test_$AMOInstance ]; then
			git -C $AMOBaseDir clone --recursive https://github.com/mozilla/Addon-Tests test_$AMOInstance
		fi
 	
	git -C $AMOBaseDir/test_$AMOInstance pull
	git -C $AMOBaseDir/test_$AMOInstance submodule update --init
}

gatherTestReports(){
mkdir -p $AMOBaseDir/AMO-test-reports
	if [ ! -f $AMOBaseDir/AMO-test-reports/test_reports_"$AMOGitTag".log ] || [ ! -f $AMOBaseDir/AMO-test-reports/test_log_from_SeNode_"$AMOGitTag".log ] || [ ! -f $AMOBaseDir/AMO-test-reports/selenium-hub-AMO-output.log ];
		then
			touch $AMOBaseDir/AMO-test-reports/test_reports_"$AMOGitTag".log
			touch $AMOBaseDir/AMO-test-reports/test_log_from_SeNode_"$AMOGitTag".log
			touch $AMOBaseDir/AMO-test-reports/selenium-hub-AMO-output.log
	fi
}

startAMO_SeleniumHub(){
	echo "starting tmux session selenium-hub-AMO "
	tmux kill-session -t selenium-hub-AMO
	tmux new -d -A -s selenium-hub-AMO '
	export DISPLAY=:0.0
	sleep 3
	/usr/bin/java -jar /home/'$USER'/selenium-server-standalone-2.47.1.jar -role hub -hub http://localhost:4444/grid/register 2>&1 | tee '$AMOBaseDir'/AMO-test-reports/selenium-hub-AMO-output.log
	sleep 2
	tmux detach'
	# sleep 5
	# echo "exiting tmux session selenium_hub"
}

startAMO_SeleniumNode(){
	echo "starting tmux session selenium-node-AMO-AMO"
	tmux kill-session -t selenium-node-AMO
	tmux new -d -A -s selenium-node-AMO '
	export DISPLAY=:0.0
	sleep 3
	/usr/bin/java -jar /home/'$USER'/selenium-server-standalone-2.47.1.jar -role node -hub http://localhost:4444/grid/register -browser browserName=firefox -platform platform=LINUX 2>&1 | tee '$AMOBaseDir'/AMO-test-reports/test_log_from_SeNode_'$AMOGitTag'.log
	sleep 2
	tmux detach'
	# sleep 5
	# echo "exiting tmux session selenium-node-AMO"
}

configureAMOTests(){
echo "................................configuring AMO test-properties......................................."
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "CURRENT_DIR="$CURRENT_DIR""
cp $CURRENT_DIR/amo_variables.json $AMOBaseDir/test_$AMOInstance

}

configureVirtualenv(){
	echo "................................configuring AMO Virtualenv......................................."
	curl -sL https://raw.github.com/brainsik/virtualenv-burrito/master/virtualenv-burrito.sh | $SHELL
	source /home/$USER/.venvburrito/startup.sh
	cd $AMOBaseDir/test_$AMOInstance
	mkvirtualenv test_$AMOInstance
	pip install -r requirements.txt
	sleep 2
}

runAMOtests(){
	#export DISPLAY=:0.0
	py.test --baseurl=http://localhost:$AMOPort --browsername=firefox --credentials=amo_variables.json --platform=linux --destructive  tests/desktop/ 2>&1 | tee $AMOBaseDir/AMO-test-reports/test_reports_"$AMOGitTag".log
}



while getopts ":u:t:m:p:" i; do
    case "${i}" in
        u) USER=${OPTARG}
        ;;
        t) AMOGitTag=${OPTARG}
        ;;
        m) AMOInstance=${OPTARG}
        ;;
        p) AMOPort=${OPTARG}
    esac
done

shift $((OPTIND - 1))

if [[ $USER == "" || $AMOGitTag == "" || $AMOInstance == "" || $AMOPort == "" ]]; then
        usage
fi

#..........................................function calls...................................

installTestingCode

gatherTestReports

startAMO_SeleniumHub

startAMO_SeleniumNode

configureAMOTests

configureVirtualenv

runAMOtests
