/**
 * Databaseline code repository
 *
 * Code for post: ETL: A Simple Package to Load Data from Views
 * Compatibility: Oracle Database 10g Release 1 and above
 * Base URL:      https://databaseline.tech
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1 (in ERRORS)
 */

 CREATE
  TABLE etl_conf_log
  (
    target_own        VARCHAR2(30 BYTE)
  , target_obj        VARCHAR2(30 BYTE)
  , modified_on       TIMESTAMP
  , modified_by       VARCHAR2(100 BYTE)
  , modified_through  VARCHAR2(100 BYTE)
  , modification_type VARCHAR2(10 BYTE)
  , modifications     VARCHAR2(4000 BYTE)
  , CONSTRAINT etl_conf_log_pk
      PRIMARY KEY (target_own, target_obj, modified_on, modified_by, modified_through, modification_type)
  , CONSTRAINT etl_conf_log_type_ck
      CHECK ( modification_type IN ('INSERT','UPDATE','DELETE') )
  );

COMMENT ON TABLE etl_conf_log IS 'Holds a log of all changes to ETL_CONF';

COMMENT ON COLUMN etl_conf_log.target_own IS 'Owner (schema) of the target object for which the entry was created, removed, or modified.';
COMMENT ON COLUMN etl_conf_log.target_obj IS 'Target object for which the entry was created, removed, or modified.';
COMMENT ON COLUMN etl_conf_log.modified_on IS 'Time the entry was created, removed, or modified.';
COMMENT ON COLUMN etl_conf_log.modified_by IS 'Database user and OS username of the person who created, removed, or modified the entry.';
COMMENT ON COLUMN etl_conf_log.modified_through IS 'Application through which the database was accessed to create, remove, or modify the entry.';
COMMENT ON COLUMN etl_conf_log.modification_TYPE IS 'Whether the alteration was an ''INSERT'', ''UPDATE'', or ''DELETE''.';
COMMENT ON COLUMN etl_conf_log.modifications IS 'Comma-separated list of modifcations performed for the entry.';