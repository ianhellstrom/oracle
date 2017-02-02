/**
 * Databaseline code repository
 *
 * Code for post: Searching The Oracle Data Dictionary
 *                Checking Data Type Consistency in Oracle
 * Compatibility: Oracle Database 12c Release 1 and above
 *                Oracle Database 10g Release 1 and above (with minor modifications)
 * Base URL:      https://databaseline.bitbucket.io
 * Author:        Ian Hellström
 *
 * Notes:         Regular expressions are available from 10.1
 *                INDEX BY VARCHAR2 is available from 9.2
 *                CASE statements are available from 9.0
 *
 *                To save memory, especially with many users connected to the database,
 *                this package is defined as serially reusable, which means that it can
 *                only be used from within pure PL/SQL code, not SQL statements.
 *                Functions that are used inside SQL statements (e.g. custom conversions)
 *                need to be defined in a separate package: SQL_UTILS.
 */

CREATE OR REPLACE PACKAGE BODY plsql_utils
AS
  PRAGMA SERIALLY_REUSABLE;

  TYPE identifier_aat IS TABLE OF type_defs.identifier_t INDEX BY PLS_INTEGER;

  TYPE desc_col_rec IS RECORD
  (
    col_type      PLS_INTEGER,
    col_max_len   PLS_INTEGER,
    col_precision PLS_INTEGER,
    col_scale     PLS_INTEGER
  );

  TYPE desc_tab_aat IS TABLE OF desc_col_rec INDEX BY type_defs.identifier_t;

  TYPE tab_comments_aat IS TABLE OF all_tab_comments%ROWTYPE INDEX BY PLS_INTEGER;


  /** Formats a string and, if necessary, splits it in chunks based on the maximum display width.
   * NB: It splits strings on spaces unless a word is larger than the maximum display width, in which case it splits the string at the end
   * of the line and inserts an overflow character ('\').
   * @param   string_in                string to be formatted
   * @param   indent_in                number of indentations
   * @param   new_line_in              whether or not a new line is added at the end of the formatted line
   * @param   max_width_in             maximum display width
   * @throws  ex_indentation_overflow  if more than 10 indentations are specified or
   *                                   if the number of indentation characters exceeds the maximum display width
   * @return                           formatted string
   */
  FUNCTION format_line
  (
    string_in     VARCHAR2
  , indent_in     PLS_INTEGER := 0
  , new_line_in   BOOLEAN     := FALSE
  , max_width_in  PLS_INTEGER := 80
  )
    RETURN VARCHAR2
  IS
    lc_pad_chars          CONSTANT VARCHAR2(2)   := '  ';
    lc_pad                CONSTANT VARCHAR2(100) := LPAD(lc_pad_chars, 2*indent_in, lc_pad_chars);
    lc_pad_size           CONSTANT PLS_INTEGER   := NVL(LENGTH(lc_pad),0);
    lc_max_pad_levels     CONSTANT PLS_INTEGER   := 10;
    lc_overflow_chars     CONSTANT VARCHAR2(1)   := '\';
    lc_overflow_size      CONSTANT PLS_INTEGER   := NVL(LENGTH(lc_overflow_chars),0);
    l_space_pos                    PLS_INTEGER;
    l_split_pos                    PLS_INTEGER;
    l_line                         type_defs.string_t;
    lc_padded_string      CONSTANT l_line%TYPE   := lc_pad || TRIM(string_in);
    lc_padded_string_size CONSTANT PLS_INTEGER   := NVL(LENGTH(lc_padded_string),0);
  BEGIN
    IF ( indent_in >= lc_max_pad_levels )
    THEN
      RAISE_APPLICATION_ERROR( errors.en_indentation_overflow,
                              'Indentation limited at ' || lc_max_pad_levels || ' levels, current value: ' || indent_in || '.');
    ELSIF ( indent_in >= 0.5*max_width_in )
    THEN
      RAISE_APPLICATION_ERROR( errors.en_indentation_overflow,
                              'The number of characters indented (' || lc_pad_size ||
                              ') cannot exceed the maximum display width: ' || max_width_in || '.');
    END IF;

    IF ( lc_padded_string_size > max_width_in )
    THEN
      -- Look for the whitespace closest to and below (default) the maximum width.
      -- The padding needs to be taken into account for the line to stick to the maximum width.
      l_space_pos :=
        CASE
        WHEN lc_padded_string_size <= max_width_in THEN
          lc_padded_string_size
        ELSE
          INSTR(SUBSTR(lc_padded_string, 1, max_width_in), ' ', -1)
        END;

      -- INSTR returns 0 if there is no character found, so we have to use the padding size as the offset.
      IF ( l_space_pos > lc_pad_size ) THEN
        l_split_pos := l_space_pos;
      ELSE
        -- Break the line at the last possible position to leave enough space for the overflow character(s).
        l_split_pos := max_width_in - lc_overflow_size;
      END IF;

      l_line := RTRIM(SUBSTR( lc_padded_string, 1, l_split_pos )) ||
        CASE WHEN l_space_pos <= lc_pad_size THEN lc_overflow_chars END || CHR(10);

      l_line := l_line ||
        format_line( SUBSTR( lc_padded_string, l_split_pos + 1, lc_padded_string_size ), indent_in, new_line_in, max_width_in );
    ELSE
      l_line := lc_padded_string || CASE WHEN new_line_in THEN CHR(10) END;
    END IF;

    RETURN l_line;

  END format_line;



  /** Displays a properly formatted string with DBMS_OUTPUT.PUT_LINE().
   * @param   string_in                string to be formatted
   * @param   indent_in                number of indentations
   * @param   new_line_in              whether or not a new line is added at the end of the formatted line
   * @param   max_width_in             maximum display width
   */
  PROCEDURE display
  (
    string_in     VARCHAR2
  , indent_in     PLS_INTEGER := 0
  , new_line_in   BOOLEAN     := FALSE
  , max_width_in  PLS_INTEGER := 80
  )
  IS
  BEGIN
    SYS.DBMS_OUTPUT.PUT_LINE(format_line(string_in, indent_in, new_line_in, max_width_in));
  EXCEPTION
    WHEN OTHERS THEN
      errors.log_and_stop();
  END display;



  /** Converts an object name to upper case, leaving double-quoted object names as they are,
   * and removing any leading and trailing spaces.
   * @param   object_in  object name
   * @return             trimmed object name in upper case
   */
  FUNCTION to_upper
  (
    object_in  type_defs.identifier_t
  )
    RETURN type_defs.identifier_t
    DETERMINISTIC
  IS
    l_retstr type_defs.identifier_t;
  BEGIN
    IF ( SUBSTR(object_in, 1, 1) = '"' AND SUBSTR(object_in, -1, 1) = '"' ) THEN
      l_retstr := TRIM(object_in);
    ELSE
      l_retstr := TRIM(UPPER(object_in));
    END IF;
    RETURN l_retstr;
  END to_upper;



  /** Fully qualifies an object name and converts all components to upper case, leaving double-quoted names as they are,
   * and removing any leading and trailing spaces.
   * @param  owner_in    owner
   * @param  object_in   object name
   * @param  db_link_in  database link name
   * @return             fully qualified, trimmed object identifier in upper case
   */
  FUNCTION qualify
  (
    owner_in    type_defs.identifier_t
  , object_in   type_defs.identifier_t
  , db_link_in  type_defs.identifier_t := NULL
  )
    RETURN VARCHAR2
  IS
    l_qualified type_defs.string_t;
  BEGIN
    l_qualified := to_upper(owner_in) || '.' || to_upper(object_in);

    IF (db_link_in IS NOT NULL)
    THEN
      l_qualified := l_qualified || '@' || to_upper(db_link_in);
    END IF;

    RETURN l_qualified;

  END qualify;



  /** Splits a string with object names into an associative array with the object names.
   * NB: Object names have to be delimited with any punctuation mark except _, $, #, and &.
   * @param   string_in                      string with object names
   * @throws  ex_empty_string_specified      if the input parameter is empty or NULL
   * @throws  ex_double_quotes_do_not_match  if the number of double quotes in the input parameter does not match
   * @throws  ex_invalid_identifier          if a specified object name is not a valid Oracle SQL name
   * @return                                 associative array with object names
   */
  FUNCTION split_objects
  (
    string_in  VARCHAR2
  )
    RETURN identifier_aat
    DETERMINISTIC
  IS
    l_idx    PLS_INTEGER         := 0;
    l_length NUMBER              := 0;
    l_delim  NUMBER              := 0;
    l_substr type_defs.string_t  := NULL;
    l_string type_defs.string_t  := TRIM(string_in);
    l_retarr identifier_aat;
    l_num    NUMBER;
  BEGIN
    l_num := MOD(REGEXP_COUNT(l_string, '"'), 2);

    IF ( l_string IS NULL ) THEN

      RAISE_APPLICATION_ERROR( errors.en_empty_string_specified,
                               'The input parameter is either empty or NULL');

    ELSIF ( l_num <> 0 ) THEN

      RAISE_APPLICATION_ERROR( errors.en_double_quotes_do_not_match,
                               'The number of double quotes (") does not match: ' || l_num || ' found for >>' || string_in || '<<.' );

    ELSE

      WHILE ( l_string IS NOT NULL )
        LOOP

          /* Extract a string up to and including the delimiter (i.e. [[:punct:]] except _, $, #, and &).
          * The string can be either double-quoted or a (potentially) valid schema object identifier.
          *
          * ^                                beginning of line
          * ("[[:print:]]+?")                one or more (+) printable characters enclosed by double quotes (non-greedy: ?)
          * ([[:alnum:]_$#]+?)               one or more (+) alphanumeric characters (incl. _, $, and #) (non-greedy: ?)
          * [!%&\*+,\\-\./:;<=>\?@\\^\|~ ]   exactly one punctuation character (all except _, $, and #)
          * $                                end of line
          */
          l_substr := REGEXP_SUBSTR(l_string, '^(("[[:print:]]+?")|([[:alnum:]_$#]+?))([!%*+,-./:;<=>?@\^|~ ]|$)', 1, 1);

          -- Determine the length of the substring incl. final delimiter.
          l_length := LENGTH(l_substr);

          -- Mark the trailing separator.
          IF ( SUBSTR(l_substr, -1) IN ('!','%','*','+',',','\','-','.','/',':',';','<','=','>','?','@','\','^','|','~',' ') ) THEN
            l_delim := 1;
          ELSE
            l_delim := 0;
          END IF;

          -- Remove the trailing delimiter, if necessary.
          l_substr := TRIM(SUBSTR(l_substr, 1, l_length - l_delim));

          IF ( l_substr IS NOT NULL ) THEN

            l_idx := l_idx + 1;

            -- Ensure that the substring is a syntactically valid schema object identifier.
            l_substr := SYS.DBMS_ASSERT.SIMPLE_SQL_NAME(l_substr);

            -- Convert to upper case, properly dealing with double-quoted identifiers.
            l_retarr(l_idx) := to_upper(l_substr);

          END IF;

          -- Remove the leading substring (and delimiter), and deal with empty substrings appropriately.
          l_string := SUBSTR(l_string, NVL(l_length, 1) + 1);

        END LOOP;

    END IF;

    RETURN l_retarr;

  EXCEPTION
    WHEN errors.ex_invalid_sql_name THEN
      RAISE_APPLICATION_ERROR( errors.en_invalid_identifier,
                               'Invalid database identifier >>' || l_substr || '<< specified.' );
    WHEN OTHERS THEN
      errors.log_and_stop();
  END split_objects;



  /** Finds a table or view with the columns specified.
   * NB: For Oracle Database 12c and above, the DBMS_SQL.RETURN_RESULT() function can be used to display the information directly to the
   * client. This requires a SYS_REFCURSOR, which one can easily obtain with the built-in DBMS_SQL.TO_REFCURSOR function; such a conversion
   * entails that functions that take a SQL cursor number cannot be used afterwards, as they yield errors.
   * Because of a bug in SQL Developer 4 that returns "ORA-29481: implicit results cannot be returned to client" irrespective of the
   * database client, a more backwards-compatible solution using DBMS_OUTPUT.PUT_LINE() was chosen.
   * See: http://community.oracle.com/thread/3565925
   * @param  cols_in       list of columns separated with a punctuation mark (except _, $, and #)
   * @param  owner_in      (optional) owner for sought-after object
   * @param  prefix_in     (optional) prefix for sought-after object
   * @param  tab_or_vw_in  (optional) specifier whether the sought-after object is a table ('T') or view ('V')
   */
  PROCEDURE find_table
  (
    cols_in      VARCHAR2
  , owner_in     type_defs.identifier_t           := NULL
  , prefix_in    type_defs.identifier_t           := NULL
  , tab_or_vw_in all_tab_comments.table_type%TYPE := NULL
  )
  IS
    l_cursor        PLS_INTEGER := SYS.DBMS_SQL.OPEN_CURSOR;
    l_num_obj       PLS_INTEGER;
    l_num_rows      PLS_INTEGER;
    l_objects       identifier_aat;
    l_owner         type_defs.identifier_t := to_upper(owner_in);
    l_prefix        type_defs.identifier_t := to_upper(prefix_in);
    l_tabvw         type_defs.identifier_t := to_upper(tab_or_vw_in);
    l_sql           type_defs.string_t;
    l_joins         type_defs.string_t;
    l_where         type_defs.string_t;
    l_desc_cols     desc_tab_aat;
    l_desc_owner    type_defs.identifier_t;
    l_desc_table    type_defs.identifier_t;
    l_desc_type     type_defs.identifier_t;
    l_desc_comment  type_defs.string_t;
    l_table_matches tab_comments_aat;
    l_num_matches   PLS_INTEGER := 0;

     /** Obtains the description of columns of a particular table.
     * NB: It is the SQL*Plus-equivalent of DESC table_name.
     * @param  table_name_in  name of the table to be described
     * @param  owner_in       (optional) owner for table, default SYS
     * @return                table of records with details for each column
     */
    FUNCTION desc_tab
    (
      table_name_in  type_defs.identifier_t
    , owner_in       type_defs.identifier_t := 'SYS'
    )
      RETURN desc_tab_aat
      DETERMINISTIC
    IS
      l_cursor   PLS_INTEGER := SYS.DBMS_SQL.OPEN_CURSOR;
      l_result   PLS_INTEGER;
      l_num_cols PLS_INTEGER;
      l_desc_rec SYS.DBMS_SQL.DESC_REC;
      l_desc_tab SYS.DBMS_SQL.DESC_TAB;
      l_return   desc_tab_aat;
      l_col_name type_defs.identifier_t;
    BEGIN
      SYS.DBMS_SQL.PARSE(l_cursor, 'SELECT * FROM ' || qualify(owner_in,table_name_in), SYS.DBMS_SQL.NATIVE);

      l_result := SYS.DBMS_SQL.EXECUTE(l_cursor);

      SYS.DBMS_SQL.DESCRIBE_COLUMNS(l_cursor, l_num_cols, l_desc_tab);

      SYS.DBMS_SQL.CLOSE_CURSOR(l_cursor);

      -- Convert DBMS_SQL.DESC_TAB to desc_tab_aat, which is indexed by column name
      FOR i IN l_desc_tab.FIRST .. l_desc_tab.LAST
      LOOP
        l_desc_rec := l_desc_tab(i);
        l_col_name := l_desc_rec.col_name;

        l_return(l_col_name).col_type      := l_desc_rec.col_type;
        l_return(l_col_name).col_max_len   := l_desc_rec.col_max_len;
        l_return(l_col_name).col_precision := l_desc_rec.col_precision;
        l_return(l_col_name).col_scale     := l_desc_rec.col_scale;
      END LOOP;

      RETURN l_return;

      EXCEPTION
      WHEN OTHERS THEN
        IF ( SYS.DBMS_SQL.IS_OPEN(l_cursor) ) THEN
          SYS.DBMS_SQL.CLOSE_CURSOR(l_cursor);
        END IF;
        errors.log_and_stop();
    END desc_tab;

    /** Formats table matches as required by find_table().
     * NB: It is the SQL*Plus-equivalent of DESC table_name.
     * @param  tab_comments_in  output from find_table()
     */
    PROCEDURE format_tab_comments
    (
      tab_comments_in  tab_comments_aat
    )
    IS
      l_matches PLS_INTEGER;
    BEGIN
      l_matches := tab_comments_in.COUNT;

      display('Matches found: ' || l_matches);

      FOR i IN 1..l_matches
      LOOP
        display( i || '. ' || qualify(tab_comments_in(i).owner,tab_comments_in(i).table_name) ||
                 ' (' || tab_comments_in(i).table_type || ')' ||
                 CASE WHEN tab_comments_in(i).comments IS NOT NULL THEN
                 ': ' || tab_comments_in(i).comments
                 END, 1 );
      END LOOP;
    END format_tab_comments;

  BEGIN
    l_objects := split_objects(cols_in);

    l_num_obj := l_objects.COUNT;

    -- Build JOIN and WHERE clauses.
    FOR i IN 1..l_num_obj
    LOOP
      l_joins := l_joins || ' JOIN all_tab_cols t' || i || ' USING (owner, table_name)';
      l_where := l_where || CASE WHEN i = 1 THEN ' WHERE' ELSE ' AND' END || ' t' || i || '.column_name = :a' || i;
    END LOOP;

    -- Append optional WHERE clauses.
    IF ( l_owner IS NOT NULL ) THEN
      l_where := l_where || ' AND owner = :owner';
    END IF;

    IF ( l_prefix IS NOT NULL ) THEN
      l_where := l_where || ' AND table_name LIKE :prefix';
    END IF;

    IF ( l_tabvw IS NOT NULL ) THEN
      l_where := l_where || ' AND table_type = ' || CASE WHEN UPPER(l_tabvw) LIKE 'V%' THEN '''VIEW''' ELSE '''TABLE''' END;
    END IF;

    -- Build SQL statement.
    l_sql := 'SELECT owner, table_name, table_type, comments FROM all_tab_comments ';
    l_sql := l_sql || l_joins || l_where;

    -- Obtain column data type information for DBMS_SQL.DEFINE_COLUMN.
    l_desc_cols := desc_tab('all_tab_comments');

    SYS.DBMS_SQL.PARSE( l_cursor, l_sql, SYS.DBMS_SQL.NATIVE );

    FOR i IN 1..l_num_obj
    LOOP
      SYS.DBMS_SQL.BIND_VARIABLE( l_cursor, 'a' || i, l_objects(i) );
    END LOOP;

    IF ( l_owner IS NOT NULL ) THEN
      SYS.DBMS_SQL.BIND_VARIABLE( l_cursor, 'owner', l_owner );
    END IF;

    IF ( l_prefix IS NOT NULL ) THEN
      SYS.DBMS_SQL.BIND_VARIABLE( l_cursor, 'prefix', l_prefix || '%' );
    END IF;

    -- Must match the columns in the SELECT list for l_sql, otherwise DBMS_SQL complains that "ORA-01007: variable not in select list",
    -- which can be hard to track down.
    SYS.DBMS_SQL.DEFINE_COLUMN( l_cursor, 1, l_desc_owner,   l_desc_cols('OWNER').col_max_len );
    SYS.DBMS_SQL.DEFINE_COLUMN( l_cursor, 2, l_desc_table,   l_desc_cols('TABLE_NAME').col_max_len );
    SYS.DBMS_SQL.DEFINE_COLUMN( l_cursor, 3, l_desc_type,    l_desc_cols('TABLE_TYPE').col_max_len );
    SYS.DBMS_SQL.DEFINE_COLUMN( l_cursor, 4, l_desc_comment, l_desc_cols('COMMENTS').col_max_len );

    -- For queries and DDL statements, l_num_rows is undefined and should be ignored.
    -- See: http://docs.oracle.com/database/121/ARPLS/d_sql.htm#ARPLS058
    l_num_rows := SYS.DBMS_SQL.EXECUTE(l_cursor);

    WHILE ( SYS.DBMS_SQL.FETCH_ROWS (l_cursor) > 0 )
    LOOP
      l_num_matches := l_num_matches + 1;

      SYS.DBMS_SQL.COLUMN_VALUE(l_cursor, 1, l_table_matches(l_num_matches).owner);
      SYS.DBMS_SQL.COLUMN_VALUE(l_cursor, 2, l_table_matches(l_num_matches).table_name);
      SYS.DBMS_SQL.COLUMN_VALUE(l_cursor, 3, l_table_matches(l_num_matches).table_type);
      SYS.DBMS_SQL.COLUMN_VALUE(l_cursor, 4, l_table_matches(l_num_matches).comments);
    END LOOP;

    format_tab_comments(l_table_matches);

    SYS.DBMS_SQL.CLOSE_CURSOR(l_cursor);

    EXCEPTION
      WHEN OTHERS THEN
        IF ( SYS.DBMS_SQL.IS_OPEN(l_cursor) ) THEN
          SYS.DBMS_SQL.CLOSE_CURSOR(l_cursor);
        END IF;

        errors.log_and_stop();
  END find_table;



  /** Executes a dynamic PL/SQL block.
   * @param  code_in  a block of dynamic PL/SQL code
   */
  PROCEDURE exec_plsql
  (
    code_in  VARCHAR2
  )
  IS
  BEGIN
    EXECUTE IMMEDIATE
      'BEGIN ' || RTRIM(code_in, ';') || '; END;';
  END exec_plsql;



  /** Executes a dynamic DDL statement as an autonomous transaction.
   * @param  code_in  a dynamic DDL statement
   */
  PROCEDURE exec_ddl
  (
    code_in  VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    EXECUTE IMMEDIATE RTRIM(code_in, ';');
  END exec_ddl;



  /** Executes a dynamic DDL statement as an autonomous transaction.
   * @param  code_in  a dynamic DDL statement
   */
  PROCEDURE exec_ddl
  (
    code_in  CLOB
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    EXECUTE IMMEDIATE RTRIM(code_in, ';');
  END exec_ddl;



  /** Drops a schema-level object.
   * NB: If the object to be dropped does not exist (as the object type specified), the procedure does absolutely nothing.
   * If, however, the object does exist but the user's privileges are not sufficient to drop it, the corresponding exception is raised.
   * @param  owner_in        owner
   * @param  object_in       object name
   * @param  object_type_in  object type that can be dropped with a simple DROP object_type statement
   */
  PROCEDURE drop_object
  (
    owner_in        type_defs.identifier_t
  , object_in       type_defs.identifier_t
  , object_type_in  VARCHAR2 := 'TABLE'
  )
  IS
    lc_qualified   CONSTANT type_defs.string_t           := qualify(owner_in, object_in);
    lc_object_type CONSTANT all_objects.object_type%TYPE := UPPER(object_type_in);
  BEGIN
    IF lc_object_type IN ('TABLE','VIEW','INDEX','USER','DATABASE LINK','SEQUENCE',
                         'FUNCTION','PROCEDURE','TYPE','PACKAGE','PACKAGE BODY','TRIGGER','MATERIALIZED VIEW')
    THEN
      exec_ddl( 'DROP ' || lc_object_type || ' ' || lc_qualified ||
                CASE WHEN lc_object_type = 'TABLE' THEN ' CASCADE CONSTRAINTS PURGE' END);
    ELSE
      RAISE_APPLICATION_ERROR( errors.en_invalid_object,
                               'Object >>' || lc_qualified || '<< does not exist.' );
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      /*
       * SQLCODEs:
       * -  942   TABLE, VIEW
       * - 1418   INDEX
       * - 1918   USER
       * - 2024   DATABASE LINK
       * - 2289   SEQUENCE
       * - 4043   FUNCTION, PROCEDURE, TYPE, PACKAGE (BODY)
       * - 4080   TRIGGER
       * -12003   MATERIALIZED VIEW
       */
      IF SQLCODE NOT IN (-942,-1418,-1918,-2024,-2289,-4043,-4080,-12003)
      THEN
        RAISE;
      END IF;
  END drop_object;



  /** Checks whether a type is a custom type (i.e. not pre-defined and instantiable with attributes).
   * @param  type_name_in  (base) type name
   * @param  owner_in      (optional) owner
   * @return               TRUE if the type is not pre-defined, FALSE otherwise
   */
  FUNCTION custom_type
  (
    type_name_in  type_defs.type_t
  , owner_in      type_defs.identifier_t := NULL
  )
  RETURN BOOLEAN
  IS
    l_rows PLS_INTEGER;
  BEGIN
    -- ATTRIBUTES > 0 cannot be used as a criterion because collections have no attributes but they are instantiable.
    IF ( owner_in IS NULL )
    THEN
      SELECT COUNT(*)
      INTO   l_rows
      FROM   all_types
      WHERE  predefined = 'NO'
             AND instantiable = 'YES'
             AND type_name = type_name_in;
    ELSE
      SELECT COUNT(*)
      INTO   l_rows
      FROM   all_types
      WHERE  predefined = 'NO'
             AND instantiable = 'YES'
             AND type_name = type_name_in
             AND owner = owner_in;
    END IF;

    RETURN ( l_rows > 0 );

  END custom_type;



  /** Checks whether an object exists.
   * @param  owner_in        properly formatted owner
   * @param  object_in       properly formatted object name
   * @param  object_type_in  properly formatted (optional) object type
   * @return                 TRUE if the object exists, FALSE otherwise
   */
  FUNCTION object_exists
  (
    owner_in        type_defs.identifier_t
  , object_in       type_defs.identifier_t
  , object_type_in  type_defs.identifier_t := NULL
  )
    RETURN BOOLEAN
    DETERMINISTIC
  IS
    l_rows         PLS_INTEGER;
  BEGIN
    IF ( object_type_in IS NULL )
    THEN
      SELECT COUNT(*)
      INTO   l_rows
      FROM   all_objects o
      WHERE  o.owner = owner_in
             AND o.object_name = object_in;
    ELSE
      SELECT COUNT(*)
      INTO   l_rows
      FROM   all_objects o
      WHERE  o.owner = owner_in
             AND o.object_name = object_in
             AND o.object_type = object_type_in;
    END IF;

  RETURN ( l_rows = 1 );

  END object_exists;



  /** Checks whether a table is empty (i.e. has no rows).
   * @param   owner_in           owner
   * @param   table_name_in      table name
   * @throws  ex_invalid_object  if the table specified does not exist
   * @return                     TRUE if the table does not contain rows, FALSE if the table or view does have rows
   */
  FUNCTION table_empty
  (
    owner_in       type_defs.identifier_t
  , table_name_in  type_defs.identifier_t
  )
    RETURN BOOLEAN
    DETERMINISTIC
  IS
    l_rows        PLS_INTEGER;
    lc_qualified  CONSTANT type_defs.string_t := qualify(owner_in, table_name_in);
  BEGIN

    IF ( object_exists(owner_in, table_name_in, 'TABLE') )
    THEN
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM DUAL WHERE EXISTS (SELECT * FROM ' || lc_qualified || ')'
      INTO l_rows;
    ELSE
      RAISE_APPLICATION_ERROR( errors.en_invalid_object,
                              'Object >>' || lc_qualified || '<< does not exist.');
    END IF;

    RETURN ( l_rows = 0 );

  END table_empty;



  /** Checks whether an object has a primary or unique key that is also enabled.
   * @param   owner_in     properly formatted owner
   * @param   object_in    properly formatted object name
   * @param   key_type_in  P for a primary key (default) and U for a unique key
   * @return               whether the object has an active primary key (TRUE) or not (FALSE)
   */
  FUNCTION enabled_key
  (
    owner_in     type_defs.identifier_t
  , object_in    type_defs.identifier_t
  , key_type_in  all_constraints.constraint_type%TYPE := 'P'
  )
    RETURN BOOLEAN
  IS
    CURSOR key_cur
    (
      own_in  type_defs.identifier_t
    , obj_in  type_defs.identifier_t
    , key_in  all_constraints.constraint_type%TYPE
    )
    IS
      SELECT
        ac.*
      FROM
        all_constraints ac
      WHERE
        ac.constraint_type = key_in
      AND ac.owner         = own_in
      AND ac.table_name    = obj_in;

    l_key_rec  key_cur%ROWTYPE;

    l_key      BOOLEAN := FALSE;

  BEGIN
    OPEN key_cur (owner_in, object_in, key_type_in);
    FETCH key_cur INTO l_key_rec;

    IF ( key_cur%ROWCOUNT = 0 OR l_key_rec.status <> 'ENABLED')
    THEN
      l_key := FALSE;
    ELSE
      l_key := TRUE;
    END IF;

    CLOSE key_cur;

    RETURN l_key;

  EXCEPTION
    WHEN OTHERS THEN
      IF ( key_cur%ISOPEN )
      THEN
        CLOSE key_cur;
      END IF;
      RAISE;
  END enabled_key;



  /** Creates a new empty table in the same schema based on another table's structure, which includes all partition and storage clauses
   * but excludes constraints.
   * @param  owner_in              owner
   * @param  source_table_name_in  source table name
   * @param  target_table_name_in  target table name (in the same schema)
   */
  PROCEDURE copy_table_structure
  (
    owner_in              type_defs.identifier_t
  , source_table_name_in  type_defs.identifier_t
  , target_table_name_in  type_defs.identifier_t
  )
  IS
    l_handle            NUMBER;
    l_transform_handle  NUMBER;
    l_ddl_stmt          CLOB;
    lc_quoted_source    type_defs.identifier_t := SYS.DBMS_ASSERT.ENQUOTE_NAME(source_table_name_in);
    lc_quoted_target    type_defs.identifier_t := SYS.DBMS_ASSERT.ENQUOTE_NAME(target_table_name_in);
  BEGIN
    l_handle := SYS.DBMS_METADATA.OPEN('TABLE');

    SYS.DBMS_METADATA.SET_FILTER(l_handle, 'SCHEMA', owner_in);
    SYS.DBMS_METADATA.SET_FILTER(l_handle, 'NAME', source_table_name_in);

    l_transform_handle := SYS.DBMS_METADATA.ADD_TRANSFORM(l_handle, 'DDL');

    SYS.DBMS_METADATA.SET_TRANSFORM_PARAM(l_transform_handle , 'CONSTRAINTS', FALSE);
    SYS.DBMS_METADATA.SET_TRANSFORM_PARAM(l_transform_handle , 'REF_CONSTRAINTS', FALSE);

    l_ddl_stmt := REPLACE(SYS.DBMS_METADATA.FETCH_CLOB(l_handle),lc_quoted_source,lc_quoted_target);

    SYS.DBMS_METADATA.CLOSE(l_handle);

    plsql_utils.exec_ddl(l_ddl_stmt);
  END copy_table_structure;



  /** Obtains an associative array of primary-key or unique columns sorted by their position.
   * @param   owner_in        properly formatted owner
   * @param   object_in       properly formatted object name
   * @param   key_type_in     P for a primary key (default) and U for a unique key
   * @throws  ex_no_pk_found  if no primary key is enabled or exists at all
   * @return                  list of primary key columns
   */
  FUNCTION key_cols
  (
    owner_in     type_defs.identifier_t
  , object_in    type_defs.identifier_t
  , key_type_in  all_constraints.constraint_type%TYPE := 'P'
  )
    RETURN type_defs.identifier_aat
  IS
    CURSOR key_cols_cur
    (
      own_in  type_defs.identifier_t
    , obj_in  type_defs.identifier_t
    , key_in  all_constraints.constraint_type%TYPE
    )
    IS
      SELECT
        constraint_name, status, column_name, position
      FROM
        all_constraints NATURAL JOIN all_cons_columns
      WHERE
        constraint_type = key_in
      AND owner         = own_in
      AND table_name    = obj_in
      ORDER BY
        position;

    l_key_cols      type_defs.identifier_aat;

  BEGIN
    IF ( enabled_key(owner_in, object_in, key_type_in) )
    THEN
      FOR key_cols_rec IN key_cols_cur(owner_in, object_in, key_type_in)
      LOOP
        l_key_cols(key_cols_rec.position) := key_cols_rec.column_name;
      END LOOP;

      IF ( l_key_cols.COUNT = 0 )
      THEN
        RAISE_APPLICATION_ERROR( errors.en_no_pk_found, 'Cannot retrieve PK columns for >>' ||
                                 qualify(owner_in, object_in) || '<< because it does not exist.');
      END IF;
    ELSE
      RAISE_APPLICATION_ERROR( errors.en_no_pk_found, 'Cannot retrieve PK columns for >>' ||
                               qualify(owner_in, object_in) || '<< because it either has no PK, its PK is disabled, or it does not exist.');
    END IF;

    RETURN l_key_cols;

  END key_cols;



  /** Obtains an associative array of columns sorted by their position.
   * @param   owner_in           properly formatted owner
   * @param   object_in          properly formatted object name
   * @throws  ex_invalid_object  if the object does not exist
   * @return                     list of columns
   */
  FUNCTION all_cols
  (
    owner_in   type_defs.identifier_t
  , object_in  type_defs.identifier_t
  )
    RETURN type_defs.identifier_aat
  IS
    CURSOR cols_cur
    (
      own_in  type_defs.identifier_t
    , obj_in  type_defs.identifier_t
    )
    IS
      SELECT
        tc.*
      FROM
        all_tab_cols tc
      WHERE
        tc.owner        = own_in
      AND tc.table_name = obj_in
      AND tc.hidden_column = 'NO'
      ORDER BY
        tc.column_id;

    l_cols      type_defs.identifier_aat;

  BEGIN
    FOR cols_rec IN cols_cur(owner_in, object_in)
    LOOP
      l_cols(cols_rec.column_id) := cols_rec.column_name;
    END LOOP;

    IF ( l_cols.COUNT = 0 )
    THEN
      RAISE_APPLICATION_ERROR( errors.en_invalid_object, 'Cannot retrieve columns for >>' ||
                               qualify(owner_in, object_in) || '<< because it does not exist.');
    END IF;

    RETURN l_cols;

  END all_cols;



  /** Automatically fixes all data type issues listed in the view DATA_TYPE_ISSUES.
   * NB: The current user must have execution privileges on DBMS_REDEFINITION:
   * GRANT EXECUTE ON DBMS_REDEFINITION TO username;
   */
  PROCEDURE fix_data_type_issues
  IS
    CURSOR l_issue_cur IS SELECT * FROM data_type_issues;
    TYPE l_issues_ntt  IS TABLE OF l_issue_cur%ROWTYPE;
    l_issue            l_issue_cur%ROWTYPE;
    l_issues           l_issues_ntt;
    l_string           type_defs.string_t;
    l_qualified        type_defs.string_t;
    l_alt_qualified    type_defs.string_t;
    l_redef_errors     PLS_INTEGER := 0;

    /** Checks whether a table is a candidate for online redefinition with DBMS_REDEFINITION.
     * @param  owner_in          properly formatted owner
     * @param  table_name_in     properly formatted table name
     * @param  options_flag_out  value of DBMS_REDEFINITION's options_flag
     * @return                   TRUE if the table can be redefined online, FALSE otherwise
     */
    FUNCTION table_redefinable
    (
      owner_in         IN  type_defs.identifier_t
    , table_name_in    IN  type_defs.identifier_t
    , options_flag_out OUT PLS_INTEGER
    )
      RETURN BOOLEAN
      DETERMINISTIC
    IS
    BEGIN
      IF ( enabled_key(owner_in, table_name_in)  )
      THEN
        options_flag_out := SYS.DBMS_REDEFINITION.CONS_USE_PK;
      ELSE
        options_flag_out := SYS.DBMS_REDEFINITION.CONS_USE_ROWID;
      END IF;

      SYS.DBMS_REDEFINITION.CAN_REDEF_TABLE( uname => owner_in,
                                             tname => table_name_in,
                                             options_flag => options_flag_out );

      RETURN TRUE;

    EXCEPTION
      WHEN OTHERS THEN
        RETURN FALSE;
    END table_redefinable;

    /** Attempts to redefine a column's data type when both the original and new data types are not instantiable types
     * (i.e. INSTANTIABLE = 'NO').
     * NB: Requires advanced replication to be enabled, which can be checked as follows:
     * SELECT value FROM v$option WHERE parameter = 'Advanced replication'.
     * @param  owner_in         owner
     * @param  table_name_in    table name
     * @param  column_name_in   column name
     * @param  data_type_in     desired fully specified data type
     */
    PROCEDURE redefine_column
    (
      owner_in         type_defs.identifier_t
    , table_name_in    type_defs.identifier_t
    , column_name_in   type_defs.identifier_t
    , data_type_in     type_defs.type_t
    )
    IS
      l_num_errors         PLS_INTEGER;
      l_options_flag       PLS_INTEGER;
      lc_qualified         CONSTANT type_defs.string_t := qualify(owner_in, table_name_in);
      lc_random_identifier CONSTANT VARCHAR2(15)       := SYS.DBMS_RANDOM.STRING('U',5) || SYS.DBMS_RANDOM.STRING('X',10);
      lc_copy_table_name   CONSTANT VARCHAR2(25)       := 'COPY_TAB_' || lc_random_identifier;
    BEGIN
      -- When the source table is empty we can change the data type with a simple ALTER TABLE statement.
      -- When the source table is not empty we have to do an online redefinition with DBMS_REDEFINITION.
      IF ( table_empty(owner_in, table_name_in) )
      THEN
        exec_ddl( 'ALTER TABLE ' || table_name_in ||
                  ' MODIFY ( ' || column_name_in || '  ' || data_type_in || ' )' );
      ELSE
        IF ( table_redefinable(owner_in, table_name_in, l_options_flag) )
        THEN
          copy_table_structure(owner_in, table_name_in, lc_copy_table_name);

          -- Fix the structure of the newly created (empty) interim table.
          exec_ddl( 'ALTER TABLE ' || lc_copy_table_name ||
                    ' MODIFY ( ' || column_name_in || '  ' || data_type_in || ' )' );

          -- Column mapping is assumed to be simple (one-to-one), hence NULL.
          SYS.DBMS_REDEFINITION.START_REDEF_TABLE( uname => owner_in,
                                                   orig_table => table_name_in,
                                                   int_table => lc_copy_table_name,
                                                   col_mapping => NULL,
                                                   options_flag => l_options_flag );

          SYS.DBMS_REDEFINITION.COPY_TABLE_DEPENDENTS( uname => owner_in,
                                                       orig_table => table_name_in,
                                                       int_table => lc_copy_table_name,
                                                       copy_indexes => SYS.DBMS_REDEFINITION.CONS_ORIG_PARAMS,
                                                       copy_triggers => TRUE,
                                                       copy_constraints => TRUE,
                                                       copy_privileges => TRUE,
                                                       ignore_errors => TRUE,
                                                       num_errors => l_num_errors );

          IF ( l_num_errors > 0 ) THEN
            RAISE_APPLICATION_ERROR( errors.en_redef_copy_dependents,
                                     'An issue was encountered during the copying of dependent objects for >>' || lc_qualified ||
                                     '<< while running DBMS_REDEFINITION. ' ||
                                     'Please check DBA_REDEFINITION_ERRORS for more details.' );
          END IF;

          SYS.DBMS_REDEFINITION.SYNC_INTERIM_TABLE(owner_in, table_name_in, lc_copy_table_name);

          SYS.DBMS_REDEFINITION.FINISH_REDEF_TABLE(owner_in, table_name_in, lc_copy_table_name);

          drop_object(owner_in, lc_copy_table_name);
        -- When the source table cannot be redefined online, an exception is thrown.
        ELSE
          RAISE_APPLICATION_ERROR( errors.en_table_unredefinable, 'Cannot redefine the table >>' ||
                                   lc_qualified || 'online with DBMS_REDEFINITION. ' ||
                                   'Please investigate manually.' );
        END IF;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      SYS.DBMS_REDEFINITION.ABORT_REDEF_TABLE(owner_in, table_name_in, lc_copy_table_name);
      drop_object(owner_in, lc_copy_table_name);
      RAISE;
    END redefine_column;

  BEGIN
    OPEN l_issue_cur;
    LOOP
      FETCH l_issue_cur BULK COLLECT INTO l_issues LIMIT gc_fetch_limit;

      FOR rec IN 1 .. l_issues.COUNT
      LOOP
        l_issue := l_issues(rec);
        l_qualified := qualify(l_issue.owner, l_issue.table_name);
        l_alt_qualified := qualify(l_issue.alt_owner, l_issue.alt_table_name);

        display(l_alt_qualified || ': ', 0);
        l_string := l_issue.column_name || ' - ' || l_issue.alt_full_data_type ||
                    ' [' || l_issue.alt_num_tabs || 'x]' ||
                    CASE WHEN l_issue.num_tabs > l_issue.alt_num_tabs THEN ' -> ' ELSE ' <-> ' END;
        display(l_string, 1);
        l_string := l_issue.full_data_type ||
                    ' [' || l_issue.num_tabs || 'x]';
        display(l_string, 2);

        -- When there is a clear preferred data type, we can attempt to redefine the table for simple data types.
        IF ( l_issue.num_tabs > l_issue.alt_num_tabs )
        THEN
          IF ( custom_type(l_issue.data_type) OR custom_type(l_issue.alt_data_type) )
          THEN
            l_string := 'Custom data types cannot be automatically redefined at present.';
            display(l_string, 1);
          ELSE
            BEGIN
              redefine_column(l_issue.alt_owner, l_issue.alt_table_name, l_issue.column_name, l_issue.full_data_type);

              l_string := 'Successfully redefined.';
              display(l_string, 1);
            EXCEPTION
              WHEN OTHERS THEN
              l_redef_errors := l_redef_errors + 1;
              l_string := 'Encountered an error during the redefinition.';
              display(l_string, 1);
              errors.log_and_continue();
            END;
          END IF;
        -- When both data types are equally prevalent, we cannot automatically decide on the data type for the redefinition.
        ELSE
          l_string := 'Ties cannot be resolved automatically, please redefine manually.';
          display(l_string, 1);
        END IF;

      END LOOP;
      EXIT WHEN l_issue_cur%NOTFOUND;
    END LOOP;

    CLOSE l_issue_cur;

    IF ( l_redef_errors > 0 )
    THEN
      l_string := 'NOTE: Redefinition errors were encountered, please review these [' || l_redef_errors || 'x] manually.';
      display(l_string,0);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      IF ( l_issue_cur%ISOPEN )
      THEN
        CLOSE l_issue_cur;
      END IF;
      RAISE;
  END fix_data_type_issues;

END plsql_utils;
