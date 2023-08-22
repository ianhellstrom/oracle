/**
 * Code for post: Searching The Oracle Data Dictionary
 *                Checking Data Type Consistency in Oracle
 *                ETL: A Simple Package to Load Data from Views
 * Compatibility: Oracle Database 10g Release 1 and above
 * Base URL:      https://ianhellstrom.org
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1
 */

CREATE OR REPLACE PACKAGE errors
AUTHID CURRENT_USER
AS
  PRAGMA SERIALLY_REUSABLE;

  /** Exception definitions and error handling.
  * @headcom
  */
  -- Can be either PROD or DEV, which affects logging of exceptions.
  g_env CHAR(4) := 'DEV';

  ex_invalid_sql_name           EXCEPTION;

  ex_empty_string_specified     EXCEPTION;
  ex_double_quotes_do_not_match EXCEPTION;
  ex_invalid_identifier         EXCEPTION;
  ex_incorrect_data_type        EXCEPTION;
  ex_indentation_overflow       EXCEPTION;
  ex_invalid_object             EXCEPTION;
  ex_no_pk_found                EXCEPTION;
  ex_redef_copy_dependents      EXCEPTION;
  ex_table_unredefinable        EXCEPTION;
  ex_invalid_value              EXCEPTION;
  ex_invalid_db_link            EXCEPTION;
  ex_invalid_tns_name           EXCEPTION;
  ex_invalid_tab_name           EXCEPTION;
  ex_invalid_col_name           EXCEPTION;
  ex_unrecompilable             EXCEPTION;

  -- Oracle exceptions numbers with names.
  en_invalid_sql_name CONSTANT INTEGER := -44003;
  PRAGMA EXCEPTION_INIT( ex_invalid_sql_name, -44003 );

  -- Custom exceptions numbers (between -20999 and -20005) with names.
  en_empty_string_specified CONSTANT INTEGER := -20999;
  PRAGMA EXCEPTION_INIT( ex_empty_string_specified, -20999 );

  en_double_quotes_do_not_match CONSTANT INTEGER := -20998;
  PRAGMA EXCEPTION_INIT( ex_double_quotes_do_not_match, -20998 );

  en_invalid_identifier CONSTANT INTEGER := -20997;
  PRAGMA EXCEPTION_INIT( ex_invalid_identifier, -20997 );

  en_incorrect_data_type CONSTANT INTEGER := -20996;
  PRAGMA EXCEPTION_INIT( ex_incorrect_data_type, -20996 );

  en_indentation_overflow CONSTANT INTEGER := -20995;
  PRAGMA EXCEPTION_INIT( ex_indentation_overflow, -20995 );

  en_invalid_object CONSTANT INTEGER := -20994;
  PRAGMA EXCEPTION_INIT( ex_invalid_object, -20994 );

  en_no_pk_found CONSTANT INTEGER := -20993;
  PRAGMA EXCEPTION_INIT( ex_no_pk_found, -20993 );

  en_redef_copy_dependents CONSTANT INTEGER := -20992;
  PRAGMA EXCEPTION_INIT( ex_redef_copy_dependents, -20992 );

  en_table_unredefinable CONSTANT INTEGER := -20991;
  PRAGMA EXCEPTION_INIT( ex_table_unredefinable, -20991);

  en_invalid_value CONSTANT INTEGER := -20990;
  PRAGMA EXCEPTION_INIT( ex_invalid_value, -20990);

  en_invalid_db_link CONSTANT INTEGER := -20989;
  PRAGMA EXCEPTION_INIT( ex_invalid_db_link, -20989);

  en_invalid_tns_name CONSTANT INTEGER := -20988;
  PRAGMA EXCEPTION_INIT( ex_invalid_tns_name, -20988);

  en_invalid_tab_name CONSTANT INTEGER := -20987;
  PRAGMA EXCEPTION_INIT( ex_invalid_tab_name, -20987);

  en_invalid_col_name CONSTANT INTEGER := -20986;
  PRAGMA EXCEPTION_INIT( ex_invalid_col_name, -20986);

  en_unrecompilable CONSTANT INTEGER := -20985;
  PRAGMA EXCEPTION_INIT( ex_unrecompilable, -20985);

  PROCEDURE log_and_stop
  (
    code_in INTEGER  := SQLCODE
  , desc_in VARCHAR2 := NULL
  );

  PROCEDURE log_and_continue
  (
    code_in INTEGER  := SQLCODE
  , desc_in VARCHAR2 := NULL
  );

END errors;
