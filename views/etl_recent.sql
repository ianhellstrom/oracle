/**
 * Databaseline code repository
 *
 * Code for post: ETL: A Simple Package to Load Data from Views
 * Compatibility: Oracle Database 10g Release 1 and above
 * Base URL:      https://databaseline.bitbucket.io
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1 (in ERRORS)
 */

CREATE OR REPLACE VIEW etl_recent
AS
SELECT
  source_db
, source_own
, source_obj
, target_own
, target_obj
, load_order
, load_method
, load_category
, last_successful_load
, min_elapsed_time_sec
, max_elapsed_time_sec
, avg_elapsed_time_sec
, pred_exec_time_sec
, elapsed_time_sec#1
, elapsed_time_sec#2
, elapsed_time_sec#3
, elapsed_time_sec#4
, elapsed_time_sec#5
FROM
  (
    SELECT
      summ.source_db
    , summ.source_own
    , summ.source_obj
    , summ.target_own
    , summ.target_obj
    , summ.load_order
    , summ.load_method
    , summ.load_category
    , summ.avg_elapsed_time_sec
    , stat.pred_exec_time_sec
    , stat.min_elapsed_time_sec
    , stat.max_elapsed_time_sec
    , summ.last_successful_load
    , sql_utils.dts_to_sec(hist.elapsed_time) AS elapsed_time_sec
    , ROW_NUMBER() OVER ( PARTITION BY hist.load_owner, hist.load_object
                          ORDER BY hist.load_inst DESC ) AS rn
    FROM
      etl_exec_log hist
    INNER JOIN etl_hist summ
    ON
      hist.load_owner    = summ.target_own
    AND hist.load_object = summ.target_obj
    INNER JOIN etl_stats stat
    ON
      hist.load_owner = stat.load_owner
    AND hist.load_object = stat.load_object
    AND hist.is_success = stat.is_success
    WHERE
      hist.is_success = 'Y'
  )
  PIVOT
  (
    MAX(elapsed_time_sec)
    FOR rn IN (1 AS elapsed_time_sec#1,
               2 AS elapsed_time_sec#2,
               3 AS elapsed_time_sec#3,
               4 AS elapsed_time_sec#4,
               5 AS elapsed_time_sec#5)
  )
ORDER BY
  load_category
, load_order;

COMMENT ON TABLE etl_recent IS 'Holds the information on the last five successful executions from ETL_EXEC_LOG.';