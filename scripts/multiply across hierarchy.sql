/**
 * Databaseline code repository
 *
 * Code for post: How to Multiply Across a Hierarchy in Oracle
 * Compatibility: Oracle Database 12c Release 1
 * Base URL:      http://databaseline.wordpress.com
 * Post URL:      http://wp.me/p4zRKC-2B
 *                http://wp.me/p4zRKC-2G
 * Author:        Ian Hellström
 *
 * Notes:         PRAGMA UDF and WITH FUNCTION are available from 12.1.
 */

CREATE TABLE hierarchy_example
  (
     id        NUMBER
   , prior_id  NUMBER
   , yield     NUMBER(3,2)
  );

CREATE INDEX ix_hierarchy ON hierarchy_example(prior_id, id);

CREATE TABLE hierarchy_stats
  (
     run_time         DATE
   , seed_value       NUMBER
   , num_rows         NUMBER
   , method_name      VARCHAR2(5)
   , cpu_time         NUMBER  -- microseconds (for parse, execute, and fetch)
   , elapsed_time     NUMBER  -- microseconds (for parse, execute, and fetch)
   , sharable_mem     NUMBER  -- bytes
   , persistent_mem   NUMBER  -- bytes
   , runtime_mem      NUMBER  -- bytes
   , sorts            NUMBER
   , fetches          NUMBER
   , executions       NUMBER
   , buffer_gets      NUMBER
   , plsql_exec_time  NUMBER  -- microseconds
   , rows_processed   NUMBER
   , CONSTRAINT hierarchy_stats_pk PRIMARY KEY ( run_time, seed_value, num_rows, method_name )
  );
