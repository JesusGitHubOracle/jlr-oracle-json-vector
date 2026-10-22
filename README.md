# Semantic Search over JSON in Oracle AI Database

Oracle AI Vector Search is designed for Artificial Intelligence (AI) workloads and allows you to query data based on semantics, rather than keywords.
The VECTOR data type is introduced with the release of Oracle AI Database 26ai, providing the foundation to store vector embeddings alongside business data in the database. Using embedding models, you can transform unstructured data into vector embeddings that can then be used for semantic queries on business data.

Oracle AI database also allows you to run semantic searches over JSON documents stored in the database using the JSON data type. Starting [Oracle 26ai Release Update 23.26.2](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/april-2026-release-update-23.26.2.html) it is possibe to index a JSON field usign Function-Based [Hierarchical Navigable Small World Indexes](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/hierarchical-navigable-small-world-index-syntax-and-parameters.html#example).

## Getting Started

This repository provides the scripts and sample files you need to get started with semantic search over JSON documents in Oracle AI Database. Follow these steps:

- Load a [supported ONNX model](https://docs.oracle.com/en/database/oracle/oracle-database/26/nfcoa/onnx-support.html) into the database.
- Import a newline-delimited JSON (NDJSON) file into an Oracle JSON collection table.
- Generate and store vector embeddings in each document.
- Create a Hierarchical Navigable Small World (HNSW) vector index directly on the JSON field containing the embeddings.
- Run semantic searches directly from SQL.

There are separate setup scripts for Autonomous Database (`-ADB.sql`) and a database with access to server-side files (`-DB.sql`, such as OCI Base Database Service). Embedding generation, indexing, and search use the same scripts on both paths.

## Components

- **Model:** `ALL_MINILM_L12_V2`, imported from `all_MiniLM_L12_v2.onnx`.
- **Embedding:** 384 dimensions.
- **Source text:** the document's `plot` field. Search results display `fullplot` alongside title, year, and genres.
- **Storage:** embeddings are JSON arrays in `DATA.plot_embedding`, alongside the movie fields. The scripts create an enriched JSON collection Table; it does not modify the source collection.
- **Index:** HNSW (`INMEMORY NEIGHBOR GRAPH`), cosine distance, target accuracy 95, built with `ONLINE`.

## Scripts  and short description

| File | Purpose |
| --- | --- |
| [01-oracle-json-user-DB.sql](01-oracle-json-user-DB.sql) | Recreates the demo schema, grants privileges, defines server directories, and optionally enables ORDS. |
| [01-oracle-json-user-ADB.sql](01-oracle-json-user-ADB.sql) | Recreates the Autonomous demo schema, grants privileges, and optionally enables ORDS. |
| [02-load-onnx-model-DB.sql](02-load-onnx-model-DB.sql) | Drops the existing model, imports the local ONNX file, and tests inference. |
| [02-load-onnx-model-ADB.sql](02-load-onnx-model-ADB.sql) | Imports the model from OCI Object Storage using a pre-authenticated request (PAR) URL. |
| [03-load-collection-DB.sql](03-load-collection-DB.sql) | Reads `movies.ndjson` through an external table and populates `J_MOVIES`. |
| [03-load-collection-ADB.sql](03-load-collection-ADB.sql) | Contains Object Storage and local-file loading alternatives; requires the adjustments below. |
| [04-create-vector-embeddings.sql](04-create-vector-embeddings.sql) | Recreates `J_MOVIES_EMBEDDINGS` and adds plot embeddings to the movie documents. |
| [05.create_vector_index.sql](05.create_vector_index.sql) | Recreates `MOVIES_PLOT_HNSW_IDX` on the JSON embedding field and counts usable vectors. |
| [06-vector-search.oracle.sql](06-vector-search.oracle.sql) | Generates query embeddings and demonstrates nearest-neighbor search, post-filtering, and post-sorting. |
| [movies.ndjson](movies.ndjson) | Movie documents, one JSON document per line. The supplied file contains 21,349 documents. |
| [Download all_MiniLM_L12_v2.onnx](https://objectstorage.eu-frankfurt-1.oraclecloud.com/p/hWtxHRNpBnQKaxtj5KtGVyQu4VYHqtuqAY4PUReK_6NxCeZRl94vm07lMGZAuOih/n/fro8fl9kuqli/b/bucket-for-ajd-data/o/vector-data/all_MiniLM_L12_v2.onnx)| ONNX model asset, approximately 127 MiB.

## Option A: server-side files / Base Database Service

Upload the  ONNX and JSON files from to  your  database server, for example:

   ```text
   /home/oracle/onnx_models/all_MiniLM_L12_v2.onnx
   /home/oracle/movies.ndjson
   ```

   You'd need to adjust the paths in `01-oracle-json-user-DB.sql` to match your server. `CREATE DIRECTORY` defines an Oracle object; it does not create an operating-system folder. Use the filename capitalization shown above, as used by the model loader.

## Option B: Autonomous Database / Object Storage

 Upload the ONNX file and movie dataset to your Object Storage bucket. Replace the URLs in the `-ADB.sql` scripts with your own model and dataset PAR URLs.

## Semantic Search examples

| Prompt | Behavior |
| --- | --- |
| `epic fantasy journey with reluctant heroes` | Finds the nearest five movie plots and demonstrates execution-plan inspection. |
| `Suspense plot about a mysterious disappearance` | Finds the nearest ten, then keeps movies whose genres contain Action, Adventure, or Sci-Fi. May return fewer than ten rows. |
| `Westerns and frontier tales` | Finds the nearest five, then sorts those candidates by year descending, with missing years last. |

The second query filters **after** selecting candidates; it does not find the nearest ten within the chosen genres. The third query changes the presentation order of five semantic matches; it does not explicitly filter on year or genre.

The queries use `FETCH APPROX ... WITH TARGET ACCURACY 95`. This requests approximate nearest neighbors; 95 is an accuracy target, not a per-result similarity score or guaranteed match percentage.

## Online documentation

- [Oracle AI Vector Search documentation](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/)
- [Load an ONNX model](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/load_onnx_model-procedure.html)
- [Oracle JSON in the database](https://docs.oracle.com/en/database/oracle/oracle-database/26/adjsn/json-in-oracle-database.html)
- [Query JSON data](https://docs.oracle.com/en/database/oracle/oracle-database/26/adjsn/query-json-data.html)
- [Index JSON data](https://docs.oracle.com/en/database/oracle/oracle-database/26/adjsn/overview-indexing-json-data.html)
- [SQL/JSON path expression syntax](https://docs.oracle.com/en/database/oracle/oracle-database/26/adjsn/sql-json-path-expression-syntax.html)
