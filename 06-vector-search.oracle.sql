 

SET LONG 100000
SET LONGCHUNKSIZE 100000
SET LINESIZE 200
SET PAGESIZE 100
SET VERIFY OFF

---------------------------------------------------------------------------------------------------------     
--  Generate and store the query embedding on a CLOB variable for use in subsequent vector search queries
--------------------------------------------------------------------------------------------------------- 
VARIABLE query_vector0_json CLOB
BEGIN
    SELECT VECTOR_SERIALIZE(
               VECTOR_EMBEDDING(
                   ALL_MINILM_L12_V2 USING
                   'epic fantasy journey with reluctant heroes' AS DATA
               ) RETURNING CLOB
           )
    INTO :query_vector0_json
    FROM dual;
END;
/
--------------------------------------------------------------------------------------------------------- 
-- Vector dimension count for the ALL_MINILM_L12_V2 
--------------------------------------------------------------------------------------------------------- 
SELECT VECTOR_DIMENSION_COUNT(
           TO_VECTOR(:query_vector0_json, 384, FLOAT32)
       ) AS query_vector_length
FROM dual;

--------------------------------------------------------------------------------------------------------- 
-- Finds the nearest five movie plots and demonstrates execution-plan inspection.
--------------------------------------------------------------------------------------------------------- 
EXPLAIN PLAN FOR
SELECT
       JSON_VALUE(data, '$.title' RETURNING VARCHAR2(4000)) AS title,
       JSON_VALUE(data, '$.year' RETURNING NUMBER) AS year,
       JSON_QUERY(data, '$.genres' RETURNING CLOB) AS genres,
       JSON_VALUE(data, '$.fullplot' RETURNING CLOB) AS fullplot
FROM J_MOVIES_EMBEDDINGS
ORDER BY VECTOR_DISTANCE(
           JSON_VALUE(data, '$.plot_embedding'
                      RETURNING VECTOR(384, FLOAT32)),
           TO_VECTOR(:query_vector0_json, 384, FLOAT32),
           COSINE
       )
FETCH APPROX FIRST 5 ROWS ONLY WITH TARGET ACCURACY 95;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());


/* Execution plan notes:

   * The FETCH APPROX clause allows for approximate nearest neighbor search, which can improve performance.
   * The target accuracy of 95% indicates that the results may not be exact but should be close to the true nearest neighbors.

------------------------------------------------------------------------------------------------------    
| Id  | Operation                      | Name                | Rows  | Bytes | Cost (%CPU)| Time     |    
------------------------------------------------------------------------------------------------------    
|   0 | SELECT STATEMENT               |                     |     5 |   169K|     2  (50)| 00:00:01 |    
|*  1 |  COUNT STOPKEY                 |                     |       |       |            |          |    
|   2 |   VIEW                         |                     |     5 |   169K|     2  (50)| 00:00:01 |    
|*  3 |    SORT ORDER BY STOPKEY       |                     |     5 | 25880 |     2  (50)| 00:00:01 |
|   4 |     TABLE ACCESS BY INDEX ROWID| J_MOVIES_EMBEDDINGS |     5 | 25880 |     1   (0)| 00:00:01 |    
|   5 |      VECTOR INDEX HNSW SCAN    | PLOT_VEC_IDX        |     5 | 25880 |     1   (0)| 00:00:01 |    
------------------------------------------------------------------------------------------------------    
                                                                                                        

*/  
------------------------------------------------------------------------------------------------------------------------------- 
-- Finds the nearest ten, then keeps movies whose genres contain Action, Adventure, or Sci-Fi. May return fewer than ten rows.
------------------------------------------------------------------------------------------------------------------------------- 
COL title FORMAT A30
COL year FORMAT 9999
COL genres FORMAT A40
COL fullplot FORMAT A80

VARIABLE query_vector1_json CLOB
BEGIN
    SELECT VECTOR_SERIALIZE(
               VECTOR_EMBEDDING(
                   ALL_MINILM_L12_V2 USING
                   'Suspense plot about a mysterious disappearance' AS DATA
               ) RETURNING CLOB
           )
    INTO :query_vector1_json
    FROM dual;
END;
/

WITH nearest_movies AS (
    SELECT data,
           VECTOR_DISTANCE(
           JSON_VALUE(data, '$.plot_embedding'
                      RETURNING VECTOR(384, FLOAT32)),
           TO_VECTOR(:query_vector1_json, 384, FLOAT32),
           COSINE
       ) AS distance
    FROM J_MOVIES_EMBEDDINGS
    ORDER BY distance
    FETCH APPROX FIRST 10 ROWS ONLY WITH TARGET ACCURACY 95
)
SELECT
       JSON_VALUE(data, '$.title' RETURNING VARCHAR2(4000)) AS title,
       JSON_VALUE(data, '$.year' RETURNING NUMBER) AS year,
       JSON_QUERY(data, '$.genres' RETURNING CLOB) AS genres,
       JSON_VALUE(data, '$.fullplot' RETURNING CLOB) AS fullplot
FROM nearest_movies
WHERE JSON_EXISTS(
    data,
    '$.genres[*]?(@ == "Action" || @ == "Adventure" || @ == "Sci-Fi")'
)
ORDER BY distance;

--------------------------------------------------------------------------------------------------------- 
-- Finds the nearest five, then sorts those candidates by year descending, with missing years last.
--------------------------------------------------------------------------------------------------------- 
col title format a30
col year format 9999
col genres format a40
col fullplot format a80 

VARIABLE query_vector2_json CLOB
BEGIN
    SELECT VECTOR_SERIALIZE(
               VECTOR_EMBEDDING(
                   ALL_MINILM_L12_V2 USING
                   'Westerns and frontier tales' AS DATA
               ) RETURNING CLOB
           )
    INTO :query_vector2_json
    FROM dual;
END;
/

WITH nearest_movies AS (
    SELECT data,
           VECTOR_DISTANCE(
           JSON_VALUE(data, '$.plot_embedding'
                      RETURNING VECTOR(384, FLOAT32)),
           TO_VECTOR(:query_vector2_json, 384, FLOAT32),
           COSINE
       ) AS distance
    FROM J_MOVIES_EMBEDDINGS
    ORDER BY distance
    FETCH APPROX FIRST 5 ROWS ONLY WITH TARGET ACCURACY 95
)
SELECT
       JSON_VALUE(data, '$.title' RETURNING VARCHAR2(4000)) AS title,
       JSON_VALUE(data, '$.year' RETURNING NUMBER) AS year,
       JSON_QUERY(data, '$.genres' RETURNING CLOB) AS genres,
       JSON_VALUE(data, '$.fullplot' RETURNING CLOB) AS fullplot
FROM nearest_movies
ORDER BY year DESC NULLS LAST;


