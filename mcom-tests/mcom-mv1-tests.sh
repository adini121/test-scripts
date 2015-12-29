# /bin/sh

# Description: Selenium tests script for Bedrock
# Author: Aditya

usage(){
        echo "Usage: $0 <OPTIONS>"
        echo "Required options:"
        echo "_______________________________________"
        echo "________ I M P O R T A N T ____________"
        echo "__Run inside venv from home directory__"
        echo "_______________________________________"
        echo "  -u $USER                User name"
        echo "  -t <BedrockGitTag>      Bedrock git CommitHash eg: 2015_09_08"
        echo "  -m <BedrockInstance>    Eg Bedrock_mv1_first, Bedrock_mv1_second"
        echo "  -p <BedrockPort>        Eg 8088, 8089"
        exit 1
}


mkdir -p /home/$USER/Bedrock
BedrockBaseDir="/home/$USER/Bedrock"

installTestingCode(){
echo "................................installing Bedrock test code......................................."
			
echo "Bedrock dir will be test_mv1_$BedrockInstance"
if [ ! -d $BedrockBaseDir/test_mv1_$BedrockInstance ]; then
	rm -rf $BedrockBaseDir/test_mv1_$BedrockInstance
fi
git -C $BedrockBaseDir clone -b mcom-mv1-dec16 --single-branch git@github.com:adini121/mcom-tests.git test_mv1_$BedrockInstance
}

gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
echo "Current Time : $currentTime"
REPORTS_DIR="/home/$USER/Dropbox/TestResults/Bedrock"
echo "Reports directory is: "$REPORTS_DIR" "
if [ ! -f $REPORTS_DIR/"$currentTime"_BedrockTests_mv1_"$BedrockGitTag".log ];then
	touch $REPORTS_DIR/"$currentTime"_BedrockTests_mv1_"$BedrockGitTag".log
fi

if [ ! -f $REPORTS_DIR/"$currentTime"_BedrockBrowserIdList_mv1_"$BedrockGitTag".log ];then
    touch $REPORTS_DIR/"$currentTime"_BedrockBrowserIdList_mv1_"$BedrockGitTag".log
fi
}

configureBedrockTests(){
mysql -u root << EOF
use bedrock_sessionIDs;
DROP TABLE IF EXISTS sessionids_mv1_$BedrockGitTag;
EOF
sed -i 's|test_session_ids|sessionids_mv1_'$BedrockGitTag'|g' $BedrockBaseDir/test_mv1_$BedrockInstance/conftest.py
sed -i 's|/home/adi/python.txt|'$REPORTS_DIR'/'$currentTime'_BedrockBrowserIdList_mv1_'$BedrockGitTag'.log|g' $BedrockBaseDir/test_mv1_$BedrockInstance/conftest.py
}

configureVirtualenv(){
cd $BedrockBaseDir/test_mv1_$BedrockInstance
echo "................................configuring Bedrock Virtualenv......................................."
pip install virtualenv
virtualenv $BedrockInstance
source $BedrockInstance/bin/activate
pip install -r requirements.txt
pip install MySQL-python
sleep 2
}

runBedrocktests(){
	#export DISPLAY=:0.0
	py.test -r=fsxXR --verbose --baseurl=http://134.96.235.47:$BedrockPort --host 134.96.235.159 --port 1235 --browsername=firefox --capability=browser:FIREFOX_30_WINDOWS_8_64 --capability=apikey:c717c5b3-a307-461e-84ea-1232d44cde89 --capability=email:test@testfabrik.com --capability=record:true --capability=extract:true --credentials=credentials.yaml --platform=MAC --destructive tests/. 2>&1 | tee $REPORTS_DIR/"$currentTime"_BedrockTests_mv1_"$BedrockGitTag".log
}


while getopts ":u:t:m:p:" i; do
    case "${i}" in
        u) USER=${OPTARG}
        ;;
        t) BedrockGitTag=${OPTARG}
        ;;
        m) BedrockInstance=${OPTARG}
        ;;
        p) BedrockPort=${OPTARG}
    esac
done

shift $((OPTIND - 1))

if [[ $USER == "" || $BedrockGitTag == "" || $BedrockInstance == "" || $BedrockPort == "" ]]; then
        usage
fi

#..........................................function calls...................................

installTestingCode

gatherTestReports

configureBedrockTests

configureVirtualenv

runBedrocktests
