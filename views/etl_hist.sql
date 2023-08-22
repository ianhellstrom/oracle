/**
 * Code for post: ETL: A Simple Package to Load Data from Views
 * Compatibility: Oracle Database 10g Release 1 and above
 * Base URL:      https://ianhellstrom.org
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1 (in ERRORS)
 */

CREATE OR REPLACE VIEW etl_hist
AS
  SELECT
    c.source_db
  , c.source_own
  , c.source_obj
  , c.target_own
  , c.target_obj
  , c.load_order
  , c.load_method
  , c.load_category
  , c.is_active
  , c.archive_col_name
  , c.archive_col_oper
  , c.archive_col_value
  , MAX(h.load_inst) AS last_successful_load
  , s.avg_elapsed_time_sec
  , s.pred_exec_time_sec
  , s.avg_num_rows_inserted
  , s.avg_num_rows_deleted
  , MAX(l.modified_on) AS last_conf_modification
  FROM
    etl_conf c
  LEFT JOIN etl_exec_log h
  ON
    c.target_own   = h.load_owner
  AND c.target_obj = h.load_object
  AND h.is_success = 'Y'
  LEFT JOIN etl_conf_log l
  ON
    c.target_own   = l.target_own
  AND c.target_obj = l.target_obj
  LEFT JOIN etl_stats s
  ON
    c.target_own = s.load_owner
  AND c.target_obj = s.load_object
  AND s.is_success = 'Y'
  GROUP BY
    c.source_db
  , c.source_own
  , c.source_obj
  , c.target_own
  , c.target_obj
  , c.load_order
  , c.load_method
  , c.load_category
  , c.is_active
  , c.archive_col_name
  , c.archive_col_oper
  , c.archive_col_value
  , s.avg_elapsed_time_sec
  , s.pred_exec_time_sec
  , s.avg_num_rows_inserted
  , s.avg_num_rows_deleted
  ORDER BY
    c.load_category
  , c.load_order;

COMMENT ON TABLE etl_hist IS 'Holds both basic information and aggregated statistics for successful entries in ETL_EXEC_LOG, sorted by category and sequence.';