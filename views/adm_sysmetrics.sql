/**
 * Databaseline code repository
 *
 * Code for post: N/A
 * Compatibility: Oracle Database 11g Release 1
 * Base URL:      http://databaseline.wordpress.com
 * Post URL:      N/A
 * Author:        Ian Hellström
 *
 * Notes:         PIVOT is available from 11.1
 */

CREATE OR REPLACE VIEW adm_sysmetrics
AS
   SELECT /* Shows important database system metrics for the last 365 days, as available in
           * DBA_HIST_SYSMETRIC_SYMMARY, in a row-based format that is best suited to
           * in-depth (statistical) analyses to track down performance issues.
           *
           * Abbreviations used in the column names:
           * ALLOC - allocated/allocation
           * BCKGRD - background
           * BLCK - block(s)
           * CHKPTS - checkpoints
           * CHG - changes
           * CONS - consistent
           * CR - consistent read
           * CURR - current
           * CURS - cursor(s)
           * DB - database
           * DBWR - database writer
           * DOWNGR - downgraded
           * DRCT - direct
           * EXECS - executions
           * IDX - index
           * ICONN - interconnect
           * LIM - limit
           * NETW - network
           * PCT - percentage
           * PHYS - physical
           * PGA - parallel global area
           * PQ - parallel query
           * PX - parallel execution
           * QC - query coordinator
           * R - read(s)
           * RBCK - rollbacks
           * RECS - records
           * REQS - requests
           * RESP - response
           * SRVC - service
           * SYNC - synchronous
           * TAB - table
           * TOT - total
           * TXN - transaction
           * USG - usage
           * USR - user
           * UTIL - utilization
           * VOL - volume
           * W - write(s)
           *
           * More details about the metrics can be found in the Oracle Database Concepts
           * guide.
           *
           * 2014-03-13 Christian Hellström (MFE): - created view.
           * 2014-03-28 Christian Hellström (MFE): - changed columns to be more consistent.
           * 2015-04-07 Christian Hellström (MFE): - removed superfluous columns.
           */
           begin_time
         , active_parallel_sessions
         , active_serial_sessions
         , avg_active_sessions
         , avg_sync_blck_r_latency
         , bckgrd_chkpts_per_sec
         , branch_node_splits_per_txn
         , buffer_cache_hit_ratio
         , cell_phys_io_iconn_bytes
         , cons_r_chg_per_txn
         , cons_r_gets_per_txn
         , 10 * cpu_usg_per_txn AS cpu_usg_per_txn
         , cr_blck_created_per_txn
         , cr_undo_recs_per_txn
         , curr_logons_count
         , curr_open_curs_count
         , curr_os_load
         , curs_cache_hit_ratio
         , db_blck_chg_per_txn
         , db_blck_gets_per_txn
         , db_cpu_time_ratio
         , db_wait_time_ratio
         , dbwr_chkpts_per_sec
         , disk_sort_per_txn
         , enqueue_reqs_per_txn
         , enqueue_timeouts_per_txn
         , enqueue_waits_per_txn
         , execs_per_txn
         , execs_without_parse_ratio
         , full_idx_scans_per_txn
         , hard_parse_count_per_txn
         , host_cpu_util
         , io_mb_per_sec
         , io_reqs_per_sec
         , leaf_node_splits_per_txn
         , library_cache_hit_ratio
         , logical_r_per_txn
         , logons_per_txn
         , long_tab_scans_per_txn
         , memory_sorts_ratio
         , netw_traffic_vol_per_sec
         , open_curs_per_txn
         , parse_fail_count_per_txn
         , pga_cache_hit_ratio
         , phys_r_drct_per_txn
         , phys_r_per_txn
         , phys_r_tot_bytes_per_sec
         , phys_w_drct_per_txn
         , phys_w_per_txn
         , phys_w_tot_bytes_per_sec
         , pq_qc_session_count
         , pq_slave_session_count
         , px_downgraded_25_per_sec + px_downgraded_50_per_sec + px_downgraded_75_per_sec + px_downgraded_99_per_sec + px_downgraded_serial_per_sec AS px_ops_downgr_per_sec
         , px_ops_not_downgr_per_sec
         , queries_parallelized_per_sec
         , recursive_calls_per_txn
         , redo_alloc_hit_ratio
         , redo_generated_per_txn
         , redo_w_per_txn
         , 10 * resp_time_per_txn AS resp_time_per_txn
         , row_cache_hit_ratio
         , rows_per_sort
         , session_count
         , shared_pool_free_pct
         , soft_parse_ratio
         , 10 * sql_srvc_resp_time AS sql_srvc_resp_time
         , temp_space_used
         , tot_idx_scans_per_txn
         , tot_parse_count_per_txn
         , tot_pga_alloc
         , tot_pga_sql_workareas
         , tot_tab_scans_per_txn
         , txns_per_logon
         , usr_calls_per_txn
         , usr_commits_pct
         , usr_rbck_pct
         , usr_rbck_undo_recs_per_txn
         , usr_txn_per_sec
     FROM (SELECT begin_time, metric_name, average
             FROM dba_hist_sysmetric_summary
            WHERE begin_time > SYSDATE - 365) PIVOT (MAX(average)
                                              FOR metric_name
                                              IN  ('Active Parallel Sessions' AS active_parallel_sessions
                                                 , 'Active Serial Sessions' AS active_serial_sessions
                                                 , 'Average Active Sessions' AS avg_active_sessions
                                                 , 'Average Synchronous Single-Block Read Latency' AS avg_sync_blck_r_latency
                                                 , 'Background Checkpoints Per Sec' AS bckgrd_chkpts_per_sec
                                                 , 'Branch Node Splits Per Txn' AS branch_node_splits_per_txn
                                                 , 'Buffer Cache Hit Ratio' AS buffer_cache_hit_ratio
                                                 , 'CPU Usage Per Txn' AS cpu_usg_per_txn
                                                 , 'CR Blocks Created Per Txn' AS cr_blck_created_per_txn
                                                 , 'CR Undo Records Applied Per Txn' AS cr_undo_recs_per_txn
                                                 , 'Cell Physical IO Interconnect Bytes' AS cell_phys_io_iconn_bytes
                                                 , 'Consistent Read Changes Per Txn' AS cons_r_chg_per_txn
                                                 , 'Consistent Read Gets Per Txn' AS cons_r_gets_per_txn
                                                 , 'Current Logons Count' AS curr_logons_count
                                                 , 'Current OS Load' AS curr_os_load
                                                 , 'Current Open Cursors Count' AS curr_open_curs_count
                                                 , 'Cursor Cache Hit Ratio' AS curs_cache_hit_ratio
                                                 , 'DB Block Changes Per Txn' AS db_blck_chg_per_txn
                                                 , 'DB Block Gets Per Txn' AS db_blck_gets_per_txn
                                                 , 'DBWR Checkpoints Per Sec' AS dbwr_chkpts_per_sec
                                                 , 'Database CPU Time Ratio' AS db_cpu_time_ratio
                                                 , 'Database Wait Time Ratio' AS db_wait_time_ratio
                                                 , 'Disk Sort Per Txn' AS disk_sort_per_txn
                                                 , 'Enqueue Requests Per Txn' AS enqueue_reqs_per_txn
                                                 , 'Enqueue Timeouts Per Txn' AS enqueue_timeouts_per_txn
                                                 , 'Enqueue Waits Per Txn' AS enqueue_waits_per_txn
                                                 , 'Execute Without Parse Ratio' AS execs_without_parse_ratio
                                                 , 'Executions Per Txn' AS execs_per_txn
                                                 , 'Full Index Scans Per Txn' AS full_idx_scans_per_txn
                                                 , 'Hard Parse Count Per Txn' AS hard_parse_count_per_txn
                                                 , 'Host CPU Utilization (%)' AS host_cpu_util
                                                 , 'I/O Megabytes per Second' AS io_mb_per_sec
                                                 , 'I/O Requests per Second' AS io_reqs_per_sec
                                                 , 'Leaf Node Splits Per Txn' AS leaf_node_splits_per_txn
                                                 , 'Library Cache Hit Ratio' AS library_cache_hit_ratio
                                                 , 'Logical Reads Per Txn' AS logical_r_per_txn
                                                 , 'Logons Per Txn' AS logons_per_txn
                                                 , 'Long Table Scans Per Txn' AS long_tab_scans_per_txn
                                                 , 'Memory Sorts Ratio' AS memory_sorts_ratio
                                                 , 'Network Traffic Volume Per Sec' AS netw_traffic_vol_per_sec
                                                 , 'Open Cursors Per Txn' AS open_curs_per_txn
                                                 , 'PGA Cache Hit %' AS pga_cache_hit_ratio
                                                 , 'PQ QC Session Count' AS pq_qc_session_count
                                                 , 'PQ Slave Session Count' AS pq_slave_session_count
                                                 , 'PX downgraded 1 to 25% Per Sec' AS px_downgraded_25_per_sec
                                                 , 'PX downgraded 25 to 50% Per Sec' AS px_downgraded_50_per_sec
                                                 , 'PX downgraded 50 to 75% Per Sec' AS px_downgraded_75_per_sec
                                                 , 'PX downgraded 75 to 99% Per Sec' AS px_downgraded_99_per_sec
                                                 , 'PX downgraded to serial Per Sec' AS px_downgraded_serial_per_sec
                                                 , 'PX operations not downgraded Per Sec' AS px_ops_not_downgr_per_sec
                                                 , 'Parse Failure Count Per Txn' AS parse_fail_count_per_txn
                                                 , 'Physical Read Total Bytes Per Sec' AS phys_r_tot_bytes_per_sec
                                                 , 'Physical Reads Direct Per Txn' AS phys_r_drct_per_txn
                                                 , 'Physical Reads Per Txn' AS phys_r_per_txn
                                                 , 'Physical Write Total Bytes Per Sec' AS phys_w_tot_bytes_per_sec
                                                 , 'Physical Writes Direct Per Txn' AS phys_w_drct_per_txn
                                                 , 'Physical Writes Per Txn' AS phys_w_per_txn
                                                 , 'Queries parallelized Per Sec' AS queries_parallelized_per_sec
                                                 , 'Recursive Calls Per Txn' AS recursive_calls_per_txn
                                                 , 'Redo Allocation Hit Ratio' AS redo_alloc_hit_ratio
                                                 , 'Redo Generated Per Txn' AS redo_generated_per_txn
                                                 , 'Redo Writes Per Txn' AS redo_w_per_txn
                                                 , 'Response Time Per Txn' AS resp_time_per_txn
                                                 , 'Row Cache Hit Ratio' AS row_cache_hit_ratio
                                                 , 'Rows Per Sort' AS rows_per_sort
                                                 , 'SQL Service Response Time' AS sql_srvc_resp_time
                                                 , 'Session Count' AS session_count
                                                 , 'Shared Pool Free %' AS shared_pool_free_pct
                                                 , 'Soft Parse Ratio' AS soft_parse_ratio
                                                 , 'Temp Space Used' AS temp_space_used
                                                 , 'Total Index Scans Per Txn' AS tot_idx_scans_per_txn
                                                 , 'Total PGA Allocated' AS tot_pga_alloc
                                                 , 'Total PGA Used by SQL Workareas' AS tot_pga_sql_workareas
                                                 , 'Total Parse Count Per Txn' AS tot_parse_count_per_txn
                                                 , 'Total Table Scans Per Txn' AS tot_tab_scans_per_txn
                                                 , 'Txns Per Logon' AS txns_per_logon
                                                 , 'User Calls Per Txn' AS usr_calls_per_txn
                                                 , 'User Calls Ratio' AS usr_calls_ratio
                                                 , 'User Commits Percentage' AS usr_commits_pct
                                                 , 'User Rollback Undo Records Applied Per Txn' AS usr_rbck_undo_recs_per_txn
                                                 , 'User Rollbacks Percentage' AS usr_rbck_pct
                                                 , 'User Transaction Per Sec' AS usr_txn_per_sec));
                                                 
