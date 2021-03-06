# /bin/sh

# Description: Selenium tests script for AMO
# Author: Aditya

usage(){
        echo "Usage: $0 <OPTIONS>"
        echo "Required options:"
        echo "  -u $USER            user name"
        echo "  -t <AMOGitTag>      AMO git tag eg: 2015_09_08 | 2015_09_15 | 2015_09_22"
        echo "  -m <AMOInstance>    Eg AMO_first, AMO_second"
        echo "  -p <AMOPort>        Eg 9001, 8088, 8089"
        exit 1
}
mkdir -p /home/$USER/AMOHome
AMOBaseDir="/home/$USER/AMOHome"

installTestingCode(){
echo "................................installing AMO test code......................................."
echo "AMO dir will be test_mv0_$AMOInstance"
if [ -d $AMOBaseDir/test_mv0_$AMOInstance ]; then
	rm -rf $AMOBaseDir/test_mv0_$AMOInstance
fi
git -C $AMOBaseDir clone -b addons-mv0 --single-branch git@github.com:adini121/Addon-Tests.git test_mv0_$AMOInstance
}

gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
echo "Current Time : $currentTime"
REPORTS_DIR="/home/$USER/Dropbox/TestResults/AMO"
echo "Reports directory is: "$REPORTS_DIR" "
if [ ! -f $REPORTS_DIR/"$currentTime"_AMOTests_mv0_"$AMOGitTag".log ];then
	touch $REPORTS_DIR/"$currentTime"_AMOTests_mv0_"$AMOGitTag".log
fi

if [ ! -f $REPORTS_DIR/"$currentTime"_AMO_BrowserIdList_mv0_"$AMOGitTag".log ];then
    touch $REPORTS_DIR/"$currentTime"_AMO_BrowserIdList_mv0_"$AMOGitTag".log
fi
}

configureAMOTests(){
echo "................................configuring AMO test-properties......................................."
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "CURRENT_DIR="$CURRENT_DIR""
mysql -u root << EOF
use amo_sessionIDs;
DROP TABLE IF EXISTS sessionids_$AMOGitTag;
EOF
sed -i 's|test_session_ids|sessionids_'$AMOGitTag'|g' $AMOBaseDir/test_mv0_$AMOInstance/conftest.py
sed -i 's|/home/nisal/python.txt|'$REPORTS_DIR'/'$currentTime'_AMO_BrowserIdList_mv0_'$AMOGitTag'.log|g' $AMOBaseDir/test_mv0_$AMOInstance/conftest.py
cp $CURRENT_DIR/credentials.yaml $AMOBaseDir/test_mv0_$AMOInstance/credentials.yaml
}

configureVirtualenv(){
echo "................................configuring AMO Virtualenv......................................."
cd $AMOBaseDir/test_mv0_$AMOInstance
pip install virtualenv
virtualenv $AMOInstance
source $AMOInstance/bin/activate
pip install -r requirements.txt
pip install MySQL-python
sleep 2
}

runAMOtests(){
#export DISPLAY=:0.0
py.test  -r=fsxXR --verbose --baseurl=http://134.96.235.47:$AMOPort --host 134.96.235.159 --port 1235 --browsername=firefox --capability=browser:FIREFOX_30_WINDOWS_8_64 --capability=email:test@testfabrik.com --capability=record:true --capability=extract:true --capability=apikey:c717c5b3-a307-461e-84ea-1232d44cde89 --credentials=credentials.yaml --platform=MAC --destructive tests/desktop/ 2>&1 | tee $REPORTS_DIR/"$currentTime"_AMOTests_mv0_"$AMOGitTag".log
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

configureAMOTests

configureVirtualenv

runAMOtests
