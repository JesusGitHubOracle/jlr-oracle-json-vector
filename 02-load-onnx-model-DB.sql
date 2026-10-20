set echo off
set serveroutput on size unlimited
set linesize 220
set pagesize 100


/*  
This script loads the all-MiniLM-L12-v2 ONNX embedding model into Oracle AiDatabase.     
*/
------------------------------------------------------------
prompt DROP model if it exists...
------------------------------------------------------------
BEGIN
    DBMS_VECTOR.DROP_ONNX_MODEL(
        model_name => 'ALL_MINILM_L12_V2'
    );
END;
/
-------------------------------------------------------------
prompt Load ONNX embedding model from directory...
------------------------------------------------------------
/*
Use provided JSON metadata for the all-MiniLM-L12-v2 ONNX embedding model.  
*/
BEGIN
    DBMS_VECTOR.LOAD_ONNX_MODEL(
        'ONNX_IMPORT',
        'all_MiniLM_L12_v2.onnx',
        'ALL_MINILM_L12_V2',
        JSON('{
            "function": "embedding",
            "embeddingOutput": "embedding",
            "input": {"input": ["DATA"]}
        }')
    );
END;
/
---------------------------------------------------------------
prompt Verify model registration...
---------------------------------------------------------------
col model_name format a30
col mining_function format a20
col algorithm format a20

select model_name, mining_function, algorithm
from   user_mining_models
where  model_name = 'ALL_MINILM_L12_V2';

prompt  test VECTOR_EMBEDDING...

select vector_embedding(
         "ALL_MINILM_L12_V2"
         using 'Oracle Database supports vector search.' as data
       ) as embedding
from dual;

 