COMMENT ON TABLE adm_sysmetrics
IS
  'This view shows the last 365 days of system metrics from DBA_HIST_SYSMETRIC_SUMMARY. It pivots the data, so that each metric has its own column to enable statistical analyses to identify potential issues with the database. Most of the details contained in the column comments have been shamelessly copied from the Oracle Concepts Guide, the Oracle DBA page by Burleson Consulting, and Tom Kyte''s excellent blog entries. For metrics that have a value per second (and per user call) and per transaction, we only take the value per transaction, as we can reconstruct the value per second with the number of transactions per second anyway.'
  ;
  COMMENT ON column adm_sysmetrics.ACTIVE_PARALLEL_SESSIONS
IS
  'The number of active parallel sessions.';
  COMMENT ON column adm_sysmetrics.ACTIVE_SERIAL_SESSIONS
IS
  'The number of active serial sessions.';
  COMMENT ON column adm_sysmetrics.AVG_ACTIVE_SESSIONS
IS
  'The mean number of active sessions, both serial and parallel.';
  COMMENT ON column adm_sysmetrics.AVG_SYNC_BLCK_R_LATENCY
IS
  'The mean latency (in ms) of synchronous single-block reads. Synchronous single-block reads are a reasonably accurate way of assessing the performance of the storage subsystem. High latencies are typically caused by a high I/O request load. Excessively high CPU load can also cause the latencies to increase.'
  ;
  COMMENT ON column adm_sysmetrics.BCKGRD_CHKPTS_PER_SEC
