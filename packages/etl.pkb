/**
 * Databaseline code repository
 *
 * Code for post: ETL: A Simple Package to Load Data from Views
 * Compatibility: Oracle Database 10g Release 1 and above
 *                Oracle Database 9i Release 1 and above (with minor modifications)
 * Base URL:      http://databaseline.wordpress.com
 * Post URL:      http://wp.me/p4zRKC-6F
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1 (in ERRORS)
 *                CASE statements are available from 9.0
 */
 
CREATE OR REPLACE PACKAGE BODY etl
AS
  PRAGMA SERIALLY_REUSABLE;
  
  /** Reads the configuration for a particular target table from ETL_CONF.
   * @param   owner_in                 owner (i.e. schema) of the target table
   * @param   table_in                 target table identifier
   * @return                           configuration record from ETL_CONF
   */  
  FUNCTION tab_conf
    (
      owner_in  etl_conf.target_own%TYPE
    , table_in  etl_conf.target_obj%TYPE
    )
    RETURN etl_conf%ROWTYPE
  IS
    l_tab_conf  etl_conf%ROWTYPE;
  BEGIN
    SELECT *
    INTO   l_tab_conf
    FROM   etl_conf
    WHERE  target_own = UPPER(owner_in)
           AND target_obj = UPPER(table_in);
    
    RETURN l_tab_conf;

  EXCEPTION
    WHEN OTHERS THEN
      errors.log_and_continue();    
  END tab_conf;
  


  /** Gets a full concatenated list of columns for a particular table.
   * @param   owner_in                 owner (i.e. schema) of the table or view
   * @param   table_in                 table or view identifier
   * @return                           comma-separated list of columns
   */  
  FUNCTION tab_cols_list
    (
      owner_in  etl_conf.target_own%TYPE
    , table_in  etl_conf.target_obj%TYPE
    )
    RETURN type_defs.string_t
  IS
    l_cols_list type_defs.string_t; 
  BEGIN
    -- ALL_TAB_COLS includes disabled columns (HIDDEN_COLUMN='YES')
    -- ALL_TAB_COLUMNS only includes enabled columns
    SELECT LISTAGG(column_name,',') 
             WITHIN GROUP (ORDER BY column_id) 
    INTO   l_cols_list
    FROM   all_tab_columns
    WHERE  owner = UPPER(owner_in)
           AND table_name = UPPER(table_in);

    RETURN l_cols_list;
  
  EXCEPTION
    WHEN OTHERS THEN
      errors.log_and_continue();
    
  END tab_cols_list;



  /** Adds an entry to the execution log ETL_EXEC_LOG.
   * @param   inst_in                  current instant (i.e. time stamp)
   * @param   owner_in                 owner (i.e. schema) of object loaded
   * @param   object_in                object identifier, typically a table from ETL_CONF but can also include clean-up entries
   * @param   num_ins_in               number of rows inserted
   * @param   num_del_in               number of rows deleted
   * @param   success_in               whether the attempt to load data was successful ('Y') or not ('N')
   * @param   elapsed_in               time taken to execute data load for current object
   */  
  PROCEDURE add_load_entry
  (
    inst_in      etl_exec_log.load_inst%TYPE    := SYSTIMESTAMP
  , owner_in     etl_exec_log.load_owner%TYPE
  , object_in    etl_exec_log.load_object%TYPE
  , num_ins_in   etl_exec_log.num_inserted%TYPE := 0
  , num_del_in   etl_exec_log.num_deleted%TYPE  := 0
  , success_in   etl_exec_log.is_success%TYPE   := 'Y'
  , elapsed_in   etl_exec_log.elapsed_time%TYPE
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    SAVEPOINT before_insert;
    INSERT INTO etl_exec_log(load_inst, 
                             load_owner, load_object, 
                             num_inserted, num_deleted,
                             is_success, elapsed_time)
    VALUES ( inst_in,
             UPPER(owner_in), UPPER(object_in),
             num_ins_in, num_del_in,
             success_in, elapsed_in );
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK TO before_insert;
    errors.log_and_continue();  
  END;



  /** Purges old data from a log table.
   * @param   own_in                 owner (i.e. schema) of object
   * @param   tab_in                 log table identifier
   * @param   col_in                 column identifier to be used for purge based on days_in
   * @param   days_in                how many days to keep in the log table
   * @throws  ex_invalid_value       if days_in is zero or negative
   */  
  PROCEDURE cleanup
  (
    own_in  VARCHAR2 := SYS_CONTEXT('USERENV','CURRENT_SCHEMA')
  , tab_in  VARCHAR2
  , col_in  VARCHAR2
  , days_in NUMBER   := 100
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_num_del PLS_INTEGER;
    l_begin   TIMESTAMP;
  BEGIN 
    IF ( days_in <= 0 ) 
    THEN
      RAISE_APPLICATION_ERROR(errors.en_invalid_value, 
                              'An invalid value for days_in (> 0) was supplied: >>' || days_in || '<<.');
    END IF;
  
    l_begin := SYSTIMESTAMP;

    SAVEPOINT before_cleanup;
  
    EXECUTE IMMEDIATE 'DELETE FROM ' || UPPER(own_in) || '.' || UPPER(tab_in) ||
                      ' WHERE ' || UPPER(col_in) || ' < TRUNC(SYSTIMESTAMP - ' || CEIL(days_in) || ',''DD'')';
    
    l_num_del := SQL%ROWCOUNT;
    
    COMMIT;

    add_load_entry( inst_in => SYSTIMESTAMP,
                    owner_in => UPPER(own_in), 
                    object_in => UPPER(tab_in) || '/CLEANUP',
                    num_ins_in => 0, 
                    num_del_in => NVL(l_num_del,0),
                    success_in => 'Y',
                    elapsed_in => SYSTIMESTAMP - l_begin );
  
  EXCEPTION
    WHEN errors.ex_invalid_value THEN
      add_load_entry( inst_in => SYSTIMESTAMP,
                      owner_in => UPPER(own_in), 
                      object_in => UPPER(tab_in) || '/CLEANUP',
                      num_ins_in => 0, 
                      num_del_in => 0,
                      success_in => 'N',
                      elapsed_in => SYSTIMESTAMP - l_begin );
      errors.log_and_stop();
    WHEN OTHERS THEN
      ROLLBACK TO before_cleanup;
      add_load_entry( inst_in => SYSTIMESTAMP,
                      owner_in => UPPER(own_in) || '/CLEANUP', 
                      object_in => UPPER(tab_in) || '/CLEANUP',
                      num_ins_in => 0, 
                      num_del_in => 0,
                      success_in => 'N',
                      elapsed_in => SYSTIMESTAMP - l_begin );
      errors.log_and_continue();
  END;



  /** Loads a particular table from its reference (source) view/table.
   * @param   target_own_in           owner (i.e. schema) of the target table
   * @param   target_obj_in           target table identifier
   */  
  PROCEDURE load_tab_from_view
  (
    target_own_in   etl_conf.target_own%TYPE
  , target_obj_in   etl_conf.target_obj%TYPE
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  
    l_conf       etl_conf%ROWTYPE;
    l_cols_list  type_defs.string_t;
    l_num_ins    PLS_INTEGER;
    l_num_del    PLS_INTEGER;
    l_begin      TIMESTAMP;
  BEGIN
    l_begin     := SYSTIMESTAMP;
  
    l_conf      := tab_conf(owner_in => target_own_in, table_in => target_obj_in);
    l_cols_list := tab_cols_list(owner_in => target_own_in, table_in => target_obj_in);
    
    SAVEPOINT before_load_attempt;
    
    -- Empty table for refresh or purge stale data.
    IF ( l_conf.load_method = 'REF' ) 
    THEN
      EXECUTE IMMEDIATE 'DELETE FROM ' || l_conf.target_own || '.' || l_conf.target_obj;
      
      l_num_del := SQL%ROWCOUNT;
      
    ELSIF ( l_conf.archive_col_name IS NOT NULL )
    THEN
      EXECUTE IMMEDIATE 'DELETE FROM ' || l_conf.target_own || '.' || l_conf.target_obj ||
                        ' WHERE ' || l_conf.archive_col_name || l_conf.archive_col_oper || l_conf.archive_col_value;
  
      l_num_del := SQL%ROWCOUNT;
  
    END IF;
    
    -- Insert fresh data.
    EXECUTE IMMEDIATE 'INSERT INTO ' || l_conf.target_own || '.' || l_conf.target_obj ||
                      '(' || l_cols_list || ')' ||
                      ' SELECT ' || l_cols_list ||
                      ' FROM ' || l_conf.source_own || '.' || l_conf.source_obj || 
                      CASE 
                        WHEN l_conf.source_db IS NOT NULL
                        THEN '@' || l_conf.source_db
                        ELSE ''
                      END;    
  
    l_num_ins := SQL%ROWCOUNT;
  
    COMMIT;
  
    add_load_entry( inst_in => SYSTIMESTAMP,
                    owner_in => l_conf.target_own, 
                    object_in => l_conf.target_obj,
                    num_ins_in => NVL(l_num_ins,0), 
                    num_del_in => NVL(l_num_del,0),
                    success_in => 'Y',
                    elapsed_in => SYSTIMESTAMP - l_begin );
     
  EXCEPTION
    WHEN errors.ex_invalid_db_link THEN
      ROLLBACK TO before_load_attempt;
      errors.log_and_stop(SQLCODE, 'Issue with loading of ' || l_conf.target_own || '.' || l_conf.target_obj || 
                          ' because the database link >> ' || l_conf.source_db || '<< is invalid.');
    WHEN errors.ex_invalid_tns_name THEN
      ROLLBACK TO before_load_attempt;
      errors.log_and_stop(SQLCODE, 'Issue with loading of ' || l_conf.target_own || '.' || l_conf.target_obj || 
                          ' because the database TNS/connection string for the database link >> ' || l_conf.source_db || '<< is invalid.');
    WHEN errors.ex_invalid_tab_name THEN
      ROLLBACK TO before_load_attempt;
      errors.log_and_stop(SQLCODE, 'Issue with loading of ' || l_conf.target_own || '.' || l_conf.target_obj || 
                          ' because the table is invalid or the permissions to query from it have not been set properly.');
    WHEN errors.ex_invalid_col_name THEN
      ROLLBACK TO before_load_attempt;
      errors.log_and_stop(SQLCODE, 'Issue with loading of ' || l_conf.target_own || '.' || l_conf.target_obj || 
                          ' because the column names of the source table/view do not match the columns in the target table.');      
    WHEN OTHERS THEN
      ROLLBACK TO before_load_attempt;
      add_load_entry( inst_in => SYSTIMESTAMP,
                      owner_in => l_conf.target_own, 
                      object_in => l_conf.target_obj,
                      num_ins_in => 0, 
                      num_del_in => 0,
                      success_in => 'N',
                      elapsed_in => SYSTIMESTAMP - l_begin );
      errors.log_and_stop(SQLCODE, 'Issue with loading of ' || l_conf.target_own || '.' || l_conf.target_obj);
  END load_tab_from_view;


  
  /** Checks whether an object is in a valid state.
   * @param   db_in                  database link
   * @param   owner_in               owner (i.e. schema) of the object
   * @param   object_in              object identifier
   * @return                         whether the object is valid
   */  
  FUNCTION is_object_valid
  (
    db_in    VARCHAR2
  , owner_in VARCHAR2
  , object_in VARCHAR2
  )
  RETURN BOOLEAN
  IS
    TYPE cursor_t IS REF CURSOR;
    l_obj_cur     cursor_t;
    l_object      all_objects%ROWTYPE;
    l_status      all_objects.status%TYPE;
    l_db_link     etl_conf.source_db%TYPE := '';
    l_sql         type_defs.string_t;
    l_return      BOOLEAN := FALSE;
  BEGIN
    IF (db_in IS NOT NULL)
    THEN
      l_db_link := '@' || UPPER(db_in);
    END IF;
    
    l_sql := 'SELECT * FROM all_objects' || l_db_link || ' WHERE owner = :owner AND object_name = :object';  
  
    OPEN l_obj_cur FOR l_sql USING owner_in, object_in;
  
    FETCH l_obj_cur INTO l_object;
    
    IF (l_object.status = 'VALID' AND l_obj_cur%FOUND)
    THEN
      l_return := TRUE;
    END IF;

    CLOSE l_obj_cur;
  
    RETURN l_return;
  
  EXCEPTION
    WHEN OTHERS THEN
      IF l_obj_cur%ISOPEN
      THEN
        CLOSE l_obj_cur;
      END IF;
      errors.log_and_stop();
  END is_object_valid;



  /** Attempts to recompile a non-remote object.
   * @param   owner_in               owner (i.e. schema) of the object
   * @param   object_in              object identifier
   */  
  PROCEDURE recompile
  (
    owner_in VARCHAR2
  , object_in VARCHAR2
  )
  IS
    l_object      all_objects%ROWTYPE;
  BEGIN
    SELECT *
    INTO   l_object
    FROM   all_objects
    WHERE  owner = UPPER(owner_in)
    AND    object_name = UPPER(object_in);

    EXECUTE IMMEDIATE 'ALTER ' || l_object.object_type || ' ' ||
                      l_object.owner || '.' || l_object.object_name || ' COMPILE';  
   
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      errors.log_and_stop(SQLCODE, 'Cannot recompile >>' || 
                          owner_in || '.' || object_in || '<< because no such object exists in the current database.');
    WHEN OTHERS THEN
      errors.log_and_stop();
  END recompile;



  /** Checks the validity of all source objects in ETL_CONF and attempts to recompile invalid objects on the fly.
   * NB: Recompilation through database links is not supported because typically remote database accessed with 
   * read-only privileges.
   * @throws  ex_unrecompilable      if the object cannot be recompiled automatically
   */  
  PROCEDURE check_validity
  IS
    TYPE tab_conf_nt IS TABLE OF etl_conf%ROWTYPE;  
    TYPE objects_nt  IS TABLE OF all_objects%ROWTYPE;
  
    l_tab_conf       tab_conf_nt;
    l_objects        objects_nt;
    l_invalid        objects_nt;
    l_ex_reason      error_log.message%TYPE;
  BEGIN
    FOR rec IN (SELECT * FROM etl_conf)
    LOOP
      IF ( etl.is_object_valid(db_in => rec.source_db,
                               owner_in => rec.source_own,
                               object_in => rec.source_obj) )
      THEN
        NULL; -- already OK.
      ELSE
        etl.recompile(owner_in => rec.source_own,
                      object_in => rec.source_obj);
  
        IF ( etl.is_object_valid(db_in => rec.source_db,
                                 owner_in => rec.source_own,
                                 object_in => rec.source_obj) )
        THEN
          NULL; -- OK after recompilation.
        ELSE
          IF (rec.source_db IS NOT NULL)
          THEN
            l_ex_reason := ' cannot be recompiled through a database link with limited (read-only) privileges.';
          ELSE
            l_ex_reason := ' cannot be recompiled, probably because of a dependency on an invalid object.';
          END IF;
          RAISE_APPLICATION_ERROR( errors.en_unrecompilable, 
                                   rec.source_own || '.' || rec.source_obj || l_ex_reason );
        END IF;
      END IF;
    END LOOP;
  END check_validity;



  /** Loads all enabled tables from a particular category in the proper sequence.
   * @param   category_in            load configuration category (from ETL_CONF)
   * @param   resume_load_at_in      load order sequence number to resume the load from
   */  
  PROCEDURE load_all_tabs
  (
    category_in        etl_conf.load_category%TYPE := NULL
  , resume_load_at_in  etl_conf.load_order%TYPE    := NULL
  )
  IS
    l_sql           type_defs.string_t := 'SELECT * FROM etl_conf WHERE is_active = ''Y'' ';
    l_sql_cat       VARCHAR2(100)  := 'AND load_category = UPPER(:category) ';
    l_sql_seq       VARCHAR2(100)  := 'AND load_order >= (:resume) ';
    l_sql_sort      VARCHAR2(50)   := 'ORDER BY load_category, load_order';
    l_tab_conf_cur  SYS_REFCURSOR;
    l_tab_conf_rec  etl_conf%ROWTYPE;
  BEGIN
    check_validity();

    IF ( category_in IS NULL )
    THEN
      IF ( resume_load_at_in IS NULL )
      THEN
        OPEN l_tab_conf_cur FOR l_sql || l_sql_sort;
      ELSE
        OPEN l_tab_conf_cur FOR l_sql || l_sql_seq || l_sql_sort USING resume_load_at_in;
      END IF;
    ELSE
      IF ( resume_load_at_in IS NULL )
      THEN
        OPEN l_tab_conf_cur FOR l_sql || l_sql_cat || l_sql_sort USING category_in;
      ELSE
        OPEN l_tab_conf_cur FOR l_sql || l_sql_cat || l_sql_seq || l_sql_sort USING category_in, resume_load_at_in;
      END IF;
    END IF;

    LOOP
      FETCH l_tab_conf_cur INTO l_tab_conf_rec;
      EXIT WHEN l_tab_conf_cur%NOTFOUND;
      load_tab_from_view(target_own_in => l_tab_conf_rec.target_own, 
                         target_obj_in => l_tab_conf_rec.target_obj);
    END LOOP;
    
    CLOSE l_tab_conf_cur;

    cleanup(tab_in => 'ERROR_LOG',
            col_in => 'CREATED_ON');
    cleanup(tab_in => 'ETL_CONF_LOG',
            col_in => 'MODIFIED_ON');
    cleanup(tab_in => 'ETL_EXEC_LOG',
            col_in => 'LOAD_INST');

  EXCEPTION
    WHEN OTHERS THEN
      CLOSE l_tab_conf_cur;
      errors.log_and_stop(SQLCODE, 'Issue with loading of ' || 
                          l_tab_conf_rec.target_own || '.' || l_tab_conf_rec.target_obj ||
                          ' with SQL statement: ' || l_sql);
  END load_all_tabs;

END etl;