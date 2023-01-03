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
