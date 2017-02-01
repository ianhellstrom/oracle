/**
 * Databaseline code repository
 *
 * Code for post: Searching The Oracle Data Dictionary 
 *                Checking Data Type Consistency in Oracle
 * Compatibility: Oracle Database 12c Release 1 and above
 *                Oracle Database 10g Release 1 and above (with minor modifications)
 * Base URL:      http://databaseline.wordpress.com
 * Post URL:      http://wp.me/p4zRKC-2U
 *                http://wp.me/p4zRKC-42
 * Author:        Ian Hellström
 *
 * Notes:         Regular expressions are available from 10.1
 *                INDEX BY VARCHAR2 is available from 9.2
 *                CASE statements are available from 9.0
 *
 *                To save memory, especially with many users connected to the database, this package is defined as serially reusable, which 
 *                means that it can only be used from within pure PL/SQL code, not SQL statements. Functions that are used inside SQL 
 *                statements (e.g. custom conversions) need to be defined in a separate package: SQL_UTILS.
 */

CREATE OR REPLACE PACKAGE plsql_utils
AUTHID CURRENT_USER
AS
  PRAGMA SERIALLY_REUSABLE;

  gc_fetch_limit CONSTANT PLS_INTEGER := 100;

 PROCEDURE display
  (
    string_in     VARCHAR2 
  , indent_in     PLS_INTEGER := 0
  , new_line_in   BOOLEAN     := FALSE
  , max_width_in  PLS_INTEGER := 80 
  );
  
  PROCEDURE find_table 
  (
    cols_in       VARCHAR2
  , owner_in      type_defs.identifier_t           := NULL
  , prefix_in     type_defs.identifier_t           := NULL
  , tab_or_vw_in  all_tab_comments.table_type%TYPE := NULL
  );

  PROCEDURE exec_plsql ( code_in  VARCHAR2 );
 
  PROCEDURE exec_ddl ( code_in  VARCHAR2 );
  
  PROCEDURE exec_ddl ( code_in  CLOB );

  PROCEDURE drop_object
  (
    owner_in        type_defs.identifier_t
  , object_in       type_defs.identifier_t
  , object_type_in  VARCHAR2 := 'TABLE'
  );
  
  PROCEDURE fix_data_type_issues;

END plsql_utils;
