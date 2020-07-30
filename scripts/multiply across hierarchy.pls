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

DECLARE

  TYPE seed_arr IS VARRAY(4) OF BINARY_INTEGER;
  TYPE rows_arr IS VARRAY(5) OF NUMBER;
  TYPE meth_arr IS VARRAY(4) OF VARCHAR2(5);

  l_seeds    seed_arr := seed_arr(42, 429, 4862, 58786);
  l_rows     rows_arr := rows_arr();
  l_methods  meth_arr := meth_arr('cte', 'eval', 'mult', 'with');
  l_value    NUMBER;
  l_start_ts TIMESTAMP;
  l_end_ts   TIMESTAMP;

BEGIN

  l_rows.EXTEND(5);

  DELETE FROM hierarchy_example;
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Seed,Rows,Method,Value,Elapsed');

  << rows_loop >>
  FOR row_idx IN 1..l_rows.COUNT LOOP
	l_rows(row_idx) := POWER( 10, row_idx );

    << seeds_loop >>
    FOR seed_idx IN 1..l_seeds.COUNT LOOP

      prepare_table( l_seeds(seed_idx), l_rows(row_idx) );

      << methods_loop >>
      FOR meth_idx IN 1..l_methods.COUNT LOOP

        -- ensure a similar environment for each run
        EXECUTE IMMEDIATE 'ALTER SYSTEM FLUSH buffer_cache';
        EXECUTE IMMEDIATE 'ALTER SYSTEM FLUSH shared_pool';

        l_start_ts := SYSTIMESTAMP;
        l_value    := run_mult_stmt( l_methods(meth_idx) );
        l_end_ts   := SYSTIMESTAMP;

        -- cross-check with hierarchy_stats
        DBMS_OUTPUT.PUT_LINE
          (
            TO_CHAR( l_seeds(seed_idx) )   || ',' ||
            TO_CHAR( l_rows(row_idx) )     || ',' ||
            TO_CHAR( l_methods(meth_idx) ) || ',' ||
            TO_CHAR( l_value )             || ',' ||
            TO_CHAR( l_end_ts - l_start_ts )
          );

        INSERT INTO
           hierarchy_stats
        SELECT
           SYSDATE
         , l_seeds(seed_idx)
         , l_rows(row_idx)
         , l_methods(meth_idx)
         , cpu_time
         , elapsed_time
         , sharable_mem
         , persistent_mem
         , runtime_mem
         , sorts
         , fetches
         , executions
         , buffer_gets
         , plsql_exec_time
         , rows_processed
          FROM
           v$sql
        WHERE
         REGEXP_LIKE(sql_text, '(SELECT|WITH|WITH FUNCTION) /\*--' || l_methods(meth_idx) || '--\*/');
        COMMIT;

      END LOOP methods_loop;

      DELETE FROM hierarchy_example;
      COMMIT;

    END LOOP seeds_loop;

  END LOOP rows_loop;

END;
