 

SET LONG 100000
SET LONGCHUNKSIZE 100000
SET LINESIZE 200
SET PAGESIZE 100
SET VERIFY OFF

---------------------------------------------------------------------------------------------------------     
--  Generate and store the query embedding on a CLOB variable for use in subsequent vector search queries
--------------------------------------------------------------------------------------------------------- 
VARIABLE query_vector0_json CLOB
BEGIN
    SELECT VECTOR_SERIALIZE(
               VECTOR_EMBEDDING(
                   ALL_MINILM_L12_V2 USING
                   'epic fantasy journey with reluctant heroes' AS DATA
               ) RETURNING CLOB
           )
    INTO :query_vector0_json
    FROM dual;
END;
/


*/  
------------------------------------------------------------------------------------------------------------------------------- 
-- Finds the nearest ten, then keeps movies whose genres contain Action, Adventure, or Sci-Fi. May return fewer than ten rows.
------------------------------------------------------------------------------------------------------------------------------- 
SET LONG 100000
SET PAGESIZE 50000

COLUMN title FORMAT A30
COLUMN year FORMAT 9999
COLUMN genres FORMAT A40
COLUMN fullplot FORMAT A80

-- generate emmbeddings
VARIABLE query_vector0_json CLOB
BEGIN
    SELECT VECTOR_SERIALIZE(
               VECTOR_EMBEDDING(
                   ALL_MINILM_L12_V2 USING
                   'epic fantasy journey with reluctant heroes' AS DATA
               ) RETURNING CLOB
           )
    INTO :query_vector0_json
    FROM dual;
END;
/


SELECT JSON_VALUE(
           DATA, '$.title' RETURNING VARCHAR2(4000)
       ) AS title,
       JSON_VALUE(
           DATA, '$.year' RETURNING NUMBER
       ) AS year,
       JSON_QUERY(
           DATA, '$.genres' RETURNING CLOB
       ) AS genres,
       JSON_VALUE(
           DATA, '$.fullplot' RETURNING CLOB
       ) AS fullplot
FROM J_MOVIES_EMBEDDINGS
ORDER BY VECTOR_DISTANCE(
             JSON_VALUE(
                 DATA,
                 '$.plot_embedding'
                 RETURNING VECTOR(384, FLOAT32)
             ),
             TO_VECTOR(:query_vector0_json, 384, FLOAT32),
             COSINE
         )
FETCH APPROX FIRST 5 ROWS ONLY
WITH TARGET ACCURACY 95;


/*
TITLE                                         YEAR GENRES                              FULLPLOT                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
__________________________________________ _______ ___________________________________ ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________ 
Short Peace                                   2013 ["Animation","Fantasy","Sci-Fi"]    A traveler is confronted by spirits in an abandoned shrine; a story of honor and firefighting in ancient Japan; a white bear defends the royal family from a monstrous red demon; ragtag soldiers battle a robotic force in futuristic Japan.                                                                                                                                                                                                                                                                
Dr. Wai in the Scriptures with No Words       1996 ["Action","Adventure"]              A serial adventure writer with problems in his personal life lives out the adventures of his literary hero, King of Adventurers.                                                                                                                                                                                                                                                                                                                                                                             
Dr. Wai in the Scriptures with No Words       1996 ["Action","Adventure"]              A serial adventure writer with problems in his personal life lives out the adventures of his literary hero, King of Adventurers.                                                                                                                                                                                                                                                                                                                                                                             
When Darkness Falls                           2006 ["Drama"]                           Two young sisters act against their family's "code of honour" and their lives become a deadly nightmare. Two bouncers at a popular club are attacked by criminals igniting total war. An award winning journalist presses charges of spousal abuse against her husband only to become a hated pariah amongst their common colleagues. But what none of their aggressors could have foreseen is the enormous will to fight and prevail that is awaked in the hearts of those threatened one time too many.    
Catatan (Harian) si Boy                       2011 ["Action","Drama","Romance"]        A circle of friends risking their Friendship, Trust, Love and Hope in search of a legend. A young and privileged teenager with a golden heart, beset with challenges and tribulations we face today with the goal to open many young people's mind with inspirations and hopes that drive them in achieving their dreams. To get out of their comfort zone and finish what they started.

*/

 
--------------------------------------------------------------------------------------------------------- 
-- Finds the nearest five movie plots and demonstrates execution-plan inspection.
--------------------------------------------------------------------------------------------------------- 
EXPLAIN PLAN FOR
SELECT
       JSON_VALUE(data, '$.title' RETURNING VARCHAR2(4000)) AS title,
       JSON_VALUE(data, '$.year' RETURNING NUMBER) AS year,
       JSON_QUERY(data, '$.genres' RETURNING CLOB) AS genres,
       JSON_VALUE(data, '$.fullplot' RETURNING CLOB) AS fullplot
FROM J_MOVIES_EMBEDDINGS
ORDER BY VECTOR_DISTANCE(
           JSON_VALUE(data, '$.plot_embedding'
                      RETURNING VECTOR(384, FLOAT32)),
           TO_VECTOR(:query_vector0_json, 384, FLOAT32),
           COSINE
       )
