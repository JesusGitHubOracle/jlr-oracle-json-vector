WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET DEFINE OFF
SET LONG 1000000
SET LONGCHUNKSIZE 32767
SET LINESIZE 200
SET PAGESIZE 0

PROMPT Retrieval only: inspect the evidence without calling Ollama.
SELECT movie_rag.retrieve('epic fantasy journey with reluctant heroes') FROM dual;

PROMPT RAG: generate a recommendation using the retrieved plots and cite sources.
SELECT movie_rag.ask(
  'Recommend movies about an epic fantasy journey with reluctant heroes. Explain the matches using their plots.'
) FROM dual;

PROMPT RAG: compare candidates about a mysterious disappearance.
SELECT movie_rag.ask(
  p_question => 'Suggest two movies about a mysterious disappearance and compare their plots.',
  p_top_k => 5,
  p_max_distance => 0.65
) FROM dual;
 
