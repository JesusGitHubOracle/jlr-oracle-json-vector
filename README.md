# Semantic Search and RAG over JSON in Oracle AI Database

This repository walks you through extending semantic search over JSON documents with retrieval-augmented generation (RAG) in Oracle AI Database. You will load sample movie documents, generate embeddings from their plots using an in-database ONNX model, create a vector index on the JSON field containing those embeddings, and run semantic searches directly from SQL. Finally, you will pass the retrieved movie plots to a language model to generate answers grounded in the search results.

## AI Vector Search and RAG Workflow

This repository provides the scripts and sample files for semantic search and RAG over JSON documents in Oracle AI Database release 23.26.2 or later.

- Load a [supported ONNX model](https://docs.oracle.com/en/database/oracle/oracle-database/26/nfcoa/onnx-support.html) into the database.
- Import a newline-delimited JSON (NDJSON) file into an Oracle JSON collection table.
- Generate and store vector embeddings in each document.
- Create a Hierarchical Navigable Small World (HNSW) vector index directly on the JSON field containing the embeddings.
- Run semantic searches directly from SQL.
- Extend retrieval with Ollama-generated answers and numbered supporting sources.



## Components

- **Model:** `ALL_MINILM_L12_V2`, imported from `all_MiniLM_L12_v2.onnx`.
- **Embedding:** 384 dimensions.
- **Source text:** the document's `plot` field. Search results display `fullplot` alongside title, year, and genres.
- **Storage:** embeddings are JSON arrays in `DATA.plot_embedding`, alongside the movie fields. The scripts create an enriched JSON collection Table; it does not modify the source collection.
- **Index:** HNSW (`INMEMORY NEIGHBOR GRAPH`), cosine distance, target accuracy 95, built with `ONLINE`.
- **Answer generation:** Ollama running `gemma3:4b`, called from Oracle through `DBMS_VECTOR.UTL_TO_GENERATE_TEXT`. The existing ONNX model continues to generate embeddings inside the database.

## Scripts and brief description

There are separate setup scripts for Autonomous Database (`-ADB.sql`) and a database with access to server-side files (`-DB.sql`, such as OCI Base Database Service). Embedding generation, indexing, and search use the same scripts on both paths.

| File | Purpose |
| --- | --- |
| [01-oracle-json-user-DB.sql](01-oracle-json-user-DB.sql) | Recreates the demo schema, grants privileges, defines server directories, and optionally enables ORDS. |
| [01-oracle-json-user-ADB.sql](01-oracle-json-user-ADB.sql) | Recreates the Autonomous demo schema, grants privileges, and optionally enables ORDS. |
| [02-load-onnx-model-DB.sql](02-load-onnx-model-DB.sql) | Drops the existing model, imports the local ONNX file, and tests inference. |
| [02-load-onnx-model-ADB.sql](02-load-onnx-model-ADB.sql) | Imports the model from OCI Object Storage using a pre-authenticated request (PAR) URL. |
| [03-load-collection-DB.sql](03-load-collection-DB.sql) | Reads `movies.ndjson` through an external table and populates `J_MOVIES`. |
| [03-load-collection-ADB.sql](03-load-collection-ADB.sql) | Contains Object Storage and local-file loading alternatives; requires the adjustments below. |
| [03-load-collection-Free.sql](03-load-collection-Free.sql) | Loads the NDJSON dataset with the `ORACLE_LOADER` variant provided for Oracle AI Database Free. |
| [04-create-vector-embeddings.sql](04-create-vector-embeddings.sql) | Recreates `J_MOVIES_EMBEDDINGS` and adds plot embeddings to the movie documents. |
| [05.create_vector_index.sql](05.create_vector_index.sql) | Recreates `MOVIES_PLOT_HNSW_IDX` on the JSON embedding field and counts usable vectors. |
| [06-vector-search.oracle.sql](06-vector-search.oracle.sql) | Generates query embeddings and demonstrates nearest-neighbor search, post-filtering, and post-sorting. |
| [07-rag-admin.sql](07-rag-admin.sql) | Run as an administrator to grant the existing application user table/package privileges and access to the Ollama host and port through an Oracle network ACL. |
| [08-rag-setup.sql](08-rag-setup.sql) | Run as the application user to check the existing model and embeddings, create the answer-generation configuration, and install `MOVIE_RAG.RETRIEVE` and `MOVIE_RAG.ASK`. Existing configuration is retained. |
| [09-rag-demo.sql](09-rag-demo.sql) | Demonstrates retrieval without an LLM call, then generates movie recommendations and plot comparisons with numbered supporting sources. |
| [movies.ndjson](movies.ndjson) | Movie documents, one JSON document per line. The supplied file contains 21,349 documents. |
| [Oracle’s pretrained ONNX model catalog](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/import-pretrained-models-onnx-format-vector-generation-database.html) | Follow the download link for `all_MiniLM_L12_v2` and extract the archive to obtain `all_MiniLM_L12_v2.onnx`, the embedding model used in this repository. |




## Semantic Search examples

| Prompt | Behavior |
| --- | --- |
| `epic fantasy journey with reluctant heroes` | Finds the nearest five movie plots and demonstrates execution-plan inspection. |
| `Suspense plot about a mysterious disappearance` | Finds the nearest ten, then keeps movies whose genres contain Action, Adventure, or Sci-Fi. May return fewer than ten rows. |
| `Westerns and frontier tales` | Finds the nearest five, then sorts those candidates by year descending, with missing years last. |

The second query filters **after** selecting candidates; it does not find the nearest ten within the chosen genres. The third query changes the presentation order of five semantic matches; it does not explicitly filter on year or genre.

The queries use `FETCH APPROX ... WITH TARGET ACCURACY 95`. This requests approximate nearest neighbors; 95 is an accuracy target, not a per-result similarity score or guaranteed match percentage.

## Extend vector search with RAG

Scripts 07–10 add retrieval-augmented generation to the existing movie collection. They reuse `J_MOVIES_EMBEDDINGS`, the in-database `ALL_MINILM_L12_V2` ONNX model, and the JSON vector expression indexed by `MOVIES_PLOT_HNSW_IDX`. There is no new embedding model or movie reload. Ollama is used only to write answers.

```text
Question → in-database ONNX embedding → Oracle approximate vector search
         → numbered movie plots → Ollama → answer with supporting sources
```

| File | Purpose |
| --- | --- |
| [07-rag-admin.sql](07-rag-admin.sql) | Optional administrator grants and host/port network ACL for the existing application schema. |
| [08-rag-setup.sql](08-rag-setup.sql) | Creates provider configuration and the SQL-callable `MOVIE_RAG` package. Repeat installs retain configuration. |
| [09-rag-demo.sql](09-rag-demo.sql) | Demonstrates retrieval alone, generated recommendations, and comparisons with citations. |
| [10-rag-smoke-test.sql](10-rag-smoke-test.sql) | Checks retrieval, source evidence, distance ordering, and input validation against a live database, without calling Ollama. |

### RAG setup

1. Complete the original database/model/data/embedding/index steps (scripts 01–05) if they are not already installed. **Do not rerun the existing user-creation scripts on a working demo:** those scripts recreate the schema. The new RAG scripts do not drop the movies, model, or index.
2. Install [Ollama](https://ollama.com/download) on a host reachable from the database, start it, and download the answer model:

   ```sh
   ollama pull gemma3:4b
   ```

3. As an administrator in the application PDB, review and run `07-rag-admin.sql`. Edit the schema name, host, and port to match your environment. The existing application user needs `CREATE TABLE`, `CREATE PROCEDURE`, tablespace quota, a direct `EXECUTE` grant on `SYS.DBMS_VECTOR`, and network access to the Ollama endpoint. The Oracle installation must provide this package and its required components.
4. Connect as the existing application user (`JSON_VECTOR` by default) in SQLcl or SQL*Plus and run:

   ```sql
   @08-rag-setup.sql
   ```

5. As the application user, point `MOVIE_RAG_CONFIG` to the same Ollama host and port allowed by the administrator script. Replace `<OLLAMA_HOST>` with the address reachable from the database server:

   ```sql
   UPDATE movie_rag_config
   SET generation_params = JSON_TRANSFORM(
       generation_params,
       SET '$.url' = 'http://<OLLAMA_HOST>:11434/api/generate'
   )
   WHERE id = 1;
   COMMIT;
   ```

   For Ollama on the database host, the endpoint may be `localhost`; for a separate VM, use its reachable private IP or hostname. Change the port if your service uses a different one. The Oracle ACL and provider URL must refer to the intended destination. You can change the model by updating `$.model` in the same JSON configuration; that model must already be available in Ollama.

6. Run the examples:

   ```sql
   @09-rag-demo.sql
   ```

**The database server makes the Ollama request.** `localhost` means the database host/container, not the SQL client's machine. A container may require a host-reachable address such as `host.docker.internal`, depending on its configuration. Autonomous Database needs an endpoint reachable under its network policies; a laptop's localhost is not reachable from the cloud database. Routing, firewalls, and HTTPS trust must be configured where applicable. `host: local` disables provider credentials; it does not change the URL's destination. Keep unauthenticated Ollama endpoints restricted to your private environment.

### Verify the RAG extension

```sql
@10-rag-smoke-test.sql
```

The smoke test checks SQL invocation, source numbering, distance ordering, correspondence between returned plots and stored JSON, and invalid-input handling. It reads the existing data and model and does not call Ollama. Run `09-rag-demo.sql` to check actual answer generation and review its citations.

The installer checks `USER_ERRORS` and stops if the package fails to compile. The smoke test verifies retrieval and input handling; it does not verify Ollama connectivity or the quality of generated answers. Use `09-rag-demo.sql` against your configured endpoint to check answer generation and source citations.

If you receive `ORA-24247`, check the application's network ACL. Connection/timeouts require checking reachability from the database host. For package compilation problems, inspect `USER_ERRORS` and verify direct grants. If no sources survive, inspect `movie_rag.retrieve` with a larger distance threshold before changing the model.

Oracle references: [text generation API](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/utl_to_generate_text-dbms_vector.html), [supported provider endpoints](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/supported-third-party-provider-operations-and-endpoints.html).

## Further reading

### Related examples

- [JSON Full-Text Search with Oracle AI Database — example repository](https://github.com/JesusGitHubOracle/jlr-oracle-search)
- [Oracle JSON: From relational to document store](https://github.com/JesusGitHubOracle/jlr-oracle-json)


### Online documentation

- [Oracle AI Vector Search documentation](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/)
- [Load an ONNX model](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/load_onnx_model-procedure.html)
- [Oracle JSON in the database](https://docs.oracle.com/en/database/oracle/oracle-database/26/adjsn/json-in-oracle-database.html)
- [Query JSON data](https://docs.oracle.com/en/database/oracle/oracle-database/26/adjsn/query-json-data.html)
- [Index JSON data](https://docs.oracle.com/en/database/oracle/oracle-database/26/adjsn/overview-indexing-json-data.html)
- [SQL/JSON path expression syntax](https://docs.oracle.com/en/database/oracle/oracle-database/26/adjsn/sql-json-path-expression-syntax.html)
- [Oracle AI Database JSON Developer’s Guide](https://docs.oracle.com/en/database/oracle/oracle-database/26/adjsn/)
- [Oracle AI Vector Search User’s Guide](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/)
- [Release Update 23.26.2 — introduction of function-based HNSW indexes](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/april-2026-release-update-23.26.2.html)
- [HNSW index syntax and parameters, including function-based indexes](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/hierarchical-navigable-small-world-index-syntax-and-parameters.html)
- [Load an ONNX model with DBMS_VECTOR.LOAD_ONNX_MODEL](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/load_onnx_model-procedure.html)
- [Generate answers with DBMS_VECTOR.UTL_TO_GENERATE_TEXT](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/utl_to_generate_text-dbms_vector.html)

### Background and installation

- [Database & Cloud Technology Blog — JSON articles](https://blogs.oracle.com/coretec/category/crt-json)
- [Oracle JSON Insights](https://www.oracle.com/database/what-is-json/technologies/database/)
- [Install and run Ollama on Linux](https://docs.ollama.com/linux)

### ## Dataset and embedding model

- [Sample movie dataset — ZIP archive](https://github.com/JesusGitHubOracle/jlr-oracle-json-vector/blob/main/movies-json.zip)
- [Oracle’s pretrained ONNX model catalog](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/import-pretrained-models-onnx-format-vector-generation-database.html) — Download the `all_MiniLM_L12_v2` model and extract the archive to obtain `all_MiniLM_L12_v2.onnx`
