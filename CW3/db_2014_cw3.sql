-- Q1 returns (first_name)
SELECT SUBSTRING(name FROM 1 FOR (POSITION(' ' IN name)+LENGTH(name))%(LENGTH(name)+1)) AS first_name
FROM person
ORDER BY first_name
;

-- Q2 returns (born_in,popularity)
SELECT born_in,
	     COUNT(person) AS popularity
FROM person
GROUP BY born_in
ORDER BY popularity DESC, born_in
;

-- Q3 returns (house,seventeenth,eighteenth,nineteenth,twentieth)
SELECT house,
       COUNT(CASE WHEN accession BETWEEN '1600-01-01' AND '1699-12-31' THEN name ELSE NULL END) AS seventeenth,
       COUNT(CASE WHEN accession BETWEEN '1700-01-01' AND '1799-12-31' THEN name ELSE NULL END) AS eighteenth,
       COUNT(CASE WHEN accession BETWEEN '1800-01-01' AND '1899-12-31' THEN name ELSE NULL END) AS nineteenth,
	     COUNT(CASE WHEN accession BETWEEN '1900-01-01' AND '1999-12-31' THEN name ELSE NULL END) AS twentieth
FROM monarch
WHERE house IS NOT NULL
GROUP BY house
ORDER BY house
; 

-- Q4 returns (name,age)
SELECT * 
FROM (
  SELECT father.name AS name,
         DATE_PART('year', AGE(child.dob,father.dob)) AS AGE
  FROM person AS child
  JOIN person AS father ON child.father = father.name
  WHERE child.dob <= ALL(SELECT dob 
                         FROM person
                         WHERE father = father.name)
  UNION ALL
  SELECT mother.name AS name,
         DATE_PART('year', AGE(child.dob,mother.dob)) AS AGE
  FROM person AS child
  JOIN person AS mother ON child.mother = mother.name 
  WHERE child.dob <= ALL(SELECT dob 
                         FROM person
                         WHERE mother = mother.name)
) AS parents
ORDER BY name
;

-- Q5 returns (father,child,born)
SELECT father.name AS father,
       children.name as child,
       CASE WHEN children.name IS NOT NULL 
            THEN RANK() OVER
         		(PARTITION BY father.name ORDER BY children.dob) 
            ELSE 0
       END AS born
FROM person AS father
LEFT JOIN person AS children ON father.name = children.father
WHERE father.gender = 'M'
;

-- Q6 returns (monarch,prime_minister)
-- FIRST: SELECT ALL monarchs & PMs where the PM's TERM BEGINS BEFORE THE MONARCH'S SUCCESSION
SELECT mon.name AS monarch,
       pm.name AS prime_minister
FROM monarch AS mon
JOIN person ON mon.name = person.name
LEFT JOIN monarch AS successor ON mon.accession < successor.accession
AND successor.accession <= ALL( SELECT accession
                                FROM monarch
                                WHERE monarch.accession > mon.accession)
JOIN prime_minister AS pm ON pm.entry <= COALESCE(successor.accession, CURRENT_DATE)
INTERSECT
-- SECOND: I SELECT ALL monarchs & PMs where PM's TERM *ENDS* AFTER THE MONARCH's ACCESSION
SELECT monarch.name AS monarch,
       pm.name AS prime_minister
FROM prime_minister pm
LEFT JOIN prime_minister AS successor ON pm.entry < successor.entry
AND successor.entry <= ALL( SELECT entry
                            FROM prime_minister
                            WHERE prime_minister.entry > pm.entry)
JOIN monarch ON COALESCE(successor.entry, CURRENT_DATE) >= monarch.accession
;


