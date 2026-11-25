/*
Option B: Autonomous Database / Object Storage
 Upload the ONNX file and movie dataset to your Object Storage bucket. 
 Replace the URLs in the scripts with your own model and dataset PAR URLs.
*/


  
 ---------------------------------------------------------------
 -- Cleanup any existing tables and indexes
DROP TABLE IF EXISTS j_movies_ext;
DROP TABLE IF EXISTS j_movies CASCADE CONSTRAINTS PURGE;
---------------------------------------------------------------   


-- Option A: if Oracle Autonomous Database
-- OCI PAR URL for the movies.ndjson file in OCI Object Storage.  

define movies_par_url = '<your_par_url>/movies.ndjson';

BEGIN
  DBMS_CLOUD.CREATE_EXTERNAL_TABLE(
    table_name      => 'j_movies_ext',
    credential_name => NULL,  -- use NULL for a PAR URL
    format          => JSON_OBJECT('type' VALUE 'jsondoc'),
    file_uri_list   => '&&movies_par_url'
  );
END;
/

select count(*) from j_movies_ext;

/* 21349 */

-------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------------
-- Space used by the collection table and its associated objects (indexes, LOBs, etc.)
--------------------------------------------------------------------------------------
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
