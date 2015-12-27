# /bin/sh

# Description: Selenium tests script for AMO
# Author: Aditya

usage(){
        echo "Usage: $0 <OPTIONS>"
        echo "Required options:"
        echo "  -u $USER            user name"
        echo "  -t <AMOGitTag_underscores>      AMO git tag eg: 2015_09_08 | 2015_09_15 | 2015_09_22"
        echo "  -m <AMOInstance>    Eg AMO_first, AMO_second"
        echo "  -p <AMOPort>        Eg 9001, 8088, 8089"
        echo "  -c <CommitHash>		CommitHash"
        exit 1
}
mkdir -p /home/$USER/AMOHome
AMOBaseDir="/home/$USER/AMOHome"

installTestingCode(){
echo "................................installing AMO test code......................................."
echo "AMO dir will be test_$AMOInstance"
if [ -d $AMOBaseDir/test_$AMOInstance ]; then
	rm -rf $AMOBaseDir/test_$AMOInstance
fi
git -C $AMOBaseDir clone https://github.com/mozilla/Addon-Tests test_$AMOInstance
git -C $AMOBaseDir/test_$AMOInstance stash
git -C $AMOBaseDir/test_$AMOInstance pull
git -C $AMOBaseDir/test_$AMOInstance checkout $CommitHash
}

gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
echo "Current Time : $currentTime"
REPORTS_DIR="/home/$USER/Dropbox/TestResults/AMO"
echo "Reports directory is: "$REPORTS_DIR" "
if [ ! -f $REPORTS_DIR/"$currentTime"_AMOTests_"$CommitHash"_"$AMOGitTag_underscores".log ];then
	touch $REPORTS_DIR/"$currentTime"_AMOTests_"$CommitHash"_"$AMOGitTag_underscores".log
fi
}

configureAMOTests(){
echo "................................configuring AMO test-properties......................................."
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "CURRENT_DIR="$CURRENT_DIR""
mysql -u root << EOF
use amo_sessionIDs;
DROP TABLE IF EXISTS sessionids_$AMOGitTag_underscores;
EOF
# sed -i 's|test_session_ids|sessionids_'$AMOGitTag_underscores'|g' $AMOBaseDir/test_$AMOInstance/conftest.py
# sed -i 's|/home/adi/python.txt|'$REPORTS_DIR'/'$currentTime'_BrowserIdList_'$AMOGitTag_underscores'.log|g' $AMOBaseDir/test_$AMOInstance/conftest.py
cp $CURRENT_DIR/credentials.yaml $AMOBaseDir/test_$AMOInstance/credentials.yaml
}

configureVirtualenv(){
echo "................................configuring AMO Virtualenv......................................."
cd $AMOBaseDir/test_$AMOInstance
pip install virtualenv
virtualenv $AMOInstance
source $AMOInstance/bin/activate
pip install -r requirements.txt
pip install MySQL-python
sleep 1
}

runAMOtests(){
#export DISPLAY=:0.0
py.test  -r=fsxXR --verbose --baseurl=http://134.96.235.47:$AMOPort --host 134.96.235.159 --port 1235 --browsername=firefox --capability=browser:FIREFOX_30_WINDOWS_8_64 --capability=email:test@testfabrik.com --capability=record:false --capability=extract:false --capability=apikey:c717c5b3-a307-461e-84ea-1232d44cde89 --credentials=credentials.yaml --platform=MAC --destructive tests/desktop/ 2>&1 | tee $REPORTS_DIR/"$currentTime"_AMOTests_"$CommitHash"_"$AMOGitTag_underscores".log
}



while getopts ":u:t:m:p:c:" i; do
    case "${i}" in
        u) USER=${OPTARG}
        ;;
        t) AMOGitTag_underscores=${OPTARG}
        ;;
        m) AMOInstance=${OPTARG}
        ;;
        p) AMOPort=${OPTARG}
		;;
		c) CommitHash=${OPTARG}
    esac
done

shift $((OPTIND - 1))

if [[ $USER == "" || $AMOGitTag_underscores == "" || $AMOInstance == "" || $AMOPort == "" || $CommitHash == "" ]]; then
        usage
fi

#..........................................function calls...................................

installTestingCode

gatherTestReports

configureAMOTests

configureVirtualenv

runAMOtests
