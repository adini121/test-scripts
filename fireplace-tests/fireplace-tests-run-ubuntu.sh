# /bin/sh

# Description: Selenium tests script for Fireplace
# Author: Aditya

usage(){
        echo "Usage: $0 <OPTIONS>"
        echo "Required options:"
        echo "  -u $USER                  user name"
        echo "  -t <FireplaceGitTag>      Fireplace git tag eg: 2015.09.08 | 2015.09.15 | 2015.09.22"
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
			git -C $FireplaceBaseDir clone --recursive https://github.com/mozilla/marketplace-tests test_$FireplaceInstance
		fi
 	git -C $FireplaceBaseDir/test_$FireplaceInstance stash
	git -C $FireplaceBaseDir/test_$FireplaceInstance fetch
	git -C $FireplaceBaseDir/test_$FireplaceInstance submodule update --init
	git -C $FireplaceBaseDir/test_$FireplaceInstance checkout $CommitHash
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
sleep 2
}

runFireplacetests(){
	#export DISPLAY=:0.0
	py.test -r=fsxXR --verbose --baseurl=http://37.230.7.66:$FireplacePort --driver=firefox --credentials=credentials.yaml --platform=linux --destructive tests/desktop/consumer_pages/ 2>&1 | tee $REPORTS_DIR/"$currentTime"_fireplaceTests_"$CommitHash"_"$FireplaceGitTag".log
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
