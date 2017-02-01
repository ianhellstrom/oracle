/**
 * Databaseline code repository
 *
 * Code for post: ETL: A Simple Package to Load Data from Views
 * Compatibility: Oracle Database 10g Release 1 and above
 * Base URL:      http://databaseline.wordpress.com
 * Post URL:      http://wp.me/p4zRKC-6F
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1 (in ERRORS)
 */

CREATE OR REPLACE VIEW etl_stats
AS
WITH stats AS
(
  SELECT
    load_owner
  , load_object
  , is_success
  , COUNT(*)                                                                                                    AS num_entries
  , CEIL(AVG(num_inserted))                                                                                     AS avg_num_rows_inserted
  , CEIL(AVG(num_deleted))                                                                                      AS avg_num_rows_deleted
  , ROUND(MIN(sql_utils.dts_to_sec(elapsed_time)),2)                                                            AS min_elapsed_time_sec
  , ROUND(AVG(sql_utils.dts_to_sec(elapsed_time)),2)                                                            AS avg_elapsed_time_sec
  , ROUND(MAX(sql_utils.dts_to_sec(elapsed_time)),2)                                                            AS max_elapsed_time_sec
  , ROUND(STDDEV(sql_utils.dts_to_sec(elapsed_time)),2)                                                         AS std_elapsed_time_sec
  , ROUND(AVG((num_inserted + num_deleted)/NULLIF(sql_utils.dts_to_sec(elapsed_time),0)),2)                     AS avg_rows_per_sec
  , ROUND(REGR_SLOPE(     sql_utils.dts_to_sec(elapsed_time), sql_utils.dts_to_sec(SYSTIMESTAMP-load_inst) ),2) AS elapsed_time_sec_slope
  , ROUND(REGR_INTERCEPT( sql_utils.dts_to_sec(elapsed_time), sql_utils.dts_to_sec(SYSTIMESTAMP-load_inst) ),2) AS elapsed_time_sec_intercept
  , ROUND(REGR_R2(        sql_utils.dts_to_sec(elapsed_time), sql_utils.dts_to_sec(SYSTIMESTAMP-load_inst) ),2) AS elapsed_time_sec_r2
  FROM
    etl_exec_log
  GROUP BY
    load_owner
  , load_object
  , is_success
)
SELECT 
  load_owner
, load_object
, is_success
, num_entries
, avg_num_rows_inserted
, avg_num_rows_deleted
, min_elapsed_time_sec
, avg_elapsed_time_sec
, max_elapsed_time_sec
, std_elapsed_time_sec
, CASE WHEN is_success = 'Y'
  THEN
    CASE WHEN elapsed_time_sec_intercept > 0
    THEN
      elapsed_time_sec_intercept
    ELSE
      avg_elapsed_time_sec
    END
  ELSE
    NULL
  END AS pred_exec_time_sec
, avg_rows_per_sec
FROM 
  stats
;

COMMENT ON TABLE etl_stats IS 'Holds statistics on successful executions from ETL_EXEC_LOG.';