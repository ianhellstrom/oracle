/**
 * Databaseline code repository
 *
 * Code for post: ETL: A Simple Package to Load Data from Views
 * Compatibility: Oracle Database 10g Release 1 and above
 * Base URL:      https://databaseline.bitbucket.io
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1 (in ERRORS)
 */

CREATE OR REPLACE TRIGGER etl_conf_bef_ins
BEFORE INSERT ON etl_conf
FOR EACH ROW
DECLARE
  l_src_db_cnt  PLS_INTEGER;
  l_src_tab_cnt PLS_INTEGER;
  l_tgt_tab_cnt PLS_INTEGER;
  l_db_link     all_db_links.db_link%TYPE;
  l_src_db      all_db_links.db_link%TYPE;
  l_src_own     all_tables.owner%TYPE;
  l_src_obj     all_tables.table_name%TYPE;
  l_tgt_own     all_tables.owner%TYPE;
  l_tgt_obj     all_tables.table_name%TYPE;
BEGIN
  l_src_db  := UPPER(:NEW.source_db);
  l_src_own := UPPER(:NEW.source_own);
  l_src_obj := UPPER(:NEW.source_obj);
  l_tgt_own := UPPER(:NEW.target_own);
  l_tgt_obj := UPPER(:NEW.target_obj);

  -- Check whether DB link is valid.
  IF ( l_src_db IS NOT NULL )
  THEN
    l_db_link := '@' || l_src_db;
    l_src_db := l_src_db || '%';

    SELECT COUNT(*)
    INTO l_src_db_cnt
    FROM all_db_links
    WHERE db_link LIKE l_src_db;

    IF ( l_src_db_cnt = 0 )
    THEN
      RAISE_APPLICATION_ERROR(errors.en_invalid_db_link,
        'Cannot insert row because the DB link >>' || l_src_db || '<< is not defined.');
    END IF;
  ELSE
    l_db_link := '';
  END IF;

  -- Check whether source table is valid.
  EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM all_objects' || l_db_link ||
                    ' WHERE owner = :own AND object_name = :obj'
    INTO l_src_tab_cnt USING l_src_own, l_src_obj;

  IF ( l_src_tab_cnt = 0 )
  THEN
    RAISE_APPLICATION_ERROR(errors.en_invalid_tab_name,
      'Cannot insert row because the source table >>' || l_src_own || '.' || l_src_obj || '<< does not exist or cannot be queried.');
  END IF;

  -- Check whether target table is valid.
  EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM all_objects' ||
                    ' WHERE owner = :own AND object_name = :obj'
    INTO l_tgt_tab_cnt USING l_tgt_own, l_tgt_obj;

  IF ( l_tgt_tab_cnt = 0 )
  THEN
    RAISE_APPLICATION_ERROR(errors.en_invalid_tab_name,
      'Cannot insert row because the target table >>' || l_tgt_own || '.' || l_tgt_obj || '<< does not exist or cannot be queried.');
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    errors.log_and_stop();

END etl_conf_bef_ins;