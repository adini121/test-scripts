# /bin/sh

# Description: Selenium tests script for Fireplace
# Author: Aditya

usage(){
        echo "Usage: $0 <OPTIONS>"
        echo "Required options:"
        echo "  -u $USER                  user name"
        echo "  -t <FireplaceGitTag>      Fireplace git tag eg: 2015.09.08 | 2015.09.15 | 2015.09.22"
        echo "  -m <FireplaceInstance>    Eg Fireplace_first, Fireplace_second"
        echo "	-h <FireplaceHost>		  Eg localhost, 134.96.235.47, 134.96.235.134"
        echo "  -p <FireplacePort>        Eg 8088, 8089"
        echo "  -g <Grid_Address>         Selenium GRID URL Address e.g. 192.168.2.3, infinity.st.cs.uni-saarland.de"
        echo "  -o <Grid_Port>            Selenium GRID port e.g. 4444, 6666"
        exit 1
}


mkdir -p /home/$USER/Fireplace
FireplaceBaseDir="/home/$USER/Fireplace"

installTestingCode(){
echo "................................installing Fireplace test code......................................."
			
	echo "Fireplace dir will be test_$FireplaceInstance"
		if [ ! -d $FireplaceBaseDir/test_$FireplaceInstance ]; then
			git -C $FireplaceBaseDir clone --recursive https://github.com/mozilla/marketplace-tests test_$FireplaceInstance
		fi
 	
	git -C $FireplaceBaseDir/test_$FireplaceInstance pull
	git -C $FireplaceBaseDir/test_$FireplaceInstance submodule update --init
}

gatherTestReports(){
mkdir -p $FireplaceBaseDir/Fireplace-test-reports
	if [ ! -f $FireplaceBaseDir/Fireplace-test-reports/test_reports_"$FireplaceGitTag".log ] || [ ! -f $FireplaceBaseDir/Fireplace-test-reports/test_log_from_SeNode_"$FireplaceGitTag".log ] || [ ! -f $FireplaceBaseDir/Fireplace-test-reports/selenium-hub-fireplace-output.log ];
		then
			touch $FireplaceBaseDir/Fireplace-test-reports/test_reports_"$FireplaceGitTag".log
			touch $FireplaceBaseDir/Fireplace-test-reports/test_log_from_SeNode_"$FireplaceGitTag".log
			touch $FireplaceBaseDir/Fireplace-test-reports/selenium-hub-fireplace-output.log
	fi
}

# startFireplace_SeleniumHub(){
# 	echo "starting tmux session selenium-hub-fireplace-fireplace "
# 	tmux kill-session -t selenium-hub-fireplace
# 	tmux new -d -A -s selenium-hub-fireplace '
# 	export DISPLAY=:0.0
# 	sleep 3
# 	/usr/bin/java -jar /home/'$USER'/selenium-server-standalone-2.47.1.jar -role hub -hub http://localhost:4444/grid/register 2>&1 | tee '$FireplaceBaseDir'/Fireplace-test-reports/selenium-hub-fireplace-output.log
# 	sleep 2
# 	tmux detach'
# 	# sleep 5
# 	# echo "exiting tmux session selenium_hub"
# }

# startFireplace_SeleniumNode(){
# 	echo "starting tmux session selenium-node-fireplace-fireplace"
# 	tmux kill-session -t selenium-node-fireplace
# 	tmux new -d -A -s selenium-node-fireplace '
# 	export DISPLAY=:0.0
# 	sleep 3
# 	/usr/bin/java -jar /home/'$USER'/selenium-server-standalone-2.47.1.jar -role node -hub http://localhost:4444/grid/register -browser browserName=firefox -platform platform=LINUX 2>&1 | tee '$FireplaceBaseDir'/Fireplace-test-reports/test_log_from_SeNode_'$FireplaceGitTag'.log
# 	sleep 2
# 	tmux detach'
# 	# sleep 5
# 	# echo "exiting tmux session selenium-node-fireplace"
# }

configureFireplaceTests(){
echo "................................configuring Fireplace test-properties......................................."
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cp $CURRENT_DIR/credentials.yaml $FireplaceBaseDir/test_$FireplaceInstance/credentials.yaml

}

configureVirtualenv(){
	echo "................................configuring Fireplace Virtualenv......................................."
	curl -sL https://raw.github.com/brainsik/virtualenv-burrito/master/virtualenv-burrito.sh | $SHELL
	source /home/$USER/.venvburrito/startup.sh
	cd $FireplaceBaseDir/test_$FireplaceInstance
	mkvirtualenv test_$FireplaceInstance
	pip install -r requirements.txt
	sleep 2
}

runFireplacetests(){
	#export DISPLAY=:0.0
	py.test -r=fsxXR --verbose --baseurl=http://$FireplaceHost:$FireplacePort --host $Grid_Address --port $Grid_Port --browsername=firefox --credentials=credentials.yaml --platform=linux --destructive  tests/desktop/consumer_pages/ 2>&1 | tee $FireplaceBaseDir/Fireplace-test-reports/test_reports_"$FireplaceGitTag".log
}



while getopts ":u:t:m:p:h:g:o:" i; do
    case "${i}" in
        u) USER=${OPTARG}
        ;;
        t) FireplaceGitTag=${OPTARG}
        ;;
        m) FireplaceInstance=${OPTARG}
        ;;
        p) FireplacePort=${OPTARG}
		;;
		h) FireplaceHost=${OPTARG}
		;;
		g) Grid_Address=${OPTARG}
        ;;
        o) Grid_Port=${OPTARG}
    esac
done

shift $((OPTIND - 1))

if [[ $USER == "" || $FireplaceGitTag == "" || $FireplaceInstance == "" || $FireplacePort == "" || $FireplaceHost == "" || $Grid_Address == ""|| $Grid_Port == ""  ]]; then
        usage
fi

#..........................................function calls...................................

installTestingCode

gatherTestReports

# startFireplace_SeleniumHub

# startFireplace_SeleniumNode

configureFireplaceTests

configureVirtualenv

runFireplacetests
