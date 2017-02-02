/*
 * Execute this deployment script from the current directory
 * in which the source files are located.
 *
 * These files can also be placed in the SQLPATH folder,
 * which can be found by issuing:
 *   - "echo $SQLPATH" on UNIX/Linux
 *   - "echo %SQLPATH%" on Windows.
 * A list of all environment variables for Linux (Windows)
 * can be obtained by the command "printenv" ("set").
 *
 * To find the present working directory, use "host pwd"
 * in SQL*Plus.
 * Note that "host cd" in SQL*Plus creates a subshell,
 * which does not affect SQL*Plus itself.
 *
 * Running a script in SQL*Plus is as easy as typing
 * START deployment.pls (when moved to the root folder).
 */

@"tables/error_log.sql"
/
@"views/error_log_recent.sql"
/
@"packages/errors.pks"
/
@"packages/errors.pkb"
/
@"packages/type_defs.pkg"
/
@"packages/sql_utils.pks"
/
@"packages/sql_utils.pkb"
/
@"views/data_type_issues.sql"
/
@"packages/plsql_utils.pks"
/
@"packages/plsql_utils.pkb"
/
@"tables/etl_conf.sql"
/
@"tables/etl_conf_log.sql"
/
@"tables/etl_exec_log.sql"
/
@"triggers/etl_conf_aft_mod.pls"
/
@"triggers/etl_conf_bef_ins.pls"
/
@"packages/etl.pks"
/
@"packages/etl.pkb"
/
@"views/etl_stats.sql"
/
@"views/etl_hist.sql"
/
@"views/etl_recent.sql"