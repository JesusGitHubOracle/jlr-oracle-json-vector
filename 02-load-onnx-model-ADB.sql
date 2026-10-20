set echo on
set serveroutput on size unlimited
set define on
set linesize 220
set pagesize 100


/*  Load the augmented all-MiniLM-L12-v2 ONNX embedding model into Autonomous Database from an OCI Object Storage PAR URL.
  Use dbms_vector.load_onnx_model_cloud() to load the model from the PAR URL.
  The model will be registered in the database and can be used for vector embedding operations.
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

--------------------------------------------------------------  
prompt Load ONNX embedding model from PAR URL...
--------------------------------------------------------------
begin
  dbms_vector.load_onnx_model_cloud(
    model_name => 'ALL_MINILM_L12_V2',
    credential => null,
    uri        => 'https://objectstorage.eu-frankfurt-1.oraclecloud.com/p/hWtxHRNpBnQKaxtj5KtGVyQu4VYHqtuqAY4PUReK_6NxCeZRl94vm07lMGZAuOih/n/fro8fl9kuqli/b/bucket-for-ajd-data/o/vector-data/all_MiniLM_L12_v2.onnx',
    metadata   => json('{
      "function": "embedding",
      "embeddingOutput": "embedding",
      "input": { "input": ["DATA"] }
    }')
  );
end;
/
----------------------------------------------------------------
-- Verify model registration...
----------------------------------------------------------------
prompt Verify model registration...


col model_name format a30
col mining_function format a20
col algorithm format a20

select model_name, mining_function, algorithm
from   user_mining_models
where  model_name = 'ALL_MINILM_L12_V2';
---------------------------------------------------------------
-- test embedding with a sample text input
---------------------------------------------------------------
prompt  test VECTOR_EMBEDDING...

select vector_embedding(
         "ALL_MINILM_L12_V2"
         using 'Oracle Database supports vector search.' as data
       ) as embedding
from dual;
 