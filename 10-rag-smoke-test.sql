-- Optional LIVE database test. Requires the ONNX model and movie embeddings.
-- Does not modify movies/configuration or contact Ollama.
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET DEFINE OFF
SET SERVEROUTPUT ON
DECLARE
  l_text CLOB;
  l_result JSON_OBJECT_T;
  l_sources JSON_ARRAY_T;
  l_source JSON_OBJECT_T;
  l_match_count NUMBER;
  l_movie_id VARCHAR2(4000);
  l_plot VARCHAR2(4000);
  l_previous_distance NUMBER := -1;
BEGIN
  SELECT movie_rag.retrieve('epic fantasy journey with reluctant heroes', 5, 2)
  INTO l_text FROM dual;
  l_result := JSON_OBJECT_T.parse(l_text);
  l_sources := l_result.get_array('sources');
  IF l_sources.get_size() < 1 OR l_sources.get_size() > 5 THEN
    raise_application_error(-20100, 'Expected between one and five movie sources.');
  END IF;
  FOR i IN 0..l_sources.get_size() - 1 LOOP
    l_source := TREAT(l_sources.get(i) AS JSON_OBJECT_T);
    IF l_source.get_number('source') != i + 1
       OR l_source.get_number('distance') < l_previous_distance THEN
      raise_application_error(-20101, 'Invalid source numbering or distance order.');
    END IF;
    l_previous_distance := l_source.get_number('distance');
    l_movie_id := l_source.get_string('movie_id');
    l_plot := l_source.get_string('plot');
    SELECT COUNT(*) INTO l_match_count FROM J_MOVIES_EMBEDDINGS
    WHERE JSON_VALUE(data, '$._id."$oid"') = l_movie_id
      AND JSON_VALUE(data, '$.plot' RETURNING VARCHAR2(4000) NULL ON ERROR) = l_plot;
    IF l_match_count = 0 THEN
      raise_application_error(-20102, 'Returned evidence does not match the movie collection.');
    END IF;
  END LOOP;
  BEGIN
    l_text := movie_rag.ask('   ');
    raise_application_error(-20103, 'Blank question was accepted.');
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -20012 THEN RAISE; END IF;
  END;
  BEGIN
    l_text := movie_rag.retrieve('fantasy', 0, 2);
    raise_application_error(-20104, 'Invalid top_k was accepted.');
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -20014 THEN RAISE; END IF;
  END;
  DBMS_OUTPUT.put_line('PASS: SQL invocation, source numbering, distance order, original plot evidence, and input validation.');
END;
/
-- Run 09-rag-demo.sql separately to check Ollama answers and citations manually.
