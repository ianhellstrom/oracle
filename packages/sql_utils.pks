/**
 * Code for post: Checking Data Type Consistency in Oracle
 * Compatibility: Oracle Database 12c Release 1 and above
 *                Oracle Database 10g Release 1 and above (with minor modifications)
 * Base URL:      https://ianhellstrom.org
 * Author:        Ian Hellström
 *
 * Notes:         Extended data types (e.g. VARCHAR2) are available from 12.1
 *                PRAGMA UDF is available from 12.1
 *                Regular expressions are available from 10.1
 *
 *                RESULT_CACHE does not work in 11.2 for invoker-rights (IR) units (i.e. AUTHID CURRENT_USER).
 *                From 12c onwards, both IR and definer-rights (DR) units can use the result cache, but for IR
 *                units the result cache is user-specific.
 *                More information: http://www.oracle.com/technetwork/issue-archive/2013/13-sep/o53plsql-1999801.html.
 */

CREATE OR REPLACE PACKAGE sql_utils
AUTHID CURRENT_USER
AS
  FUNCTION default_schemas_regex
    RETURN type_defs.text_t
    DETERMINISTIC
    RESULT_CACHE;

  FUNCTION dts_to_sec
  (
    dts_in INTERVAL DAY TO SECOND
  )
    RETURN NUMBER
    DETERMINISTIC
    RESULT_CACHE;

  FUNCTION to_type_spec
  (
    data_type_in       all_tab_cols.data_type%TYPE
  , data_length_in     all_tab_cols.data_length%TYPE
  , data_precision_in  all_tab_cols.data_precision%TYPE
  , data_scale_in      all_tab_cols.data_scale%TYPE
  , char_used_in       all_tab_cols.char_used%TYPE
  )
    RETURN type_defs.spec_t
    DETERMINISTIC
    RESULT_CACHE;

END sql_utils;
