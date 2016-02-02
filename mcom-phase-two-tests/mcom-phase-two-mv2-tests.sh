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
        echo "  -m <BedrockInstance>    Eg Bedrock_mv2_first, Bedrock_mv2_second"
        echo "  -p <BedrockPort>        Eg 8088, 8089"
        echo "  -c <CommitHash>         Bedrock tests CommitHash"               
        exit 1
}


mkdir -p /home/$USER/Bedrock
BedrockBaseDir="/home/$USER/Bedrock"

installTestingCode(){
echo "................................installing Bedrock test code......................................."
echo " "
echo "Bedrock dir will be test_mv2_phase2_$BedrockInstance"
if [ -d $BedrockBaseDir/test_mv2_phase2_$BedrockInstance ]; then
	rm -rf $BedrockBaseDir/test_mv2_phase2_$BedrockInstance
fi
git -C $BedrockBaseDir clone -b master --single-branch git@github.com:adini121/mcom-tests.git test_mv2_phase2_$BedrockInstance
git -C $BedrockBaseDir/test_mv2_phase2_$BedrockInstance checkout $CommitHash
git -C $BedrockBaseDir/test_mv2_phase2_$BedrockInstance checkout -b testing-branch
}

checkConftestPresence(){
if [ ! -f $BedrockBaseDir/test_mv2_phase2_$BedrockInstance/conftest.py ];then
    touch $BedrockBaseDir/test_mv2_phase2_$BedrockInstance/conftest.py
    chmod 755 $BedrockBaseDir/test_mv2_phase2_$BedrockInstance/conftest.py
fi
}
gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
echo "Current Time : $currentTime"
REPORTS_DIR="/home/$USER/Dropbox/PhaseTwoTestResults/Bedrock"
echo "Reports directory is: "$REPORTS_DIR" "
if [ ! -f $REPORTS_DIR/Phase2_BedrockTests_mv2_"$BedrockGitTag".log ];then
	touch $REPORTS_DIR/Phase2_BedrockTests_mv2_"$BedrockGitTag".log
fi

if [ ! -f $REPORTS_DIR/Phase2_BedrockBrowserIdList_mv2_"$BedrockGitTag".log ];then
    touch $REPORTS_DIR/Phase2_BedrockBrowserIdList_mv2_"$BedrockGitTag".log
fi
}

configureBedrockTests(){
mysql -u root << EOF
use phase_two_bedrock_sids;
DROP TABLE IF EXISTS sessionids_mv2_$BedrockGitTag;
EOF
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
touch $BedrockBaseDir/test_mv2_phase2_$BedrockInstance/dbconftest.py
chmod 755 $BedrockBaseDir/test_mv2_phase2_$BedrockInstance/dbconftest.py
cat > $BedrockBaseDir/test_mv2_phase2_$BedrockInstance/dbconftest.py << EOF

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
                               db='phase_two_bedrock_sids')

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
cat $BedrockBaseDir/test_mv2_phase2_$BedrockInstance/dbconftest.py >> $BedrockBaseDir/test_mv2_phase2_$BedrockInstance/conftest.py
sleep 2
sed -i 's|test_session_ids|sessionids_mv2_'$BedrockGitTag'|g' $BedrockBaseDir/test_mv2_phase2_$BedrockInstance/conftest.py
sed -i 's|/home/nisal/python.txt|'$REPORTS_DIR'/Phase2_BedrockBrowserIdList_mv2_'$BedrockGitTag'.log|g' $BedrockBaseDir/test_mv2_phase2_$BedrockInstance/conftest.py
}

