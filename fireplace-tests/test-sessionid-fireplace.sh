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
        echo "  -c <CommitHash>			  CommitHash"
        exit 1
}


mkdir -p /home/$USER/Fireplace
FireplaceBaseDir="/home/$USER/Fireplace"

installTestingCode(){
echo "................................installing Fireplace test code......................................."
			
	echo "Fireplace dir will be test_$FireplaceInstance"
		if [ ! -d $FireplaceBaseDir/test_$FireplaceInstance ]; then
			git -C $FireplaceBaseDir clone -b sessionid-file-db --single-branch git@github.com:adini121/marketplace-tests.git test_$FireplaceInstance
		fi
 	git -C $FireplaceBaseDir/test_$FireplaceInstance stash
	git -C $FireplaceBaseDir/test_$FireplaceInstance fetch
	git -C $FireplaceBaseDir/test_$FireplaceInstance submodule update --init
}

gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
echo "Current Time : $currentTime"
REPORTS_DIR="/home/$USER/Dropbox/TestResults/misc"
echo "Reports directory is: "$REPORTS_DIR" "
if [ ! -f $REPORTS_DIR/"$currentTime"_fireplaceTests_"$CommitHash"_"$FireplaceGitTag".log ];then
	touch $REPORTS_DIR/"$currentTime"_fireplaceTests_"$CommitHash"_"$FireplaceGitTag".log
fi
}

configureFireplaceTests(){
mysql -u root << EOF
use fireplace_sessionIDs;
DROP TABLE IF EXISTS sessionids_$FireplaceGitTag;
EOF
sed -i 's|test_session_ids|sessionids_'$FireplaceGitTag'|g' $FireplaceBaseDir/test_$FireplaceInstance/conftest.py
sed -i 's|/home/adi/python.txt|'$REPORTS_DIR'/'$currentTime'_BrowserIdList_'$FireplaceGitTag'.log|g' $FireplaceBaseDir/test_$FireplaceInstance/conftest.py
echo "................................configuring Fireplace test-properties......................................."
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cp $CURRENT_DIR/credentials.yaml $FireplaceBaseDir/test_$FireplaceInstance/credentials.yaml
}

configureVirtualenv(){
echo "................................configuring Fireplace Virtualenv......................................."
cd $FireplaceBaseDir/test_$FireplaceInstance
pip install virtualenv
virtualenv $FireplaceInstance
source $FireplaceInstance/bin/activate
pip install -r requirements.txt
pip install mysql-connector-python --allow-external mysql-connector-python
sleep 2
}

runFireplacetests(){
	#export DISPLAY=:0.0
	py.test -r=fsxXR --verbose --baseurl=http://134.96.78.140:$FireplacePort --driver=firefox --credentials=credentials.yaml --platform=linux --destructive tests/desktop/consumer_pages/ 2>&1 | tee $REPORTS_DIR/"$currentTime"_fireplaceTests_"$CommitHash"_"$FireplaceGitTag".log
}


while getopts ":u:t:m:p:c:" i; do
    case "${i}" in
        u) USER=${OPTARG}
        ;;
        t) FireplaceGitTag=${OPTARG}
        ;;
        m) FireplaceInstance=${OPTARG}
        ;;
        p) FireplacePort=${OPTARG}
		;;
		c) CommitHash=${OPTARG}
    esac
done

shift $((OPTIND - 1))

if [[ $USER == "" || $FireplaceGitTag == "" || $FireplaceInstance == "" || $FireplacePort == "" || $CommitHash == "" ]]; then
        usage
fi

#..........................................function calls...................................

installTestingCode

gatherTestReports

configureFireplaceTests

configureVirtualenv

runFireplacetests
