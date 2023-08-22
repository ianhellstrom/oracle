/**
 * Code for post: ETL: A Simple Package to Load Data from Views
 * Compatibility: Oracle Database 10g Release 1 and above
 * Base URL:      https://ianhellstrom.org
 * Author:        Ian Hellström
 *
 * Notes:         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE is available from 10.1 (in ERRORS)
 */

CREATE OR REPLACE TRIGGER etl_conf_aft_mod
AFTER INSERT OR UPDATE OR DELETE ON etl_conf
FOR EACH ROW
DECLARE
  l_type              VARCHAR2(10);
  l_mods              VARCHAR2(4000);
  l_date              TIMESTAMP    := SYSTIMESTAMP;
  l_user              VARCHAR2(50) := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  l_host              VARCHAR2(50) := SYS_CONTEXT('USERENV', 'HOST');
  l_module            VARCHAR2(50) := SYS_CONTEXT('USERENV', 'MODULE');
  l_os_user           VARCHAR2(50) := SYS_CONTEXT('USERENV', 'OS_USER');
BEGIN
  IF INSERTING
  THEN
    l_type := 'INSERT';
    l_mods := NVL(:NEW.source_db,'NULL') || ',' ||
              :NEW.source_own || ',' ||
              :NEW.source_obj || ',' ||
              :NEW.target_own || ',' ||
              :NEW.target_obj || ',' ||
              :NEW.load_order || ',' ||
              :NEW.load_method || ',' ||
              :NEW.load_category || ',' ||
              :NEW.is_active || ',' ||
              NVL(:NEW.archive_col_name,'NULL') || ',' ||
              NVL(:NEW.archive_col_oper,'NULL') || ',' ||
              NVL(:NEW.archive_col_value,'NULL');
  ELSIF DELETING
  THEN
    l_type := 'DELETE';
    l_mods := NVL(:OLD.source_db,'NULL') || ',' ||
              :OLD.source_own || ',' ||
              :OLD.source_obj || ',' ||
              :OLD.target_own || ',' ||
              :OLD.target_obj || ',' ||
              :OLD.load_order || ',' ||
              :OLD.load_method || ',' ||
              :OLD.load_category || ',' ||
              :OLD.is_active || ',' ||
              NVL(:OLD.archive_col_name,'NULL') || ',' ||
              NVL(:OLD.archive_col_oper,'NULL') || ',' ||
              NVL(:OLD.archive_col_value,'NULL');

  ELSE
    l_type := 'UPDATE';
    l_mods := '';

    IF (NVL(:OLD.source_db,'NULL') <> NVL(:NEW.source_db,'NULL')) THEN
      l_mods := l_mods || 'SOURCE_DB: ' || NVL(:OLD.source_db,'NULL') || '>' || NVL(:NEW.source_db,'NULL') || ',';
    END IF;

    IF (:OLD.source_own <> :NEW.source_own) THEN
      l_mods := l_mods || 'SOURCE_DB: ' || NVL(:OLD.source_own,'NULL') || '>' || NVL(:NEW.source_own,'NULL') || ',';
    END IF;

    IF (:OLD.source_obj <> :NEW.source_obj) THEN
      l_mods := l_mods || 'SOURCE_OBJ: ' || NVL(:OLD.source_obj,'NULL') || '>' || NVL(:NEW.source_obj,'NULL') || ',';
    END IF;

    IF (:OLD.target_own <> :NEW.target_own) THEN
      l_mods := l_mods || 'TARGET_OWN: ' || NVL(:OLD.target_own,'NULL') || '>' || NVL(:NEW.target_own,'NULL') || ',';
    END IF;

    IF (:OLD.target_obj <> :NEW.target_obj) THEN
      l_mods := l_mods || 'TARGET_OBJ: ' || NVL(:OLD.target_obj,'NULL') || '>' || NVL(:NEW.target_obj,'NULL') || ',';
    END IF;

    IF (:OLD.load_order <> :NEW.load_order) THEN
      l_mods := l_mods || 'LOAD_ORDER: ' || :OLD.load_order || '>' || :NEW.load_order || ',';
    END IF;

    IF (:OLD.load_method <> :NEW.load_method) THEN
      l_mods := l_mods || 'LOAD_METHOD: ' || NVL(:OLD.load_method,'NULL') || '>' || NVL(:NEW.load_method,'NULL') || ',';
    END IF;

    IF (:OLD.load_category <> :NEW.load_category) THEN
      l_mods := l_mods || 'LOAD_CATEGORY: ' || NVL(:OLD.load_category,'NULL') || '>' || NVL(:NEW.load_category,'NULL') || ',';
    END IF;

    IF (:OLD.is_active <> :NEW.is_active) THEN
      l_mods := l_mods || 'IS_ACTIVE: ' || NVL(:OLD.is_active,'NULL') || '>' || NVL(:NEW.is_active,'NULL') || ',';
    END IF;

    IF (NVL(:OLD.archive_col_name,'NULL') <> NVL(:NEW.archive_col_name,'NULL')) THEN
      l_mods := l_mods || 'ARCHIVE_COL_NAME: ' || NVL(:OLD.archive_col_name,'NULL') || '>' || NVL(:NEW.archive_col_name,'NULL') || ',';
    END IF;

    IF (NVL(:OLD.archive_col_oper,'NULL') <> NVL(:NEW.archive_col_oper,'NULL')) THEN
      l_mods := l_mods || 'ARCHIVE_COL_OPER: ' || NVL(:OLD.archive_col_oper,'NULL') || '>' || NVL(:NEW.archive_col_oper,'NULL') || ',';
    END IF;

    IF (NVL(:OLD.archive_col_value,'NULL') <> NVL(:NEW.archive_col_value,'NULL')) THEN
      l_mods := l_mods || 'ARCHIVE_COL_VALUE: ' || NVL(:OLD.archive_col_value,'NULL') || '>' || NVL(:NEW.archive_col_value,'NULL') || ',';
    END IF;

    l_mods := RTRIM(l_mods,',');
  END IF;

  INSERT INTO etl_conf_log(target_own, target_obj, modified_on, modified_by, modified_through, modification_type, modifications)
  VALUES
  (
    COALESCE(:NEW.target_own,:OLD.target_own)
  , COALESCE(:NEW.target_obj,:OLD.target_obj)
  , l_date
  , SUBSTR(l_user || ': ' || l_os_user,1,100)
  , SUBSTR(l_host || ': ' || l_module,1,100)
  , l_type
  , l_mods
  );
EXCEPTION
  WHEN OTHERS THEN
  errors.log_and_stop();
END etl_conf_aft_mod;