configureVirtualenv(){
cd $BedrockBaseDir/test_mv2_phase2_$BedrockInstance
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
py.test -r=fsxXR --verbose --baseurl=http://134.96.235.47:$BedrockPort --host 134.96.235.159 \
--port 1235 --browsername=firefox --capability=browser:FIREFOX_30_WINDOWS_8_64 \
--capability=apikey:c717c5b3-a307-461e-84ea-1232d44cde89 --capability=email:test@testfabrik.com \
--capability=record:true --capability=extract:false \
--platform=MAC --destructive \
tests/test_about.py::TestAboutPage::test_footer_link_destinations_are_correct
tests/test_about.py::TestAboutPage::test_footer_links_are_valid
tests/test_about.py::TestAboutPage::test_tabzilla_link_destinations_are_correct
tests/test_about.py::TestAboutPage::test_tabzilla_links_are_visible
tests/test_about.py::TestAboutPage::test_navbar_links_are_visible
tests/test_about.py::TestAboutPage::test_navbar_link_destinations_are_correct
tests/test_about.py::TestAboutPage::test_navbar_link_urls_are_valid
tests/test_about.py::TestAboutPage::test_major_link_destinations_are_correct
tests/test_about.py::TestAboutPage::test_major_link_urls_are_valid
tests/test_about.py::TestAboutPage::test_sign_up_form_is_visible
tests/test_about.py::TestAboutPage::test_sign_up_form_fields_are_visible
tests/test_about.py::TestAboutPage::test_sign_up_form_links_are_visible
tests/test_about.py::TestAboutPage::test_sign_up_form_link_destinations_are_correct
tests/test_about.py::TestAboutPage::test_sign_up_form_link_urls_are_valid
tests/test_about.py::TestAboutPage::test_sign_up_form_elements_are_visible
tests/test_about.py::TestAboutPage::test_sign_up_form_invalid_email
tests/test_about.py::TestAboutPage::test_sign_up_form_privacy_policy_unchecked
tests/test_contact.py::TestContact::test_spaces_links_are_correct
tests/test_contact.py::TestContact::test_start_on_spaces
tests/test_contact.py::TestContact::test_switching_tabs_list_display
tests/test_contact.py::TestContact::test_region_links_are_correct
tests/test_contribute.py::TestContribute::test_tabzilla_links_are_correct
tests/test_contribute.py::TestContribute::test_major_link_destinations_are_correct
tests/test_contribute.py::TestContribute::test_major_link_urls_are_valid
tests/test_contribute.py::TestContribute::test_sign_up_form_fields_are_visible
tests/test_contribute.py::TestContribute::test_sign_up_form_is_visible
tests/test_home.py::TestHomePage::test_major_link_urls_are_valid
tests/test_home.py::TestHomePage::test_major_link_destinations_are_correct
tests/test_home.py::TestHomePage::test_footer_links_are_valid
tests/test_home.py::TestHomePage::test_sign_up_form_is_visible
tests/test_home.py::TestHomePage::test_sign_up_form_link_destinations_are_correct
tests/test_home.py::TestHomePage::test_sign_up_form_link_urls_are_valid
tests/test_mission.py::TestMission::test_major_link_destinations_are_correct
tests/test_mission.py::TestMission::test_video_srcs_are_valid
tests/test_mission.py::TestMission::test_tabzilla_links_are_correct
tests/test_mozillabased.py::TestMozillaBasedPagePage::test_breadcrumbs_link_destinations_are_correct
tests/test_mozillabased.py::TestMozillaBasedPagePage::test_breadcrumbs_link_urls_are_valid
tests/test_mozillabased.py::TestMozillaBasedPagePage::test_main_feature_link_destinations_are_correct
tests/test_mozillabased.py::TestMozillaBasedPagePage::test_featured_billboard_images_links_are_correct
tests/test_mozillabased.py::TestMozillaBasedPagePage::test_featured_images_links_are_correct
tests/test_mozillabased.py::TestMozillaBasedPagePage::test_tabzilla_links_are_correct
tests/test_mozillabased.py::TestMozillaBasedPagePage::test_tabzilla_links_are_visible
tests/test_mozillabased.py::TestMozillaBasedPagePage::test_navbar_links_are_visible
tests/test_nightlyfirstrun.py::TestNightlyFirstRun::test_footer_links_are_valid
tests/test_nightlyfirstrun.py::TestNightlyFirstRun::test_tabzilla_link_destinations_are_correct
tests/test_nightlyfirstrun.py::TestNightlyFirstRun::test_tabzilla_links_are_visible
tests/test_nightlyfirstrun.py::TestNightlyFirstRun::test_are_sections_visible
tests/test_partners.py::TestPartners::test_overview_section_image
tests/test_partners.py::TestPartners::test_os_section
tests/test_partnerships.py::TestPartnerships::test_section_link_destinations_are_correct
tests/test_partnerships.py::TestPartnerships::test_section_link_urls_are_valid
tests/test_partnerships.py::TestPartnerships::test_image_srcs_are_correct
tests/test_partnerships.py::TestPartnerships::test_partner_form_is_visible
tests/test_privacy.py::TestPrivacy::test_tabzilla_links_are_correct
tests/test_privacy.py::TestPrivacy::test_page_sections
tests/test_projects.py::TestProjects::test_tabzilla_links_are_correct
tests/test_projects.py::TestProjects::test_billboard_link_destinations_are_correct
tests/test_projects.py::TestProjects::test_billboard_link_urls_are_valid
tests/test_projects.py::TestProjects::test_projects_link_destinations_are_correct
tests/test_sms.py::TestSMSPage::test_info_link_destinations_are_correct
tests/test_sms.py::TestSMSPage::test_tabzilla_links_are_correct
2>&1 | tee $REPORTS_DIR/Phase2_BedrockTests_mv2_"$BedrockGitTag".log
}


while getopts ":u:t:m:p:c:" i; do
    case "${i}" in
        u) USER=${OPTARG}
        ;;
        t) BedrockGitTag=${OPTARG}
        ;;
        m) BedrockInstance=${OPTARG}
        ;;
        p) BedrockPort=${OPTARG}
        ;;
        c) CommitHash=${OPTARG}
    esac
done

shift $((OPTIND - 1))

if [[ $USER == "" || $BedrockGitTag == "" || $BedrockInstance == "" || $BedrockPort == "" || $CommitHash == "" ]]; then
        usage
fi

#..........................................function calls...................................

installTestingCode

checkConftestPresence

gatherTestReports

configureBedrockTests

configureVirtualenv

runBedrocktests