IS
  'The number of background checkpoints per second. A checkpoint is the writing by the DBWR process of all modified buffers in the SGA buffer cache to the database data files. Data file headers are also updated with the latest checkpoint SCN, even if the file had no changed blocks, as well as the control files. Checkpoints occur after every redo log switch and also at intervals specified by initialization parameters.'
  ;
  COMMENT ON column adm_sysmetrics.BRANCH_NODE_SPLITS_PER_TXN
IS
  'The number of branch node splits per transaction. It is the number of times an index branch block was split because of the insertion of an additional value.';
  COMMENT ON column adm_sysmetrics.BUFFER_CACHE_HIT_RATIO
IS
  'The percentage of times the data block requested by the query is already/still in memory. Effective use of the buffer cache can greatly reduce the I/O load on the database. If the buffer cache is too small, frequently accessed data will be flushed from the buffer cache too quickly which forces the information to be re-fetched from disk. Since disk access is much slower than memory access, application performance will suffer. In addition, the extra burden imposed on the I/O subsystem could introduce a bottleneck at one or more devices that would further degrade performance.'
  ;
  COMMENT ON column adm_sysmetrics.CELL_PHYS_IO_ICONN_BYTES
IS
  'The amount of bytes for disk-to-database-host interconnect traffic.';
  COMMENT ON column adm_sysmetrics.CONS_R_CHG_PER_TXN
