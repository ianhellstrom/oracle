/**
 * Databaseline code repository
 *
 * Code for post: Checking Data Type Consistency in Oracle
 * Compatibility: Oracle Database 12c Release 1 and above
 *                Oracle Database 10g Release 1 and above (with minor modifications)
 * Base URL:      https://databaseline.tech
 * Author:        Ian Hellström
 *
 * Notes:         Regular expressions are available from 10.1
 */

CREATE OR REPLACE VIEW data_type_issues
AS
WITH
  tab_cols AS
  (
    SELECT
      atc.owner
    , atc.table_name
    , atc.column_name
    , atc.data_type
    , atc.data_length
    , atc.data_precision
    , atc.data_scale
    , atc.char_used
    , sql_utils.to_type_spec( atc.data_type, atc.data_length,
                              atc.data_precision, atc.data_scale, atc.char_used )                         AS full_data_type
    , COUNT(DISTINCT atc.table_name)
        OVER ( PARTITION BY atc.column_name,
                            sql_utils.to_type_spec( atc.data_type, atc.data_length,
                                                    atc.data_precision, atc.data_scale, atc.char_used ) ) AS num_tabs
    , COUNT(DISTINCT sql_utils.to_type_spec( atc.data_type, atc.data_length,
                                             atc.data_precision, atc.data_scale, atc.char_used ))
        OVER (PARTITION BY atc.column_name)                                                               AS num_types
    FROM
      all_tab_cols atc
    INNER JOIN
      all_objects ao
    ON
      atc.owner = ao.owner
    AND atc.table_name = ao.object_name
    WHERE
      NOT REGEXP_LIKE(atc.owner,sql_utils.default_schemas_regex())
      AND object_type LIKE 'TABLE%'
  )
, filtered_tab_cols AS
  (
    SELECT
      MIN(tc.owner)
        KEEP (DENSE_RANK FIRST ORDER BY tc.num_tabs DESC, tc.owner, tc.table_name) AS owner
    , MIN(tc.table_name)
        KEEP (DENSE_RANK FIRST ORDER BY tc.num_tabs DESC, tc.owner, tc.table_name) AS table_name
    , tc.column_name
    , tc.data_type
    , tc.data_length
    , tc.data_precision
    , tc.data_scale
    , tc.char_used
    , tc.full_data_type
    , tc.num_tabs
    , tc.num_types
    FROM
      tab_cols tc
    WHERE
      tc.num_types > 1
    GROUP BY
      tc.column_name
    , tc.data_type
    , tc.data_length
    , tc.data_precision
    , tc.data_scale
    , tc.char_used
    , tc.full_data_type
    , tc.num_tabs
    , tc.num_types
  )
SELECT
  ftc.column_name     AS column_name
, ftc.owner           AS owner
, ftc.table_name      AS table_name
, ftc.full_data_type  AS full_data_type
, ftc.data_type       AS data_type
, ftc.data_length     AS data_length
, ftc.data_precision  AS data_precision
, ftc.data_scale      AS data_scale
, ftc.char_used       AS char_used
, ftc.num_tabs        AS num_tabs
, aftc.owner          AS alt_owner
, aftc.table_name     AS alt_table_name
, aftc.full_data_type AS alt_full_data_type
, aftc.data_type      AS alt_data_type
, aftc.data_length    AS alt_data_length
, aftc.data_precision AS alt_data_precision
, aftc.data_scale     AS alt_data_scale
, aftc.char_used      AS alt_char_used
, aftc.num_tabs       AS alt_num_tabs
FROM
  filtered_tab_cols ftc
INNER JOIN filtered_tab_cols aftc
ON
  ftc.column_name = aftc.column_name
AND
  (
    ftc.num_tabs > aftc.num_tabs
    OR
    (
      ftc.num_tabs = aftc.num_tabs
      AND ftc.table_name < aftc.table_name
    )
  );

COMMENT ON TABLE data_type_issues IS 'Holds all potential data type mismatches with occurrences.'