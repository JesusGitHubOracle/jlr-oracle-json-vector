 

/* Run this script as sys or system on the Pluggable Database (PDB).
 This script will create a new user JSON_VECTOR with the required privileges to run the other scripts in this repository. 
 It will also enable ORDS for the user (optional), just in case you want to use the Oracle API for MongoDB to access the JSON collection.
The user will be created with a password of DB23ee###12345. You can change this password in the script if you wish.
*/

DROP USER IF EXISTS JSON_VECTOR CASCADE;
CREATE USER JSON_VECTOR IDENTIFIED BY DB23ee###12345;
ALTER USER JSON_VECTOR QUOTA UNLIMITED ON USERS; 

GRANT CONNECT, RESOURCE, SODA_APP, DB_DEVELOPER_ROLE TO JSON_VECTOR;
GRANT READ, WRITE ON DIRECTORY DATA_PUMP_DIR TO JSON_VECTOR;

-- Grant additional privileges for vector operations

GRANT CREATE MINING MODEL TO JSON_VECTOR;
GRANT EXECUTE ON DBMS_VECTOR TO JSON_VECTOR;

--  Directory for ONNX model import
-- copy ALL_MINILM_L12_V2.onnx to /home/oracle/onnx_models on the database server

CREATE DIRECTORY ONNX_IMPORT AS '/home/oracle/onnx_models';
GRANT READ, WRITE ON DIRECTORY ONNX_IMPORT TO JSON_VECTOR;

-- Directory for json files,  copy movies.ndjson to /home/oracle on the database server
CREATE DIRECTORY MOVIES_DIR AS '/home/oracle';
GRANT READ, WRITE ON DIRECTORY MOVIES_DIR TO JSON_VECTOR;

--   Enable ORDS (Optional)
BEGIN
  ORDS_ADMIN.ENABLE_SCHEMA(
    p_enabled             => TRUE,
    p_schema              => 'JSON_VECTOR',
    p_url_mapping_pattern => 'JSON_VECTOR'
  );
  COMMIT;
END;
/