IS
  'The number of times per transaction a user process has applied rollback entries to perform a consistent read on the block. Oracle always enforces statement-level read consistency, which guarantees that data returned by a single query is committed and consistent with respect to a single point in time.'
  ;
  COMMENT ON column adm_sysmetrics.CONS_R_GETS_PER_TXN
IS
  'The number of times per transaction a consistent read was requested for a block.';
  COMMENT ON column adm_sysmetrics.CPU_USG_PER_TXN
IS
  'The CPU usage (in ms) per transaction. Note that the default unit in DBA_HIST_SYSMETRIC_SUMMARY is centiseconds but this view converts it to milliseconds.';
  COMMENT ON column adm_sysmetrics.CR_BLCK_CREATED_PER_TXN
IS
  ' the number of current blocks per transaction cloned to create consistent read (CR) blocks. Read consistency is used when competing processes are reading and updating the data concurrently.';
  COMMENT ON column adm_sysmetrics.CR_UNDO_RECS_PER_TXN
IS
  'The number of undo records applied for consistent read per transaction. Read consistency is used when competing processes are reading and updating the data concurrently and undo blocks are used to retain the prior image of the rows.'
  ;
  COMMENT ON column adm_sysmetrics.CURR_LOGONS_COUNT
IS
  'The current number of logons.';
  COMMENT ON column adm_sysmetrics.CURR_OPEN_CURS_COUNT
