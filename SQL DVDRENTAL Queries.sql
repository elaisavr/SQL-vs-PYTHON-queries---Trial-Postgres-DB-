--- CREATE FIRST TABLE CONTAINING ACTORS FULL NAME AND FILM CATEGORY TO JOIN WITH FILM FACT TABLE

CREATE TABLE film_details AS SELECT * FROM
        (SELECT a.actor_id, CONCAT(a.first_name,' ',a.last_name) AS actor_name, 
                b.film_id AS table1_film_id
        FROM actor AS a 
        RIGHT JOIN film_actor AS b 
        ON a.actor_id = b.actor_id) AS table1
    LEFT JOIN 
        (SELECT c.category_id, c.name, d.film_id
        FROM category AS c 
        LEFT JOIN film_category AS d
        ON c.category_id = d.category_id) AS table2
    ON table1.table1_film_id = table2.film_id;


--- DROP DUPLICATED COLUMN

ALTER TABLE film_details
DROP COLUMN table1_film_id;

ALTER VIEW VW_film_details
DROP COLUMN table1_film_id;


--- CREATE 2ND TABLE WITH RENTAL ORDERS DETAILS TO JOIN WITH FACT TABLES

CREATE TABLE order_details AS SELECT * FROM 
(SELECT * FROM rental
LEFT JOIN (SELECT inventory_id AS inventory_pk, film_id, store_id FROM inventory) AS table1
ON rental.inventory_id = table1.inventory_pk) AS table2
LEFT JOIN (SELECT customer_id AS payment_customer, amount FROM payment) AS table3
ON table2.customer_id = table3.payment_customer
LEFT JOIN (SELECT store_id AS store_pk, manager_staff_id, address_id AS store_address_id FROM store) AS table4
ON table2.store_id = table4.store_pk;


--- DROP IRRELEVANT/DUPLICATED COLUMNS

ALTER TABLE order_details
DROP COLUMN  inventory_id,
DROP COLUMN last_update,
DROP COLUMN inventory_pk,
DROP COLUMN payment_customer,
DROP COLUMN store_pk;

SELECT * FROM order_details



--- CREATE 3RD TABLE WITH GEOGRAPHICAL DETAILS TO JOIN WITH FACT TABLES
CREATE VIEW VW_geo_details AS SELECT * FROM
    (SELECT * FROM address AS table1
    JOIN 
    (SELECT city_id AS table2_city_id, city, 
            country_id AS table2_country_id FROM city) AS table2
    ON table1.city_id = table2.table2_city_id) AS table3
JOIN 
    (SELECT country_id, country FROM country) AS table4
ON table4.country_id = table3.table2_country_id;

SELECT * FROM geo_details

CREATE TABLE business_details AS
SELECT * FROM 
    (SELECT a.customer_id, CONCAT(a.first_name,' ',a.last_name) AS customer_name, 
            a.address_id AS customer_address_id, 
            b.address_id AS store_address_id
    FROM customer AS a
    INNER JOIN 
    (SELECT DISTINCT store_id, address_id FROM store) AS b
    ON a.store_id = b.store_id) AS c
INNER JOIN 
    (SELECT DISTINCT address_id AS geo_customer_address_id, city AS geo_customer_city, 
                     country AS geo_customer_country FROM VW_geo_details) AS d
ON c.customer_address_id = d.geo_customer_address_id
INNER JOIN 
    (SELECT DISTINCT address_id AS geo_store_address_id, city AS geo_store_city, 
                     country AS geo_store_country FROM VW_geo_details) AS e
ON c.store_address_id = e.geo_store_address_id

SELECT * FROM business_details LIMIT 3;

ALTER TABLE business_details
DROP COLUMN geo_customer_address_id,
DROP COLUMN store_address_id;

ALTER TABLE business_details
RENAME COLUMN geo_store_address_id TO store_address_id;

ALTER TABLE business_details
RENAME COLUMN geo_customer_city TO customer_city;

ALTER TABLE business_details
RENAME COLUMN geo_customer_country TO customer_country;

ALTER TABLE business_details
RENAME COLUMN geo_store_city TO store_city;

ALTER TABLE business_details
RENAME COLUMN geo_store_country TO store_country;



---1) WHICH IS THE MOVIE HAVING LONGEST DURATION AND WHICH ARE THE ACTORS?

SELECT a.title, b.actor_name, a.length 
FROM film AS a
LEFT JOIN film_details AS b
ON a.film_id = b.film_id
GROUP BY  a.title, b.actor_name, a.length
ORDER BY  a.length DESC;



---2) WHICH IS THE AVERAGE MOVIE DURATION FOR EACH CATEGORY?

SELECT b.name AS category_name, ROUND(AVG(a.length),2) AS avg_duration,
FROM film AS a
JOIN film_details AS b
ON a.film_id = b.film_id
GROUP BY category_name
ORDER BY category_name;



---3) WHICH ARE THE TEN MAIN ACTORS?

