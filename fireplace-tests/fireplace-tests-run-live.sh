# /bin/sh

# Description: Selenium tests script for Fireplace
# Author: Aditya

usage(){
        echo "Usage: $0 <OPTIONS>"
        echo "Required options:"
        echo "  -u $USER                  user name"
        echo "  -t <FireplaceGitTag>      Fireplace git tag eg: 2015.09.08 | 2015.09.15 | 2015.09.22"
        echo "  -m <FireplaceInstance>    Eg Fireplace_first, Fireplace_second"
        # echo "	-h <FireplaceHost>		  Eg localhost, 134.96.235.47, 134.96.235.134"
        echo "  -p <FireplacePort>        Eg 8088, 8089"
        # echo "  -g <Grid_Address>         Selenium GRID URL Address e.g. 192.168.2.3, infinity.st.cs.uni-saarland.de"
        # echo "  -o <Grid_Port>            Selenium GRID port e.g. 4444, 6666"
        # echo "  -c <CommitHash>			  CommitHash"
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
 	git -C $FireplaceBaseDir/test_$FireplaceInstance stash
	git -C $FireplaceBaseDir/test_$FireplaceInstance fetch
	git -C $FireplaceBaseDir/test_$FireplaceInstance submodule update --init
	# git -C $FireplaceBaseDir/test_$FireplaceInstance checkout $CommitHash
}

gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
echo "Current Time : $currentTime"
REPORTS_DIR="/home/$USER/Dropbox/TestResults/Marketplace"
echo "Reports directory is: "$REPORTS_DIR" "
if [ ! -f $REPORTS_DIR/"$currentTime"_fireplaceTests_"$FireplaceGitTag".log ];then
	touch $REPORTS_DIR/"$currentTime"_fireplaceTests_"$FireplaceGitTag".log
fi
}

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
	sed -i 's|http:|https:|g' /home/nisal/.virtualenvs/test_$FireplaceInstance/lib/python2.7/site-packages/pytest_mozwebqa/selenium_client.py
	py.test -r=fsxXR --verbose --baseurl=http://134.96.235.47:$FireplacePort --capability=email:adityanisal@googlemail.com --capability=apikey:5c924a5e-83b2-4645-b238-e7ff03abc905 --capability=record:true --capability=extract:true --capability=browser:FIREFOX_30_WINDOWS_7_64 --host app.webmate.io --port 44444 --browsername=firefox --credentials=credentials.yaml --platform=windows --destructive tests/desktop/consumer_pages/ 2>&1 | tee $REPORTS_DIR/"$currentTime"_fireplaceTests_"$FireplaceGitTag".log
}



while getopts ":u:t:m:p:" i; do
    case "${i}" in
        u) USER=${OPTARG}
        ;;
        t) FireplaceGitTag=${OPTARG}
        ;;
        m) FireplaceInstance=${OPTARG}
        ;;
        p) FireplacePort=${OPTARG}
		# ;;
		# h) FireplaceHost=${OPTARG}
		# ;;
		# g) Grid_Address=${OPTARG}
  #       ;;
  #       o) Grid_Port=${OPTARG}
		# ;;
		# c) CommitHash=${OPTARG}
    esac
done

shift $((OPTIND - 1))

if [[ $USER == "" || $FireplaceGitTag == "" || $FireplaceInstance == "" || $FireplacePort == "" ]];then
	# || $FireplaceHost == "" || $Grid_Address == ""|| $Grid_Port == "" || $CommitHash == "" ]]; then
        usage
fi

#..........................................function calls...................................

installTestingCode

gatherTestReports

configureFireplaceTests

configureVirtualenv

runFireplacetests