IS
  'The current number of opened cursors.';
  COMMENT ON column adm_sysmetrics.CURR_OS_LOAD
IS
  'The current number of processes running.';
  COMMENT ON column adm_sysmetrics.CURS_CACHE_HIT_RATIO
IS
  'The ratio of the number of times an open cursor was found to the number of times a cursor was sought. This is influenced by the SESSION_CACHED_CURSORS parameter. The SESSION_CACHED_CURSORS parameter is used to reduce the amount of parsing with SQL statements that use host variables.'
  ;
  COMMENT ON column adm_sysmetrics.DB_BLCK_CHG_PER_TXN
IS
  'The total number of changes per transaction that were part of an update or delete operation that were made to all blocks in the SGA.';
  COMMENT ON column adm_sysmetrics.DB_BLCK_GETS_PER_TXN
IS
  'The number of times per transaction a current block was requested from the RAM data buffer.';
  COMMENT ON column adm_sysmetrics.DB_CPU_TIME_RATIO
IS
  'The CPU-to-DB time ratio.';
  COMMENT ON column adm_sysmetrics.DB_WAIT_TIME_RATIO
IS
  'The wait-to-DB time ratio.';
  COMMENT ON column adm_sysmetrics.DBWR_CHKPTS_PER_SEC
IS
  'The number of times per second the DBWR was asked to scan the cache and write all blocks marked for a checkpoint. The database writer process writes the contents of buffers to datafiles. The DBWR processes are responsible for writing modified (dirty) buffers in the database buffer cache to disk. When a buffer in the database buffer cache is modified, it is marked dirty. The primary job of the DBWR process is to keep the buffer cache clean by writing dirty buffers to disk. As user processes dirty buffers, the number of free buffers diminishes. If the number of free buffers drops too low, user processes that must read blocks from disk into the cache are not able to find free buffers. DBWR manages the buffer cache so that user processes can always find free buffers.'
  ;
  COMMENT ON column adm_sysmetrics.DISK_SORT_PER_TXN
IS
  'The number of sorts going to disk per transactions for the sample period. For best performance, most sorts should occur in memory because sorts to disks are expensive to perform. If the sort area is too small, extra sort runs will be required during the sort operation. This increases CPU and I/O resource consumption.'
  ;
  COMMENT ON column adm_sysmetrics.ENQUEUE_REQS_PER_TXN
IS
  'The total number of table or row locks acquired per transaction.';
  COMMENT ON column adm_sysmetrics.ENQUEUE_TIMEOUTS_PER_TXN
IS
  'The total number of table and row locks (acquired and converted) per second that time out before they could complete.';
  COMMENT ON column adm_sysmetrics.ENQUEUE_WAITS_PER_TXN
IS
  'The total number of waits per transaction that occurred during an enqueue convert or get because the enqueue get was deferred. It''s important to remember when you take a look at the STATS$ENQUEUESTAT table that enqueue waits are a normal part of Oracle processing. It is only when you see an excessive amount of enqueue waits for specific processes that you need to be concerned in the tuning process. Oracle locks protect shared resources and allow access to those resources via a queuing mechanism. A large amount of time spent waiting for enqueue events can be caused by various problems, such as waiting for individual row locks or waiting for exclusive locks on a table.'
  ;
  COMMENT ON column adm_sysmetrics.EXECS_PER_TXN
IS
  'The number of executes per second.';
  COMMENT ON column adm_sysmetrics.EXECS_WITHOUT_PARSE_RATIO