SELECT b.actor_name, COUNT(DISTINCT a.film_id) AS nr_movies
FROM film AS a
JOIN film_details AS b
ON a.film_id = b.film_id
GROUP BY b.actor_name
ORDER BY nr_movies DESC
LIMIT 10;



---4) HOW MANY MOVIES FOR EACH ACTOR ON THE BASIS OF FILM RATING?

SELECT DISTINCT rating FROM film;

SELECT 
        CAST ((CASE WHEN rating = 'PG' THEN 'Parental guidance suggested for children'
        WHEN rating = 'R' THEN 'Under 17 with parental required'
        WHEN rating = 'NC-17' THEN 'No children under 17 admitted'
        WHEN rating = 'PG-13' THEN 'Parents strongly cautioned for children under 13'
        WHEN rating = 'G' THEN 'General audiences – All ages admitted'
        END) AS VARCHAR(255)) AS rating_description,
        b.actor_name, COUNT(DISTINCT a.film_id) AS nr_movies
FROM film AS a
JOIN film_details AS b
ON a.film_id = b.film_id
GROUP BY rating_description, b.actor_name
ORDER BY nr_movies DESC;



---5) WHICH IS THE AVERAGE RENTAL RATE FOR EACH FILM RATING? AND THE AVERAGE RENTAL DURATION?

SELECT 
    CAST ((CASE WHEN rating = 'PG' THEN 'Parental guidance suggested for children'
    WHEN rating = 'R' THEN 'Under 17 with parental required'
    WHEN rating = 'NC-17' THEN 'No children under 17 admitted'
    WHEN rating = 'PG-13' THEN 'Parents strongly cautioned for children under 13'
    WHEN rating = 'G' THEN 'General audiences – All ages admitted'
    END) AS VARCHAR(255)) AS rating_description, 
    ROUND(AVG(rental_rate),2) AS avg_rental_rate,
    ROUND(AVG(rental_duration),2) AS avg_rental_time
FROM film
GROUP BY rating_description
ORDER BY avg_rental_rate DESC, avg_rental_time DESC;



---6) HOW MANY MOVIES FOR EACH CATEGORY WERE RELEASED IN 2006?

SELECT a.release_year, b.name, COUNT(DISTINCT a.film_id) AS nr_movies
FROM film AS a
JOIN film_details AS b
ON a.film_id = b.film_id
GROUP BY a.release_year, b.name
HAVING a.release_year = 2006
ORDER BY nr_movies DESC, b.name;



---7) IN HOW MANY LANGUAGES EACH MOVIE HAS BEEN TRANSLATED?

SELECT title, COUNT(DISTINCT language_id) AS nr_translation
FROM film 
GROUP BY title



---8) WHICH ARE THE LANGUAGES OF THE TRANSLATIONS?

SELECT b.name AS translation,  COUNT(DISTINCT a.title) AS nr_movies
FROM film AS a
LEFT JOIN language AS b
ON a.language_id = b.language_id
GROUP BY translation;


------------------------------------------------------------------------------------------


---9) WHICH IS THE MOST RENTED MOVIE AND TO WHICH CATEGORY DOES IT BELONG?

SELECT a.title, b.name, COUNT(c.rental_id) AS nr_rents
FROM 
    (SELECT film_id AS a_film_id, title FROM film) AS a
LEFT JOIN 
    (SELECT film_id AS b_film_id, name FROM film_details) AS b
ON a.a_film_id = b.b_film_id
JOIN order_details AS c
ON b.b_film_id = c.film_id
GROUP BY b.name, a.title
ORDER BY nr_rents DESC;



---10) WHICH ARE THE MOST RENTED MOVIE CONSIDERING THE MOVIE RATING?

SELECT  
    CAST ((CASE WHEN a.rating = 'PG' THEN 'Parental guidance suggested for children'
    WHEN a.rating = 'R' THEN 'Under 17 with parental required'
    WHEN a.rating = 'NC-17' THEN 'No children under 17 admitted'
    WHEN a.rating = 'PG-13' THEN 'Parents strongly cautioned for children under 13'
    WHEN a.rating = 'G' THEN 'General audiences – All ages admitted'
    END) AS VARCHAR(255)) AS rating_description, COUNT( DISTINCT b.rental_id) AS nr_rents,
    a.title
FROM 
    (SELECT film_id AS a_film_id, title, rating FROM film) AS a
JOIN order_details AS b
ON a.a_film_id = b.film_id
GROUP BY a.title, rating_description
ORDER BY nr_rents DESC;



---11) IN GENERAL WHICH MOVIE RATING IS THE MOST POPULAR?

SELECT
    CAST ((CASE WHEN a.rating = 'PG' THEN 'Parental guidance suggested for children'
    WHEN a.rating = 'R' THEN 'Under 17 with parental required'
    WHEN a.rating = 'NC-17' THEN 'No children under 17 admitted'
    WHEN a.rating = 'PG-13' THEN 'Parents strongly cautioned for children under 13'
    WHEN a.rating = 'G' THEN 'General audiences – All ages admitted'
    END) AS VARCHAR(255)) AS rating_description, COUNT(DISTINCT b.rental_id) AS nr_rents