FETCH APPROX FIRST 5 ROWS ONLY WITH TARGET ACCURACY 95;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());


/* Execution plan notes:

   * The FETCH APPROX clause allows for approximate nearest neighbor search, which can improve performance.
   * The target accuracy of 95% indicates that the results may not be exact but should be close to the true nearest neighbors.

------------------------------------------------------------------------------------------------------    
| Id  | Operation                      | Name                | Rows  | Bytes | Cost (%CPU)| Time     |    
------------------------------------------------------------------------------------------------------    
|   0 | SELECT STATEMENT               |                     |     5 |   169K|     2  (50)| 00:00:01 |    
|*  1 |  COUNT STOPKEY                 |                     |       |       |            |          |    
|   2 |   VIEW                         |                     |     5 |   169K|     2  (50)| 00:00:01 |    
|*  3 |    SORT ORDER BY STOPKEY       |                     |     5 | 25880 |     2  (50)| 00:00:01 |
|   4 |     TABLE ACCESS BY INDEX ROWID| J_MOVIES_EMBEDDINGS |     5 | 25880 |     1   (0)| 00:00:01 |    
|   5 |      VECTOR INDEX HNSW SCAN    | PLOT_VEC_IDX        |     5 | 25880 |     1   (0)| 00:00:01 |    
------------------------------------------------------------------------------------------------------    
                                                                                                        
*/

---------------------------------------------------------------------------------------------------------
-- selects the ten nearest candidates, then keeps movies whose genres include Action, Adventure, or Sci-Fi
---------------------------------------------------------------------------------------------------------
-- generate embeddings
VARIABLE query_vector1_json CLOB
BEGIN
    SELECT VECTOR_SERIALIZE(
               VECTOR_EMBEDDING(
                   ALL_MINILM_L12_V2 USING
                   'Suspense plot about a mysterious disappearance' AS DATA
               ) RETURNING CLOB
           )
    INTO :query_vector1_json
    FROM dual;
END;
/
WITH nearest_movies AS (
    SELECT data,
           VECTOR_DISTANCE(
           JSON_VALUE(data, '$.plot_embedding'
                      RETURNING VECTOR(384, FLOAT32)),
           TO_VECTOR(:query_vector1_json, 384, FLOAT32),
           COSINE
       ) AS distance
    FROM J_MOVIES_EMBEDDINGS
    ORDER BY distance
    FETCH APPROX FIRST 10 ROWS ONLY WITH TARGET ACCURACY 95
)
SELECT
       JSON_VALUE(data, '$.title' RETURNING VARCHAR2(4000)) AS title,
       JSON_VALUE(data, '$.year' RETURNING NUMBER) AS year,
       JSON_QUERY(data, '$.genres' RETURNING CLOB) AS genres,
       JSON_VALUE(data, '$.fullplot' RETURNING CLOB) AS fullplot
FROM nearest_movies
WHERE JSON_EXISTS(
    data,
    '$.genres[*]?(@ == "Action" || @ == "Adventure" || @ == "Sci-Fi")'
)
ORDER BY distance;

/*
TITLE                           YEAR GENRES                                   FULLPLOT                                                                        
------------------------------ ----- ---------------------------------------- --------------------------------------------------------------------------------
The Fourth Kind                 2009 ["Mystery","Sci-Fi","Thriller"]          In 1972, a scale of measurement was established for alien encounters. When a UFO
                                                                               is sighted, it is called an encounter of the first kind. When evidence is colle
                                                                              cted, it is known as an encounter of the second kind. When contact is made with 
                                                                              extraterrestrials, it is the third kind. The next level, abduction, is the fourt
                                                                              h kind. Modern-day, Alaska, where-mysteriously since the 1960s-a disproportionat
                                                                              e number of the population has been reported missing every year. Despite multipl
                                                                              e FBI investigations of the region, the truth has never been discovered. Here in
                                                                               this remote region, psychologist Dr. Abigail Tyler began videotaping sessions w
                                                                              ith traumatized patients and unwittingly discovered some of the most disturbing 
                                                                              evidence of alien abduction ever documented. The Fourth Kind exposes the terrifi
                                                                              ed revelations of multiple witnesses. Their accounts of being visited by alien f
                                                                             igures all share disturbingly identical details, the validity of which is invest
                                                                              igated throughout the film.


*/



--------------------------------------------------------------------------------------------------------- 
-- Finds the nearest five, then sorts those candidates by year descending,newest first:
--------------------------------------------------------------------------------------------------------- 
SET LONG 100000
SET PAGESIZE 50000

COLUMN title FORMAT A30
COLUMN year FORMAT 9999
COLUMN genres FORMAT A40
COLUMN fullplot FORMAT A80

-- generate embeddings
VARIABLE query_vector2_json CLOB
BEGIN
    SELECT VECTOR_SERIALIZE(
               VECTOR_EMBEDDING(
                   ALL_MINILM_L12_V2 USING
                   'Westerns and frontier tales' AS DATA
               ) RETURNING CLOB
           )
    INTO :query_vector2_json
    FROM dual;
END;
/

