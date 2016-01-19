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
	    echo "  -c <CommitHash>     AMO tests CommitHash"        
        exit 1
}
mkdir -p /home/$USER/AMOHome
AMOBaseDir="/home/$USER/AMOHome"

installTestingCode(){
echo "................................installing AMO test code......................................."
echo "AMO dir will be phase2_test_mv0_$AMOInstance"
if [ -d $AMOBaseDir/phase2_test_mv0_$AMOInstance ]; then
	rm -rf $AMOBaseDir/phase2_test_mv0_$AMOInstance phase2_test_mv0_$AMOInstance
fi
git -C $AMOBaseDir clone -b master --single-branch git@github.com:adini121/Addon-Tests.git phase2_test_mv0_$AMOInstance
git -C $AMOBaseDir/phase2_test_mv0_$AMOInstance checkout $CommitHash
git -C $AMOBaseDir/phase2_test_mv0_$AMOInstance checkout -b testing-branch 
}

gatherTestReports(){
currentTime=$(date "+%Y.%m.%d-%H.%M")
echo "Current Time : $currentTime"
REPORTS_DIR="/home/$USER/Dropbox/PhaseTwoTestResults/AMO"
echo "Reports directory is: "$REPORTS_DIR" "
if [ ! -f $REPORTS_DIR/AMOTests_mv0_"$AMOGitTag".log ];then
	touch $REPORTS_DIR/AMOTests_mv0_"$AMOGitTag".log
fi

if [ ! -f $REPORTS_DIR/AMO_BrowserIdList_mv0_"$AMOGitTag".log ];then
    touch $REPORTS_DIR/AMO_BrowserIdList_mv0_"$AMOGitTag".log
fi
}

configureAMOTests(){
echo "................................configuring AMO test-properties......................................."
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "CURRENT_DIR="$CURRENT_DIR""
mysql -u root << EOF
use phase_two_amo_sids;
DROP TABLE IF EXISTS sessionids_mv0_$AMOGitTag;
EOF
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
touch $AMOBaseDir/phase2_test_mv0_$AMOInstance/dbconftest.py
chmod 755 $AMOBaseDir/phase2_test_mv0_$AMOInstance/dbconftest.py 
cat > $AMOBaseDir/phase2_test_mv0_$AMOInstance/dbconftest.py << EOF

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
                               db='phase_two_amo_sids')

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
cat $AMOBaseDir/phase2_test_mv0_$AMOInstance/dbconftest.py >> $AMOBaseDir/phase2_test_mv0_$AMOInstance/conftest.py
sleep 2
sed -i 's|test_session_ids|sessionids_mv0_'$AMOGitTag'|g' $AMOBaseDir/phase2_test_mv0_$AMOInstance/conftest.py
sed -i 's|/home/nisal/python.txt|'$REPORTS_DIR'/AMO_BrowserIdList_mv0_'$AMOGitTag'.log|g' $AMOBaseDir/phase2_test_mv0_$AMOInstance/conftest.py
cp $CURRENT_DIR/credentials.yaml $AMOBaseDir/phase2_test_mv0_$AMOInstance/credentials.yaml
}

configureVirtualenv(){
echo "................................configuring AMO Virtualenv......................................."
cd $AMOBaseDir/phase2_test_mv0_$AMOInstance
pip install virtualenv
virtualenv $AMOInstance
source $AMOInstance/bin/activate
pip install -r requirements.txt
pip install MySQL-python
sleep 2
}

