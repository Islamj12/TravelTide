/*
Question #1: 
return users who have booked and completed at least 10 flights, ordered by user_id.
**Expected column names: user_id
*/
SELECT s.user_id
FROM sessions s
WHERE s.flight_booked = true AND s.cancellation = false
GROUP BY s.user_id
HAVING COUNT(s.trip_id) >= 10 
ORDER BY s.user_id
;

/*
Question #2: 
Write a solution to report the trip_id of sessions where: 

session resulted in a booked flight
booking occurred in May, 2022
booking has the maximum flight discount on that respective day.

If in one day there are multiple such transactions, return all of them.
Expected column names: trip_id
*/
WITH max_discounts AS (
SELECT DATE(ses.session_start) AS session_date, MAX(ses.flight_discount_amount) AS max_discount
FROM sessions AS ses
WHERE DATE(ses.session_start) BETWEEN '2022-05-01' AND '2022-05-31' 
  AND ses.flight_booked = TRUE
GROUP BY session_date
)
  
SELECT s.trip_id
FROM sessions AS s
INNER JOIN max_discounts md
ON DATE(s.session_start) = md.session_date  AND s.flight_discount_amount = md.max_discount
WHERE s.flight_booked = TRUE
ORDER BY s.trip_id
;

/*
Question #3: 
Write a solution that will, for each user_id of users with greater than 10 flights, find out the largest window of days 
between the departure time of a flight and the departure time of the next departing flight taken by the user.
Expected column names: user_id, biggest_window
*/

WITH booked_flights AS (
  SELECT s.user_id, s.trip_id, f.departure_time::DATE,
    LEAD(f.departure_time::DATE) OVER (PARTITION BY  s.user_id ORDER BY f.departure_time::DATE) AS subsequent_departure_time
  FROM sessions s 
  INNER JOIN flights f
    ON s.trip_id = f.trip_id
  WHERE s.flight_booked = true
  
)
SELECT user_id, 
  MAX(subsequent_departure_time - departure_time ) AS biggest_window
FROM booked_flights
GROUP BY user_id
HAVING COUNT(trip_id) > 10 -- or user_id also works or *
ORDER BY user_id
;


/*
Question #4: 
Find the user_id's of people whose origin airport is Boston (BOS) and whose first and last flight were to the same destination.
Only include people who have flown out of Boston at least twice.
**Expected column names: user_id
*/
WITH flown_out_boston AS (
SELECT s.user_id, f.destination_airport, f.departure_time
FROM flights f
INNER JOIN sessions s ON f.trip_id = s.trip_id
WHERE f.origin_airport = 'BOS' AND s.cancellation = false
  
),
ranks AS (
  SELECT 
  user_id, destination_airport,
DENSE_RANK() OVER(PARTITION BY user_id ORDER BY departure_time ASC) AS first_flight,
DENSE_RANK() OVER(PARTITION BY user_id ORDER BY departure_time DESC) AS last_flight
  FROM flown_out_boston	
  
)
SELECT user_id
FROM ranks
WHERE first_flight = 1 OR last_flight = 1
GROUP BY user_id
HAVING COUNT(DISTINCT destination_airport) = 1 AND COUNT(user_id) >= 2
;