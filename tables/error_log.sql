/**
 * Databaseline code repository
 *
 * Code for post: Searching The Oracle Data Dictionary
 *                Checking Data Type Consistency in Oracle
 * Compatibility: Oracle Database 10g Release 1 and above
 * Base URL:      https://databaseline.tech
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1
 */

CREATE TABLE error_log
(
   created_on   TIMESTAMP NOT NULL
 , created_by   VARCHAR2(100) NOT NULL
 , code         NUMBER NOT NULL
 , message      VARCHAR2(500)
 , description  VARCHAR2(2000)
 , call_stack   VARCHAR2(4000)
 , error_stack  VARCHAR2(4000)
 , error_trace  CLOB
 , session_id   NUMBER
 , session_user VARCHAR2(100)
 , application  VARCHAR2(100)
 , ip_address   VARCHAR2(100)
 , auth_method  VARCHAR2(100)
);

COMMENT ON TABLE error_log IS 'Holds a log of all unhandled run-time exceptions.';