IS
  'The percentage of statement executions that do not require a corresponding parse. A perfect system would parse all statements once and then execute the parsed statement over and over without reparsing. This ratio provides an indication as to how often the application is parsing statements as compared to their overall execution rate. A higher number is better.'
  ;
  COMMENT ON column adm_sysmetrics.FULL_IDX_SCANS_PER_TXN
IS
  'The number of index fast-full scans execution plans per second.';
  COMMENT ON column adm_sysmetrics.HARD_PARSE_COUNT_PER_TXN
IS
  'The number of hard parses per second during this sample period. A hard parse occurs when a SQL statement has to be loaded into the shared pool. In this case, the Oracle Server has to allocate memory in the shared pool and parse the statement. A soft parse is recorded when the Oracle Server checks the shared pool for a SQL statement and finds a version of the statement that it can reuse.'
  ;
  COMMENT ON column adm_sysmetrics.HOST_CPU_UTIL
IS
  'The percentage of CPU being used on the host.';
  COMMENT ON column adm_sysmetrics.IO_MB_PER_SEC
IS
  'The total I/O throughput of the database for both reads and writes in megabytes per second. A very high value indicates that the database is generating a significant volume of I/O data.';
  COMMENT ON column adm_sysmetrics.IO_REQS_PER_SEC
IS
  'The total number of I/O requests of the database for both reads and writes in megabytes per second.';  
  COMMENT ON column adm_sysmetrics.LEAF_NODE_SPLITS_PER_TXN
IS
  'The number of times per transaction an index leaf node was split because of the insertion of an additional value. It is an important measure of the DML activity on an index and excessive DML can leave an index in a sub-optimal structure, necessitating a rebuild for optimal index performance.'
  ;
  COMMENT ON column adm_sysmetrics.LIBRARY_CACHE_HIT_RATIO
IS
  'The percentage of entries in the library cache that were parsed more than once (reloads) over the lifetime of the instance. Since you never know in advance how many SQL statements need to be cached, the Oracle DBA must set SHARED_POOL_SIZE large enough to prevent excessive re-parsing of SQL.'
  ;
  COMMENT ON column adm_sysmetrics.LOGICAL_R_PER_TXN
IS
  'The number of logical reads per transaction. The value of this statistic is zero if there have not been any write or update transactions committed or rolled back during the last sample period. If the bulk of the activity to the database is read only, the corresponding per second data item of the same name will be a better indicator of current performance.'
  ;
  COMMENT ON column adm_sysmetrics.LOGONS_PER_TXN
IS
  'The number of logons per transaction.';
  COMMENT ON column adm_sysmetrics.LONG_TAB_SCANS_PER_TXN
IS
  'The number of long table scans per transaction during sample period. A table is considered long if the table is not cached and if its high-water mark is greater than 5 blocks.';
  COMMENT ON column adm_sysmetrics.MEMORY_SORTS_RATIO
IS
  'The percentage of sorts (from ORDER BY clauses or index building) that are done to disk vs. in-memory. Disk sorts are done in the TEMP tablespace, which is hundreds of times slower than a RAM sort. The in-memory sorts are controlled by sort_area_size or by pga_aggregate_target.'
  ;
  COMMENT ON column adm_sysmetrics.NETW_TRAFFIC_VOL_PER_SEC
IS
  'The network traffic volume (in bytes) per second.';
  COMMENT ON column adm_sysmetrics.OPEN_CURS_PER_TXN
IS
  'The total number of cursors opened per transaction. One problem in performance is caused by multiple cursors with bind variables that open the cursor and execute it many times.';
  COMMENT ON column adm_sysmetrics.PARSE_FAIL_COUNT_PER_TXN
IS
  'The total number of parse failures per transaction.';
  COMMENT ON column adm_sysmetrics.PGA_CACHE_HIT_ratio
IS
  'The total number of bytes processed in the PGA versus the total number of bytes processed plus extra bytes read/written in extra passes.';
  COMMENT ON column adm_sysmetrics.PHYS_R_DRCT_PER_TXN
