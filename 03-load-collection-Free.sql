-- Oracle AI Database Free variant of 03-load-collection-DB.sql.
-- Tested with the included movies.ndjson on Free 23.26.3.0.0 (Linux ARM64).
-- Run as your demo schema in FREEPDB1 after an administrator configures MOVIES_DIR.
-- WARNING: drops J_MOVIES_EXT and J_MOVIES in the connected schema.
-- REJECT LIMIT 0 stops on malformed records instead of silently dropping them.

--  Script to Create a JSON Collection Table, 
--  First we will create an external table to load the JSON documents  from a local file system using AI Database 
--  Then we will create a JSON collection table to hold the documents. 
  
 ---------------------------------------------------------------
 -- Cleanup any existing tables and indexes
 ---------------------------------------------------------------
DROP TABLE IF EXISTS j_movies_ext;
DROP TABLE IF EXISTS j_movies CASCADE CONSTRAINTS PURGE;

-------------------------------------------------------------------------------------------------------
-- Create an external table to load the JSON documents from MOVES_DIR directory on the database server.
-------------------------------------------------------------------------------------------------------
-- Oracle Free compatibility: read each NDJSON line as CLOB text.
-- DATA is quoted in the access parameters because it is a loader keyword.
-- This dataset's longest record is 8,882 bytes; CHAR(32767) covers it.
CREATE TABLE j_movies_ext (
  data CLOB
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY MOVIES_DIR
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET AL32UTF8
    NOBADFILE NOLOGFILE NODISCARDFILE
    FIELDS TERMINATED BY X'01'
    MISSING FIELD VALUES ARE NULL
    ("DATA" CHAR(32767))
  )
  LOCATION ('movies.ndjson')
)
REJECT LIMIT 0;

select count(*) from j_movies_ext;
 
/* 21349 */

--------------------------------------------------------------------------------
-- Create the collection table to hold the JSON documents. 
--  The collection table will be used to create the Oracle Vector search index.
--------------------------------------------------------------------------------
CREATE JSON COLLECTION TABLE j_movies;

INSERT INTO j_movies (DATA)
SELECT JSON(DATA)
FROM j_movies_ext;
commit;
SELECT count(*) AS document_count
FROM j_movies;

---------------------------------------------------------------------------------------
-- Space used by the collection table and its associated objects (indexes, LOBs, etc.)
---------------------------------------------------------------------------------------
COL object_kind format a20
COL segment_type format a20
COL segment_name format a30
COL allocated_mb format 999.99  

WITH collection_objects AS (
  SELECT table_name AS object_name, 'table' AS object_kind
  FROM   user_tables
  WHERE  table_name = 'J_MOVIES'

  UNION ALL

  SELECT index_name, 'index'
  FROM   user_indexes
  WHERE  table_name = 'J_MOVIES'

  UNION ALL

  SELECT segment_name, 'JSON/LOB data'
  FROM   user_lobs
  WHERE  table_name = 'J_MOVIES'

  UNION ALL

  SELECT index_name, 'JSON/LOB index'
  FROM   user_lobs
  WHERE  table_name = 'J_MOVIES'
)
SELECT o.object_kind,
       s.segment_type,
       s.segment_name,
       ROUND(s.bytes / 1024 / 1024, 2) AS allocated_mb
FROM   collection_objects o
JOIN   user_segments s
       ON s.segment_name = o.object_name
ORDER  BY o.object_kind, s.segment_type, s.segment_name;
 