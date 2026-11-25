 -- Call retrieve to find relevant movies without invoking Ollama:

SET DEFINE OFF
SET LONG 1000000
SET LONGCHUNKSIZE 32767
SET LINESIZE 200
SET PAGESIZE 0

SELECT movie_rag.retrieve('epic fantasy journey with reluctant heroes') FROM dual;

/*
{"question":"epic fantasy journey with reluctant heroes","sources":[{"source":1,"movie_id":"573a13eaf29313caabdcf802","title":"Short Peace","year":2013,"distance":0.44072490317901925,"plot":"A traveler is confronted by spirits in an abandoned shrine; a story of honor and firefighting in ancient Japan; a white bear defends the royal family from a monstrous red demon; ragtag soldiers battle a robotic force in futuristic Japan."},{"source":2,"movie_id":"573a1399f29313caabcee864","title":"Dr. Wai in the Scriptures with No Words","year":1996,"distance":0.4811511487902953,"plot":"A serial adventure writer with problems in his personal life lives out the adventures of his literary hero, King of Adventurers."},{"source":3,"movie_id":"573a139bf29313caabcf2614","title":"Dr. Wai in the Scriptures with No Words","year":1996,"distance":0.4811511487902953,"plot":"A serial adventure writer with problems in his personal life lives out the adventures of his literary hero, King of Adventurers."},{"source":4,"movie_id":"573a13b8f29313caabd4b667","title":"When Darkness Falls","year":2006,"distance":0.49464122596955307,"plot":"A gripping and intense thriller about honour, loyalty, and the courage to fight for what you believe."},{"source":5,"movie_id":"573a13d5f29313caabd9c2e4","title":"Catatan (Harian) si Boy","year":2011,"distance":0.5084424627720473,"plot":"A circle of friends risking their Friendship, Trust, Love and Hope in search of a legend. A young and privileged teenager with a golden heart, beset with challenges and tribulations we face..."}]}
*/

-- Call ask to find relevant movies and generate a summary answer using Ollama:
SELECT movie_rag.ask(
  'Recommend movies about an epic fantasy journey with reluctant heroes. Explain the matches using their plots.'
) FROM dual;

/*
{"question":"Recommend movies about an epic fantasy journey with reluctant heroes. Explain the matches using their plots.","answer":"Based on the provided movie information, “Short Peace” [1] and “Kundo: Age of the Rampant” [4] seem to align with the request for an epic fantasy journey with reluctant heroes. “Short Peace” describes a traveler confronting spirits and ragtag soldiers battling a robotic force, suggesting a heroic journey. “Kundo: Age of the Rampant” features a militia group battling an unjust nobility, fitting the “epic fantasy” and “reluctant heroes” criteria [4]. The other movies do not match the description.","sources":[{"source":1,"movie_id":"573a13eaf29313caabdcf802","title":"Short Peace","year":2013,"distance":0.48440659427624833,"plot":"A traveler is confronted by spirits in an abandoned shrine; a story of honor and firefighting in ancient Japan; a white bear defends the royal family from a monstrous red demon; ragtag soldiers battle a robotic force in futuristic Japan."},{"source":2,"movie_id":"573a13b8f29313caabd4b667","title":"When Darkness Falls","year":2006,"distance":0.51057883205556287,"plot":"A gripping and intense thriller about honour, loyalty, and the courage to fight for what you believe."},{"source":3,"movie_id":"573a1398f29313caabceb5c4","title":"Cold Feet","year":1989,"distance":0.51939809274485449,"plot":"A psycho-killer with mommy issues, a charming crooked cowboy and their girl steel some jewels. The cowboy decides not to share and goes on the run with the loot. A crazy chase across the country between former partners in crime begins."},{"source":4,"movie_id":"573a13e5f29313caabdc2c8b","title":"Kundo: Age of the Rampant","year":2014,"distance":0.5195005641612771,"plot":"A period action film centered on a militia group who turn against an unjust nobility."},{"source":5,"movie_id":"573a13a7f29313caabd1b387","title":"The Hexer","year":2001,"distance":0.52284625100335269,"plot":"The adventures of Geralt of Rivea, \"The Witcher\"."}]}

*/

-- compare movies using their plots
SELECT movie_rag.ask(
    p_question => 'Suggest two movies about a mysterious disappearance and compare their plots.',
    p_top_k => 5,
    p_max_distance => 0.65
) FROM dual;

/*
{"question":"Suggest two movies about a mysterious disappearance and compare their plots.","answer":"Based on the provided information, here are two movies about mysterious disappearances and a comparison of their plots:\n\n“Uncle John” [1] concerns the struggle to solve a mysterious disappearance. “The Fourth Kind” [2] focuses on an ongoing mystery in Alaska involving numerous unexplained disappearances and alleged federal cover-ups. “For Sale” [3] follows a private detective investigating a woman who vanished on her wedding day, tracing her life through interviews. \n\nThese films share the common theme of unexplained disappearances, though their approaches and contexts differ significantly.","sources":[{"source":1,"movie_id":"573a13e8f29313caabdca5d0","title":"Uncle John","year":2015,"distance":0.42837374393954375,"plot":"Revolves around the struggle to keep a mysterious disappearance unsolved."},{"source":2,"movie_id":"573a13c1f29313caabd65214","title":"The Fourth Kind","year":2009,"distance":0.4703999598155072,"plot":"A thriller involving an ongoing unsolved mystery in Alaska, where one town has seen an extraordinary number of unexplained disappearances during the past 40 years and there are accusations of a federal cover up."},{"source":3,"movie_id":"573a139bf29313caabcf2508","title":"For Sale","year":1998,"distance":0.47990583648017837,"plot":"A Private detective is hired to trace a woman who ran away and disappeared on her wedding day. The movie follows him and recounts the story of her life through her eyes and the eyes of those interviewed by the detective."},{"source":4,"movie_id":"573a13c1f29313caabd65741","title":"Extraordinary Stories","year":2008,"distance":0.48777011126284986,"plot":"In this adventurous experiment in storytelling, secret identities, missing persons, lost treasures, exotic beasts and desperate criminals are only a few of the elements woven into a grand tapestry of mysteries."},{"source":5,"movie_id":"573a13b1f29313caabd3752b","title":"Red Eye","year":2005,"distance":0.48778760408942823,"plot":"A woman is kidnapped by a stranger on a routine flight. Threatened by the potential murder of her father, she is pulled into a plot to assist her captor in offing a politician."}]}


