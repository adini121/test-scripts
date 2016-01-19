

""" Print sessionID to database and file """
import MySQLdb
from time import gmtime, strftime
current_time = strftime("%Y-%m-%d %H:%M")
    print('Current time is: {}'.format(current_time))
    """ Connect to MySQL database """
    try:
        conn = MySQLdb.connect(host='localhost',
                               user='root',
                               passwd='',
                               db='amo_sessionIDs')

        c = conn.cursor()
        tblQuery = """CREATE TABLE IF NOT EXISTS test_session_ids (id int unsigned auto_increment not NULL,
            session_id VARCHAR(60) not NULL,
            date_created VARCHAR(100) not NULL,
            primary key(id))"""
        c.execute(tblQuery)
        print('............Successfully created table .......')
        insQuery = """insert into test_session_ids (session_id, date_created) values ('%s', '%s')"""
        # insQuery = """insert into test_session_ids (session_id, date_created) values ('whatever', 'whatever')"""
        c = conn.cursor()
        c.execute("insert into test_session_ids (session_id, date_created) values (%s, %s)", (str_session_id, current_time))
        # c.execute(insQuery)
        print('............Successfully ADDED to table .......')
        conn.commit()
    except:
        print ('UNABLE TO PERFORM DATABASE OPERATION')

    finally:
        conn.close()