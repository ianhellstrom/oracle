/**
 * Databaseline code repository
 *
 * Code for post: How to Multiply Across a Hierarchy in Oracle
 * Compatibility: Oracle Database 12c Release 1
 * Base URL:      https://databaseline.tech
 * Author:        Ian Hellström
 *
 * Notes:         PRAGMA UDF and WITH FUNCTION are available from 12.1.
 */

CREATE OR REPLACE PROCEDURE prepare_table
(
  v_seed_in IN BINARY_INTEGER,
  v_rows_in IN NUMBER
)
AS
BEGIN
  DELETE FROM hierarchy_example;

  COMMIT;

  DBMS_RANDOM.SEED(v_seed_in);

  INSERT INTO hierarchy_example( id , prior_id , yield )
    WITH
      raw_data AS
      (
        SELECT
          ROWNUM                                          AS id
        , CEIL( v_rows_in * DBMS_RANDOM.VALUE )           AS prior_id
        , GREATEST( ROUND( DBMS_RANDOM.VALUE, 2 ), 0.01 ) AS yield -- ensure non-zero yield: LN(0) is undefined
        FROM
          DUAL
          CONNECT BY ROWNUM <= v_rows_in
      )
    SELECT id, prior_id, yield FROM raw_data;

  -- make cyclic references top-level entries in hierarchy
  UPDATE
    hierarchy_example
  SET
    prior_id = NULL
  WHERE
    id IN
    (
      SELECT DISTINCT
        id
      FROM
        (
          SELECT
            id
          , CONNECT_BY_ISCYCLE AS is_cycle
          FROM
            hierarchy_example
            START WITH prior_id  IS NOT NULL
            CONNECT BY NOCYCLE id = PRIOR prior_id
        )
      WHERE
        is_cycle = 1
    );

  COMMIT;

END prepare_table;