WITH nearest_movies AS (
    SELECT DATA,
           VECTOR_DISTANCE(
               JSON_VALUE(
                   DATA,
                   '$.plot_embedding'
                   RETURNING VECTOR(384, FLOAT32)
               ),
               TO_VECTOR(:query_vector2_json, 384, FLOAT32),
               COSINE
           ) AS distance
    FROM J_MOVIES_EMBEDDINGS
    ORDER BY distance
    FETCH APPROX FIRST 5 ROWS ONLY
    WITH TARGET ACCURACY 95
)
SELECT JSON_VALUE(
           DATA, '$.title' RETURNING VARCHAR2(4000)
       ) AS title,
       JSON_VALUE(
           DATA, '$.year' RETURNING NUMBER
       ) AS year,
       JSON_QUERY(
           DATA, '$.genres' RETURNING CLOB
       ) AS genres,
       JSON_VALUE(
           DATA, '$.fullplot' RETURNING CLOB
       ) AS fullplot
FROM nearest_movies
ORDER BY year DESC NULLS LAST;

/*
TITLE                           YEAR GENRES                                   FULLPLOT                                                                        
------------------------------ ----- ---------------------------------------- --------------------------------------------------------------------------------
Dead Man's Burden               2012 ["Drama","Western"]                      A western set on the New Mexico frontier a few years after the Civil War and cen
                                                                              tered on a struggling young family and the mining company who wants to buy their
                                                                               land.                                                                          

Bury My Heart at Wounded Knee   2007 ["Drama","History","Western"]            Beginning just after the bloody Sioux victory over General Custer at Little Big 
                                                                              Horn, Bury My Heart at Wounded Knee intertwines the perspectives of three charac
                                                                              ters: Charles Eastman, nè Ohiyesa, a young, Dartmouth-educated, Sioux doctor hel
                                                                              d up as living proof of the alleged success of assimilation; Sitting Bull, the p
                                                                              roud Lakota chief who refuses to submit to U.S. government policies designed to 
                                                                              strip his people of their identity, their dignity and their sacred land - the go
                                                                              ld-laden Black Hills of the Dakotas; and Senator Henry Dawes, who was one of the
                                                                               architects of the government policy on Indian affairs. While Eastman and patric
                                                                              ian schoolteacher Elaine Goodale work to improve life for the Indians on the res
                                                                              ervation, Senator Dawes lobbies President Grant for more humane treatment, oppos
                                                                              ing the bellicose stance of General William Tecumseh Sherman. Hope rises for the
                                                                               Indians in the form of the prophet Wovoka and the Ghost Dance - a messianic mov
                                                                              ement that promises an end of their suffering under the white man. This hope is 
                                                                              obliterated after the assassination of Sitting Bull and the massacre of hundreds
                                                                               of Indian men, women and children by the 7th Cavalry at Wounded Knee Creek on D
                                                                              ec. 29, 1890.                                                                   

Into the West                   2005 ["Western","Adventure","Drama"]          An epic tale of two figures during the American colonization of the west, one wh
                                                                              ite and the other Native American. Jacob Wheeler leaves his dull life behind to 
                                                                              strike out west, while Loved By the Buffalo faces his destiny to try to fight a 
                                                                              prophecy that his people will be wiped out by the settlers. Jacob marries Loved 
                                                                              By the Buffalo's sister Thunder Heart Woman, uniting the two families while arou
                                                                              nd them relations between the two races crumble.                                

How the West Was Won            1962 ["Western"]                              Sprawling epic which follows the Prescotts, an emigrant family through four gene
                                                                              rations, from the Erie Canal in the 1830's to their settled home in the West a h
                                                                              alf a century later. On the way they encounter river pirates, and escape with th
                                                                              e help of fur trapper Linus Rawlings, who subsequently marries one of their daug
                                                                              hters, Eve. The parents are drowned on a foundering raft, and the other daughter
                                                                               Lilith becomes a riverboat singer and catches the eye of a genteel adventurer C
                                                                              leve Van Valen. They cross the plains together in a wagon train and make and los
                                                                              e a fortune in California; meanwhile Linus has turned farmer and, comes the Civi
                                                                              l War, joins the Union Army and is killed at the Battle of Shiloh. One of his so
                                                                              ns Zeb also joins the army and stays after the war as a cavalry officer and is s
                                                                              ent to Colorado to help guard the pioneering railroad against the Indians, whose
                                                                               land they are crossing. By this time Lilith is the elderly lady of the family, 
                                                                              having survived long enough to see the dream of settlement realized, but not, me
                                                                              rcifully, the aerial shots of the Los Angeles freeway traffic with which the fil
                                                                              m ends.                                                                         

Wild and Woolly                 1917 ["Comedy","Western","Romance"]           A rich young Easterner who has always wanted to live in "the Wild West" plans to
                                                                               move to a Western town. Unknown to him, the town's "wild" days are long gone, a
                                                                              nd it is an orderly, civilized place now. The townsmen, not wanting to lose a ri
                                                                              ch potential resident, contrive to make over the town to suit the young man's fa                                                                 ntasy.

*/