IS
  'The number of direct physical reads per transaction. Direct reads are analogous to direct reads, done by bypassing the OS JFS cache.';
  COMMENT ON column adm_sysmetrics.PHYS_R_PER_TXN
IS
  'The number of disk reads per transaction. When a user performs a SQL query, Oracle tries to retrieve the data from the database buffer cache (memory) first, then goes to disk if it is not in memory already. Reading data blocks from disk is much more expensive than reading the data blocks from memory. The goal with Oracle should always be to maximize memory utilization.'
  ;
  COMMENT ON column adm_sysmetrics.PHYS_R_TOT_BYTES_PER_SEC
IS
  'Total amount of disk reads (in bytes) per second.';
  COMMENT ON column adm_sysmetrics.PHYS_W_DRCT_PER_TXN
IS
  ' The number of direct physical disk writes per second.  You can speed up disk write in several ways, most notably the segregation of high-write datafiles to a small data buffer, and by using solid-state-disk (SSD) for high disk write files.'
  ;
  COMMENT ON column adm_sysmetrics.PHYS_W_PER_TXN
IS
  'The number of disk reads per transaction.';
  COMMENT ON column adm_sysmetrics.PHYS_W_TOT_BYTES_PER_SEC
IS
  'Total amount of disk writes (in bytes) per second.';
  COMMENT ON column adm_sysmetrics.PQ_QC_SESSION_COUNT
IS
  'The number of parallel query sessions.';
  COMMENT ON column adm_sysmetrics.PQ_SLAVE_SESSION_COUNT
IS
  'The number of slave sessions for parallelized queries.';
  COMMENT ON column adm_sysmetrics.PX_OPS_DOWNGR_PER_SEC
IS
  'The number of parallel execution operations per second downgraded (i.e. degree of parallelism reduced or serialized) due to the adaptive multiuser algorithm or the depletion of available parallel execution servers.'
  ;
  COMMENT ON column adm_sysmetrics.PX_OPS_NOT_DOWNGR_PER_SEC
IS
  'The number of parallel execution operations per second not downgraded (i.e. degree of parallelism not reduced) due to the adaptive multiuser algorithm or the depletion of available parallel execution servers.'
  ;
  COMMENT ON column adm_sysmetrics.QUERIES_PARALLELIZED_PER_SEC
IS
  'The number of SQL queries parallelized per second.';
  COMMENT ON column adm_sysmetrics.RECURSIVE_CALLS_PER_TXN
IS
  'The number of recursive calls, per second. Sometimes, to execute a SQL statement issued by a user, Oracle must issue additional statements. Such statements are called recursive calls or recursive SQL statements.'
  ;
  COMMENT ON column adm_sysmetrics.REDO_ALLOC_HIT_RATIO
IS
  'The percentage of times users did not have to wait for the log writer to free space in the redo log buffer. Redo log entries contain a record of changes that have been made to the database block buffers. The log writer (LGWR) process writes redo log entries from the log buffer to a redo log file. The log buffer should be sized so that space is available in the log buffer for new entries, even when access to the redo log is heavy. When the log buffer is undersized, user process will be delayed as they wait for the LGWR to free space in the redo log buffer.'
  ;
  COMMENT ON column adm_sysmetrics.REDO_GENERATED_PER_TXN
IS
  'The amount of redo, in bytes, generated per transaction during this sample period. The redo log buffer is a circular buffer in the SGA that holds information about changes made to the database. This information is stored in redo entries. Redo entries contain the information necessary to reconstruct, or redo, changes made to the database by INSERT, UPDATE, DELETE, CREATE, ALTER or DROP operations. Redo entries are used for database recovery, if necessary.'
  ;
  COMMENT ON column adm_sysmetrics.REDO_W_PER_TXN
IS
  'The number of redo write operations per second during this sample period.';
  COMMENT ON column adm_sysmetrics.RESP_TIME_PER_TXN
