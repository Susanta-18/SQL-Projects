use lco_films;

-- Q1) Which categories of movies released in 2018? Fetch with the number of movies. 

SELECT
film.film_id,
film.title,
film.release_year,
category.`name`
FROM 
film
LEFT JOIN film_category ON film_category.film_id = film.film_id
LEFT JOIN category ON category.category_id = film_category.category_id
WHERE film.release_year = 2018;

SELECT
COUNT(film.film_id)
FROM 
film
LEFT JOIN film_category ON film_category.film_id = film.film_id
LEFT JOIN category ON category.category_id = film_category.category_id
WHERE film.release_year = 2018;

-- Q2) Update the address of actor id 36 to “677 Jazz Street”.

UPDATE address
INNER JOIN actor ON actor.address_id = address.address_id
SET address.address = '677 Jazz Street'
WHERE actor_id = 36;

-- Q3) Add the new actors (id : 105 , 95) in film  ARSENIC INDEPENDENCE (id:41).

INSERT INTO film_actor (actor_id,film_id)
VALUES (105,41),(95,41);

-- Q4) Get the name of films of the actors who belong to India.

SELECT DISTINCT
film.title
FROM 
film 
INNER JOIN film_actor ON film_actor.film_id = film.film_id
INNER JOIN actor ON actor.actor_id = film_actor.actor_id
INNER JOIN address ON address.address_id = actor.address_id
INNER JOIN city ON city.city_id = address.city_id
INNER JOIN country ON country.country_id = city.country_id
WHERE country.country = 'India';

-- Q5) How many actors are from the United States?

SELECT 
COUNT(actor_id)
FROM 
actor
INNER JOIN address ON address.address_id = actor.address_id
INNER JOIN city ON city.city_id = address.city_id
INNER JOIN country ON country.country_id = city.country_id
WHERE country = 'United States';

-- Q6) Get all languages in which films are released in the year between 2001 and 2010.

SELECT
film.film_id, film.title, film.release_year,
film.language_id,
`language`.`name`
FROM
film
INNER JOIN `language` ON `language`.language_id = film.language_id
WHERE film.release_year BETWEEN 2001 AND 2010
ORDER BY film.release_year;

-- Q7) The film ALONE TRIP (id:17) was actually released in Mandarin, update the info.

UPDATE
film
INNER JOIN `language` ON `language`.language_id = film.language_id
SET film.language_id = 4
WHERE film.film_id = 17;

-- Q8) Fetch cast details of films released during 2005 and 2015 with PG rating.

SELECT
CONCAT(actor.first_name, "  ",
actor.last_name) AS Actors_Name,
film.title,
film.release_year,
film.rating
FROM 
film
INNER JOIN film_actor ON film_actor.film_id = film.film_id
INNER JOIN actor ON actor.actor_id = film_actor.actor_id
WHERE
film.release_year BETWEEN 2005 AND 2015 AND film.rating = "PG";


-- Q9) In which year most films were released?
SELECT 
release_year,
COUNT(release_year) AS TotalNo_released_Films
FROM film
GROUP BY release_year
ORDER BY TotalNo_released_Films DESC;

-- Q10) In which year least number of films were released?

SELECT 
release_year,
COUNT(release_year) AS TotalNo_released_Films
FROM film
GROUP BY release_year
ORDER BY TotalNo_released_Films LIMIT 1;

-- Q11) Get the details of the film with maximum length released in 2014 .

SELECT *
FROM
film 
WHERE release_year = 2014 AND length = (SELECT MAX(film.length) FROM film);

-- Q12) Get all Sci- Fi movies with NC-17 ratings and language they are screened in.

SELECT 
film.title AS Movie_Names,
category.`name`,
film.rating,
`language`.`name`
FROM 
film
INNER JOIN `language` ON `language`.language_id = film.language_id
INNER JOIN film_category ON film_category.film_id = film.film_id
INNER JOIN category ON category.category_id = film_category.category_id
WHERE category.name = 'Sci-Fi' AND film.rating = 'NC-17';

/* Q13) The actor FRED COSTNER (id:16) shifted to a new address:
 055,  Piazzale Michelangelo, Postal Code - 50125 , District - Rifredi at Florence, Italy. 
Insert the new city and update the address of the actor.*/


INSERT INTO `city`(`city`, `country_id`) 
VALUES ("Florence",(SELECT country_id FROM country WHERE country.country = "Italy"));

UPDATE address
INNER JOIN actor ON actor.address_id = address.address_id 
SET address.address = "055,  Piazzale Michelangelo", address.district = "Rifredi ", 
address.city_id = (SELECT city_id FROM city WHERE city.city = "Florence") , 
address.postal_code = "50125" WHERE actor.actor_id = 16;

/* Q14) A new film “No Time to Die” is releasing in 2020 whose details are : 
Title :- No Time to Die
Description: Recruited to rescue a kidnapped scientist, globe-trotting spy James Bond finds 
himself hot on the trail of a mysterious villain, who's armed with a dangerous new technology.
Language: English
Org. Language : English
Length : 100
Rental duration : 6
Rental rate : 3.99
Rating : PG-13
Replacement cost : 20.99
Special Features = Trailers,Deleted Scenes

Insert the above data.
*/
INSERT INTO film (title,description,release_year,language_id,
rental_duration,rental_rate,length,replacement_cost,
rating,special_features)
values ("No Time to Die", "Recruited to rescue a kidnapped scientist, globe-trotting spy James Bond finds himself hot on the trail of a mysterious villain who's armed `with` a dangerous `new` technology",
2020,(SELECT language_id FROM `language` WHERE `name` = 'English'),6,3.99,100,20.99,"PG-13","Trailers,Deleted Scenes");


