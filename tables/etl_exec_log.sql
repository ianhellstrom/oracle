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
  TABLE etl_exec_log
  (
    load_inst    TIMESTAMP (6) DEFAULT systimestamp
  , load_owner   VARCHAR2(30 byte) NOT NULL
  , load_object  VARCHAR2(30 byte) NOT NULL
  , num_inserted NUMBER(10,0) NOT NULL
  , num_deleted  NUMBER(10,0) NOT NULL
  , is_success   CHAR(1 byte) NOT NULL
  , elapsed_time INTERVAL DAY (2) TO SECOND (6)
  , CONSTRAINT etl_exec_log_succ_ck
      CHECK ( is_success IN ('Y','N') )
  , CONSTRAINT etl_exec_log_ins_ck
      CHECK (num_inserted >= 0)
  , CONSTRAINT etl_exec_log_del_ck
      CHECK (num_deleted  >= 0)
  , CONSTRAINT etl_exec_log_pk
      PRIMARY KEY (load_inst, load_owner, load_object)
  );

COMMENT ON TABLE etl_exec_log IS 'Holds historical trace of both successful and unsuccessful executions of ETL package procedures.';

COMMENT ON COLUMN etl_exec_log.load_owner IS 'Owner (schema) of the target object from ETL_CONF.';
COMMENT ON COLUMN etl_exec_log.load_object IS 'Target object from ETL_CONF.';
COMMENT ON COLUMN etl_exec_log.num_inserted IS 'Number of rows inserted into target object.';
COMMENT ON COLUMN etl_exec_log.num_deleted IS 'Number of rows deleted before the insert into target object; either all (''REF'') or based on the archive settings in ETL_CONF (''APD'').';
COMMENT ON COLUMN etl_exec_log.is_success IS 'Whether the load was successful (''Y'') or not (''N'').';
COMMENT ON COLUMN etl_exec_log.elapsed_time IS 'Time elapsed for the entire load of the target object from ETL_CONF.';
COMMENT ON COLUMN etl_exec_log.load_inst IS 'Time when load was recorded.';