FROM 
    (SELECT film_id AS a_film_id, rating FROM film) AS a
JOIN order_details AS b
ON a.a_film_id = b.film_id
GROUP BY rating_description
ORDER BY nr_rents DESC;



---12) WHICH ARE THE CUSTOMERS WHO USE TO RENT MORE?

SELECT CONCAT(a.first_name,' ',a.last_name) AS customer_name, 
       COUNT(DISTINCT b.rental_id) AS nr_rents
FROM customer AS a
LEFT JOIN order_details AS b
ON a.customer_id = b.customer_id
GROUP BY customer_name
ORDER BY nr_rents DESC;



---13) ARE THE SAME WHO PAY MORE?

SELECT CONCAT(a.first_name,' ',a.last_name) AS customer_name, 
       COUNT(DISTINCT b.rental_id) AS nr_rents,
       SUM(b.amount) AS tot_amount 
FROM customer AS a
LEFT JOIN order_details AS b
ON a.customer_id = b.customer_id
GROUP BY customer_name
ORDER BY tot_amount DESC, nr_rents DESC;



---14) WHICH IS THE AVG TIME PERIOD BETWEEN THE MOST RECENT RENT AND THE LAST?

WITH avg_rental_orders AS 
    (SELECT DATE(rental_date) AS rent_date,
            LAG(DATE(rental_date)) OVER (PARTITION BY customer_id ORDER BY DATE(rental_date)) AS lag_rent_date,
            DATE(rental_date) - LAG(DATE(rental_date)) OVER (PARTITION BY customer_id ORDER BY DATE(rental_date)) AS day_diff   
    FROM order_details)
SELECT ROUND(AVG(day_diff),2) AS avg_days_orders
FROM avg_rental_orders;



---15) WHICH STORE IS THE BUSIEST?

SELECT store_city, store_country, COUNT(DISTINCT customer_id) AS nr_customers
FROM business_details
GROUP BY store_country, store_city
ORDER BY nr_customers DESC;



---16) WHERE DO MOST CUSTOMERS COME FROM?

SELECT customer_country, COUNT(DISTINCT customer_id) AS nr_customers
FROM business_details
GROUP BY customer_country
ORDER BY nr_customers DESC, customer_country;



---17) OF WHICH NATIONALITY ARE THE CUSTOMERS WHO PAY MORE ON AVERAGE?

SELECT DISTINCT a.customer_country, ROUND(AVG(b.amount),2) AS avg_expense
FROM business_details AS a
LEFT JOIN order_details AS b
ON a.customer_id = b.customer_id
GROUP BY a.customer_country 
ORDER BY avg_expense DESC; 



---18) HOW MUCH IS THE TOTAL REVENUE FOR EACH STORE?

SELECT a.store_city, a.store_country, SUM(b.amount) AS total_revenues
FROM business_details AS a
LEFT JOIN order_details AS b
ON a.customer_id = b.customer_id
GROUP BY a.store_address_id, a.store_city, a.store_country
ORDER BY total_revenues DESC;



---19) HOW MANY DVD RENTS FOR EACH STORE?

SELECT a.store_city, a.store_country, 
       COUNT(DISTINCT b.rental_id) AS nr_rents
FROM business_details AS a
LEFT JOIN order_details AS b
ON a.customer_id = b.customer_id
GROUP BY a.store_address_id, a.store_city, a.store_country
ORDER BY nr_rents DESC;

------------------------------------------------------------------------------------------

---20) WHO IS THE MANAGER OF EACH STORE?

SELECT a.staff_id, CONCAT(a.first_name,' ',a.last_name) AS mngr_name, 
       a.store_id, c.store_city, c.store_country
FROM staff AS a
INNER JOIN 
    (SELECT DISTINCT manager_staff_id AS mngr_id FROM store) AS b
ON a.staff_id = b.mngr_id
LEFT JOIN 
    (SELECT store_address_id, store_city, store_country FROM business_details) AS c
ON a.store_id = c.store_address_id
GROUP BY a.staff_id, mngr_name, store_address_id, store_city, store_country, a.store_id



---21) WHERE DO THEY COME FROM?

SELECT a.staff_id, CONCAT(a.first_name,' ',a.last_name) AS mngr_name, 
       b.address, b.district, b.city, b.country
FROM staff AS a
LEFT JOIN VW_geo_details AS b
ON a.address_id = b.address_id



---22) WHO ARE THE EMPLOYEES OF EACH STORE EXCEPT FOR THE MANAGERS? 

SELECT a.staff_id, CONCAT(a.first_name,' ',a.last_name) AS employee_name, 
       a.store_id, b.store_city, b.store_country
FROM staff AS a
LEFT JOIN 
    (SELECT store_address_id, store_city, store_country FROM business_details) AS b
ON a.store_id = b.store_address_id
WHERE a.staff_id <> 1 AND a.staff_id <> 2;