IS
  'The time spent (in ms) in database operations per transaction. It is derived from the total time that user calls spend in the database (DB time) and the number of commits and rollbacks performed. A change in this value indicates that either the workload has changed or that the database’s ability to process the workload has changed because of either resource constraints or contention. Note that the default unit in DBA_HIST_SYSMETRIC_SUMMARY is centiseconds but this view converts it to milliseconds.'
  ;
  COMMENT ON column adm_sysmetrics.ROW_CACHE_HIT_RATIO
IS
  'The ratio of hits to the total number of bytes processed in the related the total number of bytes processed plus extra bytes read/written in extra passes. Oracle recommends that if the free memory is close to zero and either the library cache hit ratio is less than 0.95 or the row cache hit ratio is less than 0.95, then the SHARED_POOL_SIZE parameter should be increased until the ratios stop improving.'
  ;
  COMMENT ON column adm_sysmetrics.ROWS_PER_SORT
IS
  'The average number of rows per sort for all types of sorts performed.';
  COMMENT ON column adm_sysmetrics.SESSION_COUNT
IS
  'The total number of session.';
  COMMENT ON column adm_sysmetrics.SHARED_POOL_FREE_PCT
IS
  'The percentage of the Shared Pool that is currently marked as free.';
  COMMENT ON column adm_sysmetrics.SOFT_PARSE_RATIO
IS
  'The ratio of soft parses (SQL is already in library cache) to hard parses (SQL must be parsed, validated, and an execution plan formed).  The library cache (as set by shared_pool_size) serves to minimize hard parses.  Excessive hard parsing could be due to a time shared_pool_size or because of SQL with embedded literal values.'
  ;
  COMMENT ON column adm_sysmetrics.SQL_SRVC_RESP_TIME
IS
  'The time (in ms) for each call. Note that the default unit in DBA_HIST_SYSMETRIC_SUMMARY is centiseconds but this view converts it to milliseconds.';
  COMMENT ON column adm_sysmetrics.TEMP_SPACE_USED
IS
  'The total amount of bytes used in the TEMP tablespace.';
  COMMENT ON column adm_sysmetrics.TOT_IDX_SCANS_PER_TXN
IS
  'The total number of index scans per transaction. Physical disk speed is an important factor in weighing these costs. As disk access speed increases, the costs of a full-table scan versus single block reads can become negligible.'
  ;
  COMMENT ON column adm_sysmetrics.TOT_PARSE_COUNT_PER_TXN
IS
  'The total number of parses per second, both hard and soft.';
  COMMENT ON column adm_sysmetrics.TOT_PGA_ALLOC
IS
  'Total amount of bytes allocated to the PGA.';
  COMMENT ON column adm_sysmetrics.TOT_PGA_SQL_WORKAREAS
IS
  'Total amount of bytes of PGA used by SQL work areas. With manual configuration of the SGA, it is possible that compiled SQL statements frequently age out of the shared pool because of its inadequate size. This can increase the frequency of hard parses, leading to reduced performance. When automatic SGA management is enabled, the internal tuning algorithm monitors the performance of the workload, increasing the shared pool if it determines the increase will reduce the number of parses required.'
  ;
  COMMENT ON column adm_sysmetrics.TOT_TAB_SCANS_PER_TXN
IS
  'The number of long and short table scans per transaction.';
  COMMENT ON column adm_sysmetrics.TXNS_PER_LOGON
IS
  'The number of transactions per logon.';
  COMMENT ON column adm_sysmetrics.USR_CALLS_PER_TXN
IS
  'The number of user calls per transaction.';
  COMMENT ON column adm_sysmetrics.USR_COMMITS_PCT
IS
  'The percentage of user commits to total user transactions.';
  COMMENT ON column adm_sysmetrics.USR_RBCK_PCT
IS
  'The percentage of user rollbacks to total user transations.';
  COMMENT ON column adm_sysmetrics.USR_RBCK_UNDO_RECS_PER_TXN
IS
  'The number of undo records applied to user-requested rollback changes per transaction.';
  COMMENT ON column adm_sysmetrics.USR_TXN_PER_SEC
IS
  'The number of user transactions per second.';                                        