/**
 * Databaseline code repository
 *
 * Code for post: Checking Data Type Consistency in Oracle
 * Compatibility: Oracle Database 12c Release 1 and above
 *                Oracle Database 10g Release 1 and above (with minor modifications)
 * Base URL:      https://databaseline.tech
 * Author:        Ian Hellström
 *
 * Notes:         Extended data types (e.g. VARCHAR2) are available from 12.1
 *                PRAGMA UDF is available from 12.1
 *                Regular expressions are available from 10.1
 *
 *                RESULT_CACHE does not work in 11.2 for invoker-rights (IR) units (i.e. AUTHID CURRENT_USER).
 *                From 12c onwards, both IR and definer-rights (DR) units can use the result cache, but for IR
 *                units the result cache is user-specific.
 *                More information: http://www.oracle.com/technetwork/issue-archive/2013/13-sep/o53plsql-1999801.html.
 */

CREATE OR REPLACE PACKAGE BODY sql_utils
AS
  /** Generates a regular expression with all built-in schema/user names.
   * It can be used to filter out these schemas: SELECT * FROM obj WHERE NOT REGEXP_LIKE( owner , sql_utils.default_schemas_regex() );
   * @return  regular expression
   */
  FUNCTION default_schemas_regex
    RETURN type_defs.text_t
    DETERMINISTIC
    RESULT_CACHE
  IS
    lc_default_schemas CONSTANT type_defs.text_t :=
      '^(AUDSYS|ANONYMOUS|APEX\_|APPQOSSYS|AWR_STAGE|CSMIG|CTXSYS|DBSNMP|DIP|DMSYS|DSSYS|DVSYS|EXFSYS|FLOWS\_|LBACSYS|GSMADMIN|' ||
        'MDDATA|MDSYS|MGMT\_VIEW|MTSSYS|OBE|ODM|OJVMSYS|OLAPSYS|ORACLE\_OCM|ORDDATA|ORDPLUGINS|ORDSYS|OUTLN|OWBSYS|SI_INFORMTN_SCHEMA|' ||
        'SPATIAL\_|SYS|SYSMAN|SYSTEM|WKPROXY|WKSYS|WMSYS|XDB)';
  BEGIN
    RETURN lc_default_schemas;
  END default_schemas_regex;



  /** Converts a DAY-TO-SECOND INTERVAL to the number of seconds in the interval.
   * @param  dts_in     day-to-second INTERVAL
   * @return            number of seconds in the INTERVAL
   */
  FUNCTION dts_to_sec
  (
    dts_in INTERVAL DAY TO SECOND
  )
    RETURN NUMBER
    DETERMINISTIC
    RESULT_CACHE
  IS
    PRAGMA UDF;
    l_seconds NUMBER;
  BEGIN
    l_seconds := 24 * 3600 * EXTRACT(DAY FROM dts_in) +
                 3600 * EXTRACT(HOUR FROM dts_in) +
                 60 * EXTRACT(MINUTE FROM dts_in) +
                 EXTRACT(SECOND FROM dts_in);

    RETURN l_seconds;
  END dts_to_sec;



  /** Converts a character data type, length, and character used to a full type specification.
   * @param   type_in                 data type of the character type
   * @param   length_in               data length of the character type
   * @param   char_in                 whether the length is specified in BYTEs (B) or CHARs (C)
   * @throws  ex_incorrect_data_type  if the input data type is not a character type
   * @return                          full specification of the data type
   */
  FUNCTION to_char_spec
  (
    type_in    all_tab_cols.data_type%TYPE
  , length_in  all_tab_cols.data_length%TYPE
  , char_in    all_tab_cols.char_used%TYPE
  )
    RETURN type_defs.spec_t
    DETERMINISTIC
    RESULT_CACHE
  IS
    PRAGMA UDF;
    l_char CHAR(4);
    l_spec type_defs.spec_t;
  BEGIN
    IF ( type_in NOT IN ('VARCHAR2','NVARCHAR2','CHAR','NCHAR') )
    THEN
      RAISE_APPLICATION_ERROR( errors.en_incorrect_data_type,
                               'Specified data type >>' || type_in || '<< is not a character data type.');
    ELSE
      IF ( type_in IN ('VARCHAR','CHAR') )
      THEN
        IF ( char_in = 'C' )
        THEN
          l_char := 'CHAR';
        ELSE
          l_char := 'BYTE';
        END IF;
        l_spec := type_in || '(' || length_in || ' ' || l_char || ')';
      ELSE
        l_spec := type_in || '(' || length_in || ')';
      END IF;
    END IF;

    RETURN l_spec;

  END to_char_spec;


  /** Converts a NUMBER data type, precision, and scale to a full type specification.
   * @param   type_in                 data type of the NUMBER type
   * @param   precision_in            data precision of the NUMBER type
   * @param   scale_in                data scale of the NUMBER type
   * @throws  ex_incorrect_data_type  if the input data type is not NUMBER
   * @return                          full specification of the data type
   */
  FUNCTION to_num_spec
  (
    type_in       all_tab_cols.data_type%TYPE
  , precision_in  all_tab_cols.data_precision%TYPE
  , scale_in      all_tab_cols.data_scale%TYPE
  )
    RETURN type_defs.spec_t
    DETERMINISTIC
    RESULT_CACHE
  IS
    PRAGMA UDF;
    l_spec type_defs.spec_t;
  BEGIN
    IF ( type_in <> 'NUMBER' )
    THEN
      RAISE_APPLICATION_ERROR( errors.en_incorrect_data_type,
                               'Specified data type >>' || type_in || '<< is not NUMBER.');
    ELSE
      IF ( precision_in IS NOT NULL )
      THEN
        IF ( scale_in   IS NOT NULL )
        THEN
          l_spec := type_in || '(' || precision_in || ',' || scale_in || ')';
        ELSE
          l_spec := type_in || '(' || precision_in || ')';
        END IF;
      ELSE
        l_spec := type_in;
      END IF;
    END IF;

    RETURN l_spec;

  END to_num_spec;



  /** Converts any database data type to a full type specification.
   * NB: The parameters are usually to be supplied from a call to dba_tab_cols
   * or all_tab_cols.
   * @param   data_type_in    data type of the NUMBER type
   * @param   data_length_in  data length or size of the data type
   * @param   precision_in    data precision or size of the data type
   * @param   scale_in        data scale of the data type
   * @param   char_used_in    whether the length is specified in BYTEs (B) or CHARs (C)
   * @return                  full specification of the data type
   */
  FUNCTION to_type_spec
  (
    data_type_in       all_tab_cols.data_type%TYPE
  , data_length_in     all_tab_cols.data_length%TYPE
  , data_precision_in  all_tab_cols.data_precision%TYPE
  , data_scale_in      all_tab_cols.data_scale%TYPE
  , char_used_in       all_tab_cols.char_used%TYPE
  )
    RETURN type_defs.spec_t
    DETERMINISTIC
    RESULT_CACHE
  IS
    PRAGMA UDF;
    c_type CONSTANT all_tab_cols.data_type%TYPE :=
      REGEXP_REPLACE(data_type_in,'\([[:digit:]]{1,}\)','');
    l_spec type_defs.spec_t;
  BEGIN
    l_spec :=
    CASE c_type
    WHEN 'VARCHAR2' THEN
      to_char_spec(c_type, data_length_in, char_used_in)
    WHEN 'NVARCHAR2' THEN
      to_char_spec(c_type, data_length_in, char_used_in)
    WHEN 'NUMBER' THEN
      to_num_spec(c_type, data_precision_in, data_scale_in)
    WHEN 'FLOAT' THEN
      c_type ||
      CASE
      WHEN data_precision_in IS NULL THEN
        '(' || data_precision_in || ')'
      ELSE
        ''
      END
    WHEN 'BINARY_FLOAT' THEN
      'BINARY_FLOAT'
    WHEN 'BINARY_DOUBLE' THEN
      'BINARY_DOUBLE'
    WHEN 'TIMESTAMP' THEN
      'TIMESTAMP(' || data_scale_in || ')'
    WHEN 'TIMESTAMP WITH TIME ZONE' THEN
      'TIMESTAMP(' || data_scale_in || ') WITH TIME ZONE'
    WHEN 'INTERVAL YEAR TO MONTH' THEN
      'INTERVAL YEAR(' || data_precision_in || ') TO MONTH'
    WHEN 'INTERVAL DAY TO SECOND' THEN
      'INTERVAL DAY(' || data_precision_in || ') TO SECOND(' || data_scale_in || ')'
    WHEN 'RAW' THEN
      'RAW(' || data_length_in || ')'
    WHEN 'UROWID' THEN
      c_type ||
      CASE
      WHEN data_length_in = 4000 THEN
        ''
      ELSE
        '(' || data_length_in || ')'
      END
    WHEN 'CHAR' THEN
      to_char_spec(c_type, data_length_in, char_used_in)
    WHEN 'NCHAR' THEN
      to_char_spec(c_type, data_length_in, char_used_in)
    ELSE
      c_type
    END;

    RETURN l_spec;

  END to_type_spec;

END sql_utils;
