-- Optional RAG administrator step. Run in the same PDB as JSON_VECTOR.
-- Edit host/port to match the URL in MOVIE_RAG_CONFIG (08-rag-setup.sql).
-- Does not recreate the existing demo user, movies, model, or index.
DEFINE rag_user = JSON_VECTOR
--DEFINE ollama_host = localhost -- linux server  
 DEFINE ollama_host = localhost.container -- macOS or Windows with Ollama Desktop
DEFINE ollama_port = 11434

GRANT CREATE TABLE, CREATE PROCEDURE TO &&rag_user;
GRANT EXECUTE ON SYS.DBMS_VECTOR TO &&rag_user;

BEGIN
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host => '&&ollama_host',
    lower_port => &&ollama_port,
    upper_port => &&ollama_port,
    ace => xs$ace_type(
      privilege_list => xs$name_list('connect'),
      principal_name => '&&rag_user',
      principal_type => xs_acl.ptype_db));
END;
/
-- localhost is the DATABASE host/container, not the SQL client's machine.
-- Autonomous Database requires an endpoint reachable under its network policies;
-- this host ACL alone does not establish network routing or HTTPS trust.


  