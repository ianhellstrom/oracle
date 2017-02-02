/**
 * Databaseline code repository
 *
 * Code for post: How to Multiply Across a Hierarchy in Oracle
 * Compatibility: Oracle Database 12c Release 1
 * Base URL:      https://databaseline.bitbucket.io
 * Author:        Ian Hellström
 *
 * Notes:         PRAGMA UDF and WITH FUNCTION are available from 12.1.
 */

CREATE OR REPLACE FUNCTION eval
(
  expr_in IN VARCHAR2
)
  RETURN NUMBER
  AUTHID CURRENT_USER
  DETERMINISTIC
  RESULT_CACHE
AS
  PRAGMA UDF;
  v_res NUMBER;
BEGIN
  EXECUTE IMMEDIATE 'SELECT ' || expr_in || ' FROM DUAL' INTO v_res;
  RETURN v_res;
END eval;
