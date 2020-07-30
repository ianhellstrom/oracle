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

CREATE OR REPLACE FUNCTION run_mult_stmt
(
  v_method_in IN VARCHAR2
)
  RETURN NUMBER
  AUTHID CURRENT_USER
AS
  SUBTYPE string_t   IS VARCHAR2(32767);
  TYPE    string_aat IS TABLE OF string_t INDEX BY VARCHAR(10);

  l_sql_stmts  string_aat;
  return_value NUMBER;
BEGIN
  l_sql_stmts('mult') := q'{SELECT /*--mult--*/
                             AVG(yield_to_step)
                            FROM
                             (
                              SELECT
                                 LEVEL AS lvl
                               , o.id
                               , o.yield
                               , (
                                  SELECT
                                    ROUND( EXP(SUM(LN(i.yield))), 2 )
                                  FROM
                                    hierarchy_example i
                                  START WITH
                                    i.id = o.id
                                  CONNECT BY NOCYCLE
                                    i.id = PRIOR i.prior_id
                                  )                               AS yield_to_step
                               , CONNECT_BY_ROOT( o.id )          AS root_id
                               , SYS_CONNECT_BY_PATH( o.id, '/' ) AS path
                              FROM
                                hierarchy_example o
                              START WITH
                                o.prior_id IS NULL
                              CONNECT BY NOCYCLE
                                o.prior_id = PRIOR o.ID
                             )}';

  l_sql_stmts('eval') := q'{SELECT /*--eval--*/
                             AVG(yield_to_step)
                            FROM
                             (
                              SELECT
                                 LEVEL AS lvl
                               , id
                               , prior_id
                               , yield
                               , eval
                                  (
                                   SUBSTR( SYS_CONNECT_BY_PATH( TO_CHAR(yield), '*' ) , 2)
                                  )                             AS yield_to_step
                               , CONNECT_BY_ROOT ( id )         AS root_id
                               , SYS_CONNECT_BY_PATH( id, '/' ) AS path
                              FROM
                                hierarchy_example
                              START WITH
                                prior_id IS NULL
                              CONNECT BY NOCYCLE
                                prior_id = PRIOR id
                             )}';

  -- WITH FUNCTION has to be issued as a whole:
  -- WITH /*--with--*/ FUNCTION leads to compilation errors in 12.1 when running statement on its own
  l_sql_stmts('with') := q'{WITH FUNCTION /*--with--*/ with_eval (expr_in IN VARCHAR2)
                              RETURN NUMBER
                            IS
                              v_res NUMBER;
                            BEGIN
                              EXECUTE IMMEDIATE 'SELECT ' || expr_in || ' FROM DUAL' INTO v_res;
                              RETURN v_res;
                            END;
                            SELECT
                             AVG(yield_to_step)
                            FROM
                             (
                              SELECT
                                 LEVEL AS lvl
                               , id
                               , prior_id
                               , yield
                               , with_eval
                                 (
                                  SUBSTR( SYS_CONNECT_BY_PATH( TO_CHAR(yield), '*' ) , 2)
                                 )                            AS yield_to_step
                               , CONNECT_BY_ROOT ( id )         AS root_id
                               , SYS_CONNECT_BY_PATH( id, '/' ) AS path
                              FROM
                                 hierarchy_example
                              START WITH
                                 prior_id IS NULL
                              CONNECT BY NOCYCLE
                                 prior_id = PRIOR id
                             )}';

  l_sql_stmts('cte')  := q'{WITH /*--cte--*/ cte(lvl, id, prior_id, yield, yield_to_step, root_id, path) AS
                              (
                               SELECT
                                 1
                               , id
                               , prior_id
                               , yield
                               , yield                                 -- yield_to_step = yield for all anchors
                               , id                                    -- root_id = id for all anchors
                               , '/' || id
                              FROM
                                 hierarchy_example
                              WHERE
                                 prior_id IS NULL
                              UNION ALL
                              SELECT
                                 r.lvl + 1
                               , d.id
                               , d.prior_id
                               , d.yield
                               , ROUND( d.yield * r.yield_to_step, 2 ) -- simple column multiplication
                               , TO_NUMBER( REGEXP_REPLACE( r.path, '/([[:digit:]]+)($|/.+)', '\1' ) )
                               , r.path || '/' || d.id
                              FROM
                                 hierarchy_example d
                              INNER JOIN
                                 cte r
                              ON
                                d.prior_id = r.id
                              WHERE
                                d.prior_id IS NOT NULL
                              )
                            SELECT AVG(yield_to_step) FROM cte}';

  EXECUTE IMMEDIATE l_sql_stmts(v_method_in) INTO return_value;

  RETURN return_value;

END run_mult_stmt;
