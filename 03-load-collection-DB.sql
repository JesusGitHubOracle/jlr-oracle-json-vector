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
CREATE TABLE j_movies_ext (
  data JSON
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_BIGDATA
  DEFAULT DIRECTORY MOVIES_DIR
  ACCESS PARAMETERS (
    com.oracle.bigdata.fileformat = jsondoc 
  )
  LOCATION (MOVIES_DIR:'movies.ndjson')
)
PARALLEL
REJECT LIMIT UNLIMITED;

select count(*) from j_movies_ext;
 
/* 21349 */

--------------------------------------------------------------------------------
-- Create the collection table to hold the JSON documents. 
--  The collection table will be used to create the Oracle Vector search index.
--------------------------------------------------------------------------------
CREATE JSON COLLECTION TABLE j_movies;

INSERT INTO j_movies
SELECT *
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
 