/**
 * Code for post: ETL: A Simple Package to Load Data from Views
 * Compatibility: Oracle Database 10g Release 1 and above
 * Base URL:      https://ianhellstrom.org
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1 (in ERRORS)
 */

CREATE
  TABLE etl_conf
  (
    source_db         VARCHAR2(30 BYTE)
  , source_own        VARCHAR2(30 BYTE) NOT NULL
  , source_obj        VARCHAR2(30 BYTE) NOT NULL
  , target_own        VARCHAR2(30 BYTE) NOT NULL
  , target_obj        VARCHAR2(30 BYTE) NOT NULL
  , load_order        NUMBER(4,0)       NOT NULL
  , load_method       CHAR(3 BYTE)      NOT NULL
  , load_category     VARCHAR2(10 BYTE) NOT NULL
  , is_active         CHAR(1 BYTE)      NOT NULL
  , archive_col_name  VARCHAR2(30 BYTE)
  , archive_col_oper  VARCHAR2(2 BYTE)
  , archive_col_value VARCHAR2(100 BYTE)
  , CONSTRAINT etl_conf_is_act_ck
      CHECK ( is_active IN ('Y','N') )
  , CONSTRAINT etl_conf_meth_ck
      CHECK ( load_method IN ('REF','APD') )
  , CONSTRAINT etl_conf_categ_ck
      CHECK ( load_category IN ('MASTER','SNAPSHOT','TRACE') )
  , CONSTRAINT etl_conf_arch_op_ck
      CHECK ( archive_col_oper IN ('<', '>', '<=', '>=', '<>') )
  , CONSTRAINT etl_conf_arch_ck
      CHECK ( (load_method = 'APD' AND archive_col_name IS NOT NULL AND archive_col_oper IS NOT NULL AND archive_col_value IS NOT NULL)
               OR
              (load_method = 'APD' AND archive_col_name IS NULL AND archive_col_oper IS NULL AND archive_col_value IS NULL)
               OR
              (load_method = 'REF' AND archive_col_name IS NULL AND archive_col_oper IS NULL AND archive_col_value IS NULL)
            )
  , CONSTRAINT etl_conf_pk
      PRIMARY KEY (target_own, target_obj)
  , CONSTRAINT etl_conf_meth_ord_un
      UNIQUE (load_method, load_order) DEFERRABLE INITIALLY DEFERRED
  );

COMMENT ON TABLE etl_conf IS 'Holds source/target (and archiving) configurations used by ETL package.';

COMMENT ON COLUMN etl_conf.source_db IS 'Database link of the source object, typically a view or table.';
COMMENT ON COLUMN etl_conf.source_own IS 'Owner (schema) of the source object, typically a view or table.';
COMMENT ON COLUMN etl_conf.source_obj IS 'Identifier of the source object, typically a view or table.';
COMMENT ON COLUMN etl_conf.target_own IS 'Owner (schema) of the target object, typically a table.';
COMMENT ON COLUMN etl_conf.target_obj IS 'Identifier of the target object, typically a table.';
COMMENT ON COLUMN etl_conf.load_order IS 'Order in which to load objects.';
COMMENT ON COLUMN etl_conf.load_method IS 'Whether the data needs to be appended (''APD'') or refreshed (''REF'').';
COMMENT ON COLUMN etl_conf.load_category IS 'Categorization of target objects; can be used to group configurations or schedule individual categories in sequence.';
COMMENT ON COLUMN etl_conf.is_active IS 'Whether the configuration listed is enabled (''Y'') or disabled (''N'').';
COMMENT ON COLUMN etl_conf.archive_col_name IS 'Name of the column that determines what data to archive/purge, only valid for APD.';
COMMENT ON COLUMN etl_conf.archive_col_oper IS 'Comparison operator that determines how the data is archived/purged (<, >, <=, >=, or <>), only valid for APD.';
COMMENT ON COLUMN etl_conf.archive_col_value IS 'Column value that determines what data to archive/purge, only valid for APD.';