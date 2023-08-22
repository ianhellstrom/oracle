/**
 * Code for post: Searching The Oracle Data Dictionary
 *                Checking Data Type Consistency in Oracle
 * Compatibility: Oracle Database 10g Release 1 and above
 * Base URL:      https://ianhellstrom.org
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1
 */

CREATE OR REPLACE VIEW error_log_recent
AS
  SELECT
    *
  FROM
    error_log
  WHERE
    created_on >= SYSDATE - INTERVAL '1' HOUR
  ORDER BY
    created_on DESC;

COMMENT ON TABLE error_log_recent IS 'Holds ERROR_LOG entries from the last hour; useful for debugging.';