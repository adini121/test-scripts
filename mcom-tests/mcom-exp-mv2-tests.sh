# /bin/sh

# Description: Selenium tests script for Bedrock
# Author: Aditya

usage(){
        echo "Usage: $0 <OPTIONS>"
        echo "Required options:"
        echo "_______________________________________"
        echo "________ I M P O R T A N T ____________"
        echo "__EXTRACT AND RECORD ARE TURNED OFF____"
        echo "__Run inside venv from home directory__"
        echo "_______________________________________"
        echo "  -u $USER                User name"
        echo "  -t <BedrockGitTag>      Bedrock git CommitHash eg: 2015.09.08 | 2015.09.15 | 2015.09.22"
        echo "  -m <BedrockInstance>    Eg Bedrock_exp_mv2_first, Bedrock_exp_mv2_second"
        echo "  -p <BedrockPort>        Eg 8088, 8089"
        echo "  -c <CommitHash>			Bedrock tests CommitHash"
        exit 1
}


mkdir -p /home/$USER/Bedrock
BedrockBaseDir="/home/$USER/Bedrock"

installTestingCode(){
echo "................................installing Bedrock test code......................................."
			
echo "Bedrock dir will be test_exp_mv2_$BedrockInstance"
if [ ! -d $BedrockBaseDir/test_exp_mv2_$BedrockInstance ]; then
	rm -rf $BedrockBaseDir/test_exp_mv2_$BedrockInstance
    git -C $BedrockBaseDir clone -b exp-formv2-may28 --single-branch git@github.com:adini121/mcom-tests.git test_exp_mv2_$BedrockInstance
else
    git -C $BedrockBaseDir clone -b exp-formv2-may28 --single-branch git@github.com:adini121/mcom-tests.git test_exp_mv2_$BedrockInstance
fi
}

gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
echo "Current Time : $currentTime"
REPORTS_DIR="/home/$USER/Dropbox/TestResults/Bedrock"
echo "Reports directory is: "$REPORTS_DIR" "
if [ ! -f $REPORTS_DIR/"$currentTime"_BedrockTests_exp_mv2_"$BedrockGitTag".log ];then
	touch $REPORTS_DIR/"$currentTime"_BedrockTests_exp_mv2_"$BedrockGitTag".log
fi

if [ ! -f $REPORTS_DIR/"$currentTime" "$BedrockGitTag".log ];then
    touch $REPORTS_DIR/"$currentTime"_BedrockBrowserIdList_exp_mv2_"$BedrockGitTag".log
fi
}

configureBedrockTests(){
mysql -u root << EOF
use bedrock_sessionIDs;
DROP TABLE IF EXISTS sessionids_exp_mv2_$BedrockGitTag;
EOF
sed -i 's|test_session_ids|sessionids_exp_mv2_'$BedrockGitTag'|g' $BedrockBaseDir/test_exp_mv2_$BedrockInstance/conftest.py
sed -i 's|/home/adi/python.txt|'$REPORTS_DIR'/'$currentTime'_BedrockBrowserIdList_exp_mv2_'$BedrockGitTag'.log|g' $BedrockBaseDir/test_exp_mv2_$BedrockInstance/conftest.py
}

configureVirtualenv(){
cd $BedrockBaseDir/test_exp_mv2_$BedrockInstance
echo "................................configuring Bedrock Virtualenv......................................."
pip install virtualenv
virtualenv $BedrockInstance
source $BedrockInstance/bin/activate
pip install -r requirements.txt
pip install mysql-connector-python --allow-external mysql-connector-python
sleep 2
}

runBedrocktests(){
	#export DISPLAY=:0.0
	py.test -r=fsxXR --verbose --baseurl=http://134.96.235.47:$BedrockPort --host 134.96.235.159 --port 1235 --browsername=firefox --capability=browser:FIREFOX_30_WINDOWS_8_64 --capability=apikey:c717c5b3-a307-461e-84ea-1232d44cde89 --capability=email:test@testfabrik.com --capability=record:false --capability=extract:false --credentials=credentials.yaml --platform=MAC --destructive tests/. 2>&1 | tee $REPORTS_DIR/"$currentTime"_BedrockTests_exp_mv2_"$BedrockGitTag".log
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
