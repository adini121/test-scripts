# /bin/sh

# Description: Selenium tests script for Fireplace
# Author: Aditya

usage(){
        echo "Usage: $0 <OPTIONS>"
        echo "Required options:"
        echo "  -u $USER                  user name"
        echo "  -t <FireplaceGitTag>      Fireplace git tag eg: 2015_09_08 | 2015_09_15 | 2015_09_22"
        echo "  -m <FireplaceInstance>    Eg Fireplace_first, Fireplace_second"
        echo "  -p <FireplacePort>        Eg 8088, 8089"
        exit 1
}


mkdir -p /home/$USER/Fireplace
FireplaceBaseDir="/home/$USER/Fireplace"

installTestingCode(){
echo "................................installing Fireplace test code......................................."
			
	echo "Fireplace dir will be test_mv1_$FireplaceInstance"
		if [ ! -d $FireplaceBaseDir/test_mv1_$FireplaceInstance ]; then
			rm -rf $FireplaceBaseDir/test_mv1_$FireplaceInstance
            git -C $FireplaceBaseDir clone -b fireplace-mv1 --single-branch git@github.com:adini121/marketplace-tests.git test_mv1_$FireplaceInstance
		else 
            git -C $FireplaceBaseDir clone -b fireplace-mv1 --single-branch git@github.com:adini121/marketplace-tests.git test_mv1_$FireplaceInstance
        fi    
 	git -C $FireplaceBaseDir/test_mv1_$FireplaceInstance stash
	git -C $FireplaceBaseDir/test_mv1_$FireplaceInstance fetch
	git -C $FireplaceBaseDir/test_mv1_$FireplaceInstance submodule update --init
	
}

gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
echo "Current Time : $currentTime"
REPORTS_DIR="/home/$USER/Dropbox/TestResults/Marketplace"
echo "Reports directory is: "$REPORTS_DIR" "
if [ ! -f $REPORTS_DIR/"$currentTime"_fireplaceTests_mv1_"$FireplaceGitTag".log ];then
	touch $REPORTS_DIR/"$currentTime"_fireplaceTests_mv1_"$FireplaceGitTag".log
fi

if [ ! -f $REPORTS_DIR/"$currentTime"_BrowserIdList_mv1_"$BedrockGitTag".log ];then
    touch $REPORTS_DIR/"$currentTime"_BrowserIdList_mv1_"$BedrockGitTag".log
fi
}

configureFireplaceTests(){
mysql -u root << EOF
use fireplace_sessionIDs;
DROP TABLE IF EXISTS sessionids_mv1_$FireplaceGitTag;
EOF
sed -i 's|test_session_ids|sessionids_mv1_'$FireplaceGitTag'|g' $FireplaceBaseDir/test_mv1_$FireplaceInstance/conftest.py
sed -i 's|/home/adi/python.txt|'$REPORTS_DIR'/'$currentTime'_BrowserIdList_mv1_'$FireplaceGitTag'.log|g' $FireplaceBaseDir/test_mv1_$FireplaceInstance/conftest.py

echo "................................configuring Fireplace test-properties......................................."
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cp $CURRENT_DIR/credentials.yaml $FireplaceBaseDir/test_mv1_$FireplaceInstance/credentials.yaml
}

configureVirtualenv(){
echo "................................configuring Fireplace Virtualenv......................................."
cd $FireplaceBaseDir/test_mv1_$FireplaceInstance
pip install virtualenv
virtualenv $FireplaceInstance
source $FireplaceInstance/bin/activate
pip install -r requirements.txt
pip install mysql-connector-python --allow-external mysql-connector-python
sleep 2
}

runFireplacetests(){
	#export DISPLAY=:0.0
	py.test -r=fsxXR --verbose --baseurl=http://134.96.235.47:$FireplacePort --host 134.96.235.159 --port 1235 --browsername=firefox --capability=browser:FIREFOX_30_WINDOWS_8_64 --capability=apikey:c717c5b3-a307-461e-84ea-1232d44cde89 --capability=email:test@testfabrik.com --capability=record:true --capability=extract:true --credentials=credentials.yaml --platform=MAC --destructive tests/desktop/consumer_pages/. 2>&1 | tee $REPORTS_DIR/"$currentTime"_fireplaceTests_mv1_"$FireplaceGitTag".log
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
    esac
done

shift $((OPTIND - 1))

if [[ $USER == "" || $FireplaceGitTag == "" || $FireplaceInstance == "" || $FireplacePort == "" ]]; then
        usage
fi

#..........................................function calls...................................

installTestingCode

gatherTestReports

configureFireplaceTests

configureVirtualenv

runFireplacetests
