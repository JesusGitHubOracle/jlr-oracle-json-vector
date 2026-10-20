----------------------------------------------------------------------------------------
-- Create a vector index on the plot_embedding field in the J_MOVIES_EMBEDDINGS table
-- Index the JSON field directly with HNSW,  Oracle 26ai Release Update 23.26.2 or later
----------------------------------------------------------------------------------------

DROP INDEX IF EXISTS movies_plot_hnsw_idx;
CREATE VECTOR INDEX movies_plot_hnsw_idx
ON J_MOVIES_EMBEDDINGS (
    JSON_VALUE(
        data,
        '$.plot_embedding' RETURNING VECTOR(384, FLOAT32)
    )
)
ORGANIZATION INMEMORY NEIGHBOR GRAPH
DISTANCE COSINE
WITH TARGET ACCURACY 95
ONLINE;
----------------------------------------------------------------------------------------
-- Validate the index creation and check the number of documents with vector embeddings
----------------------------------------------------------------------------------------
SELECT COUNT(*) AS total_documents,
       COUNT(
           VECTOR_DIMENSION_COUNT(
               JSON_VALUE(
                   data,
                   '$.plot_embedding'
                   RETURNING VECTOR(384, FLOAT32)
               )
           )
       ) AS documents_with_vector
FROM J_MOVIES_EMBEDDINGS;