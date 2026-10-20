-- Creates a new Oracle JSON collection table with in-database embeddings.
--
--    The source JSON collection table is "j_movies".
--    The target JSON collection table should be "j_movies_embeddings".
--    The ONNX embedding model has been loaded in Oracle as ALL_MINILM_L12_V2.
--    The model input column alias is DATA, which is the common alias for ONNX

 
SET DEFINE ON
SET SERVEROUTPUT ON
SET TIMING ON
 
--------------------------------------------------------------
-- Drop the target collection table if it already exists
--------------------------------------------------------------

DROP TABLE IF EXISTS J_MOVIES_EMBEDDINGS PURGE;
CREATE JSON COLLECTION TABLE J_MOVIES_EMBEDDINGS;

----------------------------------------------------------------------------
PROMPT Creating in-database embeddings for the J_MOVIES collection...
----------------------------------------------------------------------------
INSERT /*+ APPEND */ INTO  J_MOVIES_EMBEDDINGS  (DATA)
    SELECT json_transform(
             m.DATA,
             SET '$.plot_embedding' =
               CASE
                 WHEN json_value(
                        m.DATA,
                        '$.plot'
                        RETURNING VARCHAR2(4000)
                        NULL ON EMPTY
                        NULL ON ERROR
                      ) IS NOT NULL
                 THEN JSON(
                        vector_serialize(
                          vector_embedding("ALL_MINILM_L12_V2" USING
                            json_value(
                              m.DATA,
                              '$.plot'
                              RETURNING VARCHAR2(4000)
                              NULL ON EMPTY
                              NULL ON ERROR
                            ) AS DATA
                          )
                          RETURNING CLOB
                        )
                      )
                 ELSE NULL
               END
           )
    FROM J_MOVIES m;

------------------------------------------------------------------------------------
PROMPT Validation counts
------------------------------------------------------------------------------------
SELECT
  COUNT(*) AS total_documents,
  COUNT(
    CASE
      WHEN json_exists(DATA, '$.plot_embedding') THEN 1
    END
  ) AS documents_with_plot_embedding
FROM J_MOVIES_EMBEDDINGS;

------------------------------------------------------------------------------------
PROMPT Query Full JSON document sample
------------------------------------------------------------------------------------
set pagesize 0
set linesize 200
set long 100000
SELECT
  json_serialize(DATA RETURNING CLOB PRETTY) AS document
FROM J_MOVIES_EMBEDDINGS
WHERE json_exists(DATA, '$.plot_embedding')
FETCH FIRST 1 ROW ONLY;