runAMOtests(){
py.test  -r=fsxXR --verbose --baseurl=http://134.96.235.47:$AMOPort --host 134.96.235.159 --port 1235 \
--browsername=firefox --capability=browser:FIREFOX_30_WINDOWS_8_64 --capability=email:test@testfabrik.com \
--capability=record:true --capability=extract:false --capability=apikey:c717c5b3-a307-461e-84ea-1232d44cde89 \
--credentials=credentials.yaml --platform=MAC --destructive \
tests/desktop/test_collections.py::TestCollections::test_featured_tab_is_highlighted_by_default \
tests/desktop/test_collections.py::TestCollections::test_create_and_delete_collection \
tests/desktop/test_collections.py::TestCollections::test_user_my_collections_page \
tests/desktop/test_complete_themes.py::TestCompleteThemes::test_that_complete_themes_loads_landing_page_correctly \
tests/desktop/test_complete_themes.py::TestCompleteThemes::test_that_complete_themes_page_has_correct_title \
tests/desktop/test_complete_themes.py::TestCompleteThemes::test_complete_themes_page_breadcrumb \
tests/desktop/test_complete_themes.py::TestCompleteThemes::test_that_complete_themes_categories_are_not_extensions_categories \
tests/desktop/test_complete_themes.py::TestCompleteThemes::test_the_displayed_message_for_incompatible_complete_themes \
tests/desktop/test_complete_themes.py::TestCompleteThemes::test_that_most_popular_link_is_default \
tests/desktop/test_complete_themes.py::TestCompleteThemes::test_sorted_by_most_users_is_default \
tests/desktop/test_extensions.py::TestExtensions::test_featured_tab_is_highlighted_by_default \
tests/desktop/test_extensions.py::TestExtensions::test_that_checks_if_the_extensions_are_sorted_by_top_rated \
tests/desktop/test_extensions.py::TestExtensions::test_that_checks_if_the_extensions_are_sorted_by_most_user \
tests/desktop/test_extensions.py::TestExtensions::test_that_extensions_are_sorted_by_up_and_coming \
tests/desktop/test_extensions.py::TestExtensions::test_that_extensions_page_contains_addons_and_the_pagination_works \
tests/desktop/test_extensions.py::TestExtensions::test_breadcrumb_menu_in_extensions_page \
tests/desktop/test_extensions.py::TestExtensions::test_that_checks_if_the_subscribe_link_exists \
tests/desktop/test_extensions.py::TestExtensions::test_that_checks_featured_extensions_header \
tests/desktop/test_homepage.py::TestHome::test_that_checks_the_most_popular_section_exists \
tests/desktop/test_homepage.py::TestHome::test_that_checks_the_promo_box_exists \
tests/desktop/test_homepage.py::TestHome::test_that_clicking_on_addon_name_loads_details_page \
tests/desktop/test_homepage.py::TestHome::test_that_extensions_link_loads_extensions_page \
tests/desktop/test_homepage.py::TestHome::test_that_most_popular_section_is_ordered_by_users \
tests/desktop/test_homepage.py::TestHome::test_that_featured_extensions_exist_on_the_home \
tests/desktop/test_homepage.py::TestHome::test_that_items_menu_fly_out_while_hovering \
tests/desktop/test_homepage.py::TestHome::test_that_clicking_top_rated_shows_addons_sorted_by_rating \
tests/desktop/test_homepage.py::TestHome::test_that_clicking_most_popular_shows_addons_sorted_by_users \
tests/desktop/test_homepage.py::TestHome::test_that_clicking_featured_shows_addons_sorted_by_featured \
tests/desktop/test_homepage.py::TestHome::test_header_site_navigation_menus_are_correct \
tests/desktop/test_homepage.py::TestHome::test_the_name_of_each_site_navigation_menu_in_the_header \
tests/desktop/test_homepage.py::TestHome::test_top_three_items_in_each_site_navigation_menu_are_featured \
tests/desktop/test_homepage.py::TestHome::test_addons_author_link \
tests/desktop/test_homepage.py::TestHome::test_that_checks_explore_side_navigation \
tests/desktop/test_homepage.py::TestHome::test_that_clicking_see_all_extensions_link_works \
tests/desktop/test_homepage.py::TestHome::test_that_checks_all_categories_side_navigation \
tests/desktop/test_homepage.py::TestHome::test_that_checks_other_applications_menu \
tests/desktop/test_layout.py::TestAmoLayout::test_other_applications_thunderbird \
tests/desktop/test_layout.py::TestAmoLayout::test_that_checks_amo_logo_text_layout_and_title \
tests/desktop/test_layout.py::TestAmoLayout::test_that_clicking_the_amo_logo_loads_home_page \
tests/desktop/test_layout.py::TestAmoLayout::test_that_other_applications_link_has_tooltip \
tests/desktop/test_layout.py::TestAmoLayout::test_the_applications_listed_in_other_applications[Thunderbird] \
tests/desktop/test_layout.py::TestAmoLayout::test_the_applications_listed_in_other_applications[Android] \
tests/desktop/test_layout.py::TestAmoLayout::test_the_applications_listed_in_other_applications[SeaMonkey] \
tests/desktop/test_layout.py::TestAmoLayout::test_the_search_field_placeholder_and_search_button \
tests/desktop/test_layout.py::TestAmoLayout::test_the_search_box_exist \
tests/desktop/test_search.py::TestSearch::test_that_page_with_search_results_has_correct_title \
tests/desktop/test_search.py::TestSearch::test_sorting_by_newest \
tests/desktop/test_search.py::TestSearch::test_sorting_by_number_of_most_users \
tests/desktop/test_themes.py::TestThemes::test_start_exploring_link_in_the_promo_box \
tests/desktop/test_themes.py::TestThemes::test_page_title_for_themes_landing_page \
tests/desktop/test_themes.py::TestThemes::test_the_featured_themes_section \
tests/desktop/test_themes.py::TestThemes::test_the_recently_added_section \
tests/desktop/test_themes.py::TestThemes::test_the_most_popular_section \
tests/desktop/test_themes.py::TestThemes::test_the_top_rated_section \
tests/desktop/test_themes.py::TestThemes::test_breadcrumb_menu_in_theme_details_page \
tests/desktop/test_themes.py::TestThemes::test_themes_breadcrumb_format \
tests/desktop/test_users_account.py::TestAccounts::test_user_can_login_and_logout_using_normal_login \
tests/desktop/test_users_account.py::TestAccounts::test_user_can_login_and_logout_using_browser_id \
tests/desktop/test_users_account.py::TestAccounts::test_user_can_access_the_edit_profile_page \
2>&1 | tee $REPORTS_DIR/AMOTests_mv0_"$AMOGitTag".log
}



while getopts ":u:t:m:p:c:" i; do
    case "${i}" in
        u) USER=${OPTARG}
        ;;
        t) AMOGitTag=${OPTARG}
        ;;
        m) AMOInstance=${OPTARG}
        ;;
        p) AMOPort=${OPTARG}
        ;;
        c) CommitHash=${OPTARG}
    esac
done

shift $((OPTIND - 1))

if [[ $USER == "" || $AMOGitTag == "" || $AMOInstance == "" || $AMOPort == "" || $CommitHash == "" ]]; then
        usage
fi

#..........................................function calls...................................

installTestingCode

gatherTestReports

configureAMOTests

configureVirtualenv

runAMOtests
