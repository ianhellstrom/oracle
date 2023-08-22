/**
 * Code for post: ETL: A Simple Package to Load Data from Views
 * Compatibility: Oracle Database 10g Release 1 and above
 *                Oracle Database 9i Release 1 and above (with minor modifications)
 * Base URL:      https://ianhellstrom.org
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1 (in ERRORS)
 *                CASE statements are available from 9.0
 */

CREATE OR REPLACE PACKAGE etl
AUTHID CURRENT_USER
AS
  PRAGMA SERIALLY_REUSABLE;

  PROCEDURE cleanup
  (
    own_in  VARCHAR2 := SYS_CONTEXT('USERENV','CURRENT_SCHEMA')
  , tab_in  VARCHAR2
  , col_in  VARCHAR2
  , days_in NUMBER   := 100
  );

  PROCEDURE load_tab_from_view
    (
      target_own_in   etl_conf.target_own%TYPE
    , target_obj_in   etl_conf.target_obj%TYPE
    );

  PROCEDURE load_all_tabs
  (
    category_in        etl_conf.load_category%TYPE := NULL
  , resume_load_at_in  etl_conf.load_order%TYPE    := NULL
  );

END etl;