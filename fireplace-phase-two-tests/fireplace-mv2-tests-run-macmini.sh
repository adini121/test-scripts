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
        echo "  -c <CommitHash>     	  Fireplace tests CommitHash"               
        exit 1
}

mkdir -p /home/$USER/Fireplace
FireplaceBaseDir="/home/$USER/Fireplace"

installTestingCode(){
echo "................................installing Fireplace test code......................................."

echo "Fireplace dir will be phase_two_test_mv2_$FireplaceInstance"
if [ -d $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance ]; then
	rm -rf $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance
fi
git -C $FireplaceBaseDir clone -b master --single-branch git@github.com:adini121/marketplace-tests.git phase_two_test_mv2_$FireplaceInstance  
git -C $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance checkout $CommitHash
git -C $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance checkout -b testing-branch
}

gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
echo "Current Time : $currentTime"
REPORTS_DIR="/home/$USER/Dropbox/PhaseTwoTestResults/Marketplace"
echo "Reports directory is: "$REPORTS_DIR" "
if [ ! -f $REPORTS_DIR/fireplaceTests_mv2_"$FireplaceGitTag".log ];then
	touch $REPORTS_DIR/fireplaceTests_mv2_"$FireplaceGitTag".log
fi

if [ ! -f $REPORTS_DIR/Fireplace_BrowserIdList_mv2_"$FireplaceGitTag".log ];then
    touch $REPORTS_DIR/Fireplace_BrowserIdList_mv2_"$FireplaceGitTag".log
fi
}

configureFireplaceTests(){
mysql -u root << EOF
use phase_two_fireplace_sids;
DROP TABLE IF EXISTS sessionids_mv2_$FireplaceGitTag;
EOF
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
touch $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance/dbconftest.py
chmod 755 $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance/dbconftest.py 
cat > $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance/dbconftest.py << EOF

""" Print sessionID to database and file """
import MySQLdb
import pytest
from time import gmtime, strftime
@pytest.fixture(autouse=True)
def session_id(mozwebqa):
    print 'Session ID: {}'.format(mozwebqa.selenium.session_id)
    str = '{}\n'.format(mozwebqa.selenium.session_id)
    str_session_id = '{}'.format(mozwebqa.selenium.session_id)

    with open ("/home/nisal/python.txt", "a") as myfile:
        myfile.write(str)

    current_time = strftime("%Y-%m-%d %H:%M")
    print('Current time is: {}'.format(current_time))
    """ Connect to MySQL database """
    try:
        conn = MySQLdb.connect(host='localhost',
                               user='root',
                               passwd='',
                               db='phase_two_fireplace_sids')

        c = conn.cursor()
        tblQuery = """CREATE TABLE IF NOT EXISTS test_session_ids (id int unsigned auto_increment not NULL,
            session_id VARCHAR(60) not NULL,
            date_created VARCHAR(100) not NULL,
            primary key(id))"""
        c.execute(tblQuery)
        print('............Successfully created table .......')
        insQuery = """insert into test_session_ids (session_id, date_created) values ('%s', '%s')"""
        c = conn.cursor()
        c.execute("insert into test_session_ids (session_id, date_created) values (%s, %s)", (str_session_id, current_time))
        print('............Successfully ADDED to table .......')
        conn.commit()
    except:
        print ('UNABLE TO PERFORM DATABASE OPERATION')

    finally:
        conn.close()
EOF
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
sleep 2
cat $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance/dbconftest.py >> $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance/conftest.py
sleep 2
sed -i 's|test_session_ids|sessionids_mv2_'$FireplaceGitTag'|g' $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance/conftest.py
sed -i 's|/home/nisal/python.txt|'$REPORTS_DIR'/Fireplace_BrowserIdList_mv2_'$FireplaceGitTag'.log|g' $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance/conftest.py
cp $CURRENT_DIR/credentials.yaml $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance/credentials.yaml
}

configureVirtualenv(){
echo "................................configuring Fireplace Virtualenv......................................."
cd $FireplaceBaseDir/phase_two_test_mv2_$FireplaceInstance
pip install virtualenv
virtualenv $FireplaceInstance
source $FireplaceInstance/bin/activate
pip install -r requirements.txt
pip install MySQL-python
sleep 2
}

runFireplacetests(){
py.test  -r=fsxXR --verbose --baseurl=http://134.96.235.47:$FireplacePort --host 134.96.235.159 --port 1235 \
--browsername=firefox --capability=browser:FIREFOX_30_WINDOWS_8_64 --capability=email:test@testfabrik.com \
--capability=record:true --capability=extract:false --capability=apikey:c717c5b3-a307-461e-84ea-1232d44cde89 \
--platform=MAC --destructive \
tests/desktop/consumer_pages/test_home_page.py \
tests/desktop/consumer_pages/test_details_page.py \
tests/desktop/consumer_pages/test_search.py \
2>&1 | tee $REPORTS_DIR/FireplaceTests_mv2_"$FireplaceGitTag".log
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
