/**
 * Databaseline code repository
 *
 * Code for post: Searching The Oracle Data Dictionary
 *                Checking Data Type Consistency in Oracle
 *                ETL: A Simple Package to Load Data from Views
 * Compatibility: Oracle Database 10g Release 1 and above
 * Base URL:      https://databaseline.bitbucket.io
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1
 */

CREATE OR REPLACE PACKAGE BODY errors
AS
  PRAGMA SERIALLY_REUSABLE;

  /** Re-raise an exception.
   * @param  code_in  exception number (SQLCODE)
   * @param  desc_in  custom exception description
   */
  PROCEDURE reraise
  (
    code_in INTEGER  := SQLCODE
  , desc_in VARCHAR2 := NULL
  )
  IS
  BEGIN
    IF ( code_in BETWEEN -20999 AND -20005 OR code_in > 100 ) THEN
      RAISE_APPLICATION_ERROR(code_in, desc_in);
    ELSE
      EXECUTE IMMEDIATE
        'DECLARE excp EXCEPTION; ' ||
        '  PRAGMA EXCEPTION_INIT(excp, ' || TO_CHAR(code_in) || ');' ||
        'BEGIN ' ||
        '  RAISE excp; ' ||
        'END;';
    END IF;
  END reraise;

  /** Logs or displays errors based on the environment variable of this package's specification
   * without raising the exception.
   * @param  code_in  exception number (SQLCODE)
   * @param  desc_in  custom exception description
   */
  PROCEDURE log_and_continue
  (
    code_in INTEGER  := SQLCODE
  , desc_in VARCHAR2 := NULL
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_osuser       error_log.created_by%TYPE   := SYS_CONTEXT('USERENV', 'OS_USER');
    l_code         error_log.code%TYPE         := code_in;
    l_message      error_log.message%TYPE      := SUBSTR(SQLERRM, 1, 100);
    l_description  error_log.description%TYPE  := desc_in;
    l_call_stack   error_log.call_stack%TYPE   := DBMS_UTILITY.FORMAT_CALL_STACK;
    l_error_stack  error_log.error_stack%TYPE  := DBMS_UTILITY.FORMAT_ERROR_STACK;
    l_error_trace  error_log.error_trace%TYPE  := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    l_session_id   error_log.session_id%TYPE   := SYS_CONTEXT('USERENV', 'SID');
    l_session_user error_log.session_user%TYPE := SYS_CONTEXT('USERENV', 'SESSION_USER');
    l_application  error_log.application%TYPE  := SYS_CONTEXT('USERENV', 'MODULE');
    l_ip_address   error_log.ip_address%TYPE   := SYS_CONTEXT('USERENV', 'IP_ADDRESS');
    l_auth_method  error_log.auth_method%TYPE  := SYS_CONTEXT('USERENV', 'AUTHENTICATION_METHOD');
  BEGIN
    IF ( g_env = 'PROD') THEN
      INSERT INTO error_log
        VALUES ( SYSDATE,
                 l_osuser,
                 l_code,
                 l_message,
                 l_description,
                 l_call_stack,
                 l_error_stack,
                 l_error_trace,
                 l_session_id,
                 l_session_user,
                 l_application,
                 l_ip_address,
                 l_auth_method );

      COMMIT;
    ELSE
      SYS.DBMS_OUTPUT.PUT_LINE(l_call_stack);
      SYS.DBMS_OUTPUT.PUT_LINE(l_error_stack);
      SYS.DBMS_OUTPUT.PUT_LINE(l_error_trace);
    END IF;

  END log_and_continue;


  /** Logs or displays errors based on the environment variable of this package's specification,
   * and raises the exception.
   * @param  code_in  exception number (SQLCODE)
   * @param  desc_in  custom exception description
   */
  PROCEDURE log_and_stop
  (
    code_in INTEGER  := SQLCODE
  , desc_in VARCHAR2 := NULL
  )
  IS
  BEGIN
    log_and_continue(code_in, desc_in);
    reraise(code_in, desc_in);
  END log_and_stop;

END errors;