-- Q15) Which actor acted in most movies?

SELECT 
first_name,
last_name,
film_actor.ACTOR_ID,
COUNT(film_actor.FILM_ID) AS Total_film
FROM 
actor
LEFT JOIN film_actor ON film_actor.actor_id = actor.actor_id
GROUP BY film_actor.ACTOR_ID
ORDER BY COUNT(film_actor.FILM_ID) DESC ;

-- Q16) The actor JOHNNY LOLLOBRIGIDA was removed from the movie GRAIL FRANKENSTEIN. How would you update that record?

DELETE from film_actor
where actor_id= (select
actor_id
from actor where first_name = 'JOHNNY' AND last_name = 'LOLLOBRIGIDA') AND
film_id = (select
film_id
from film where title = 'GRAIL FRANKENSTEIN');

-- Q17) The HARPER DYING movie is an animated movie with Drama and Comedy. Assign these categories to the movie.

INSERT INTO `film_category`(`category_id`, `film_id`)
VALUES 
	((SELECT category_id FROM category WHERE category.name="Drama"), (SELECT film_id FROM film WHERE film.title ="HARPER DYING")),
	((SELECT category_id FROM category WHERE category.name="Comedy"),(SELECT film_id FROM film WHERE film.title ="HARPER DYING"))
ON DUPLICATE KEY UPDATE film_id = VALUES(film_id) , category_id = VALUES(category_id);

/*Q18) The entire cast of the movie WEST LION has changed. The new actors are DAN TORN, 
MAE HOFFMAN, SCARLETT DAMON. How would you update the record in the safest way?*/

DELETE FROM film_actor
WHERE film_id = (SELECT film_id FROM film WHERE title = 'WEST LION');

INSERT INTO film_actor (actor_id,film_id)
VALUES
	((SELECT actor_id FROM actor WHERE first_name='DAN' AND last_name = 'TORN'), (SELECT film_id FROM film WHERE film.title = 'WEST LION')),
    ((SELECT actor_id FROM actor WHERE first_name='MAE' AND last_name = 'HOFFMAN'), (SELECT film_id FROM film WHERE film.title = 'WEST LION')),
	((SELECT actor_id FROM actor WHERE first_name='SCARLETT' AND last_name = 'DAMON'), (SELECT film_id FROM film WHERE film.title = 'WEST LION'))
ON DUPLICATE KEY UPDATE actor_id = VALUES(actor_id), film_id = VALUES(film_id);


/* Q19) The entire category of the movie WEST LION was wrongly inserted. The correct categories are Classics, Family, Children.
How would you update the record ensuring no wrong data is left?*/

DELETE FROM film_category
WHERE film_id = (select film_id from film where title = 'WEST LION');

INSERT INTO film_category(film_id, category_id)
VALUES
((select film_id from film where title = 'WEST LION'), (SELECT category_id FROM category WHERE `name` = 'Classics')),
((select film_id from film where title = 'WEST LION'), (SELECT category_id FROM category WHERE `name` = 'Family')),
((select film_id from film where title = 'WEST LION'), (SELECT category_id FROM category WHERE `name` = 'Children'))
ON duplicate key update film_id = VALUES(film_id), category_id = VALUES(category_id);

-- Q20) How many actors acted in films released in 2017?

SELECT 
COUNT(actor_id)
FROM 
film
INNER JOIN film_actor ON film_actor.film_id = film.film_id
WHERE film.release_year = 2017;

-- Q21) How many Sci-Fi films released between the year 2007 to 2017?

SELECT
COUNT(film.film_id)
FROM 
film
INNER JOIN film_category ON film_category.film_id = film.film_id
INNER JOIN category ON category.category_id = film_category.category_id
WHERE category.`name` = 'Sci-Fi' AND film.release_year BETWEEN 2007 AND 2017;

-- Q22) Which film has the shortest length? In which language and year was it released?

SELECT
film_id AS ID,
title AS Film_Title, release_year AS Release_Year,
`language`.`name` AS `Language`,
length AS Film_length
FROM 
film
INNER JOIN `language` ON `language`.language_id = film.language_id
where length = (SELECT MIN(length) FROM film);

-- Q23) How many movies were released each year?

SELECT
release_year AS ReleasdYear,
COUNT(film_id) AS Total_films
FROM film
GROUP BY release_year
ORDER BY release_year;

-- Q24) How many languages of movies were released each year?.

SELECT
release_year AS ReleasdYear,
COUNT(DISTINCT(film.language_id)) AS language_Type
FROM 
film
INNER JOIN `language` ON film.language_id = `language`.language_id
GROUP BY release_year
ORDER BY release_year;

-- Q25) Which actor did least movies?

SELECT
CONCAT (first_name,'  ',last_name) AS `Name`,
COUNT(film_actor.film_id) AS Total_films
FROM 
actor
INNER JOIN film_actor ON film_actor.actor_id = actor.actor_id
GROUP BY CONCAT(first_name,last_name)
ORDER BY Total_films LIMIT 1;





    

