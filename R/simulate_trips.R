

simulate_trips = function(conn,
                          start_points) {

  return(start_points)

  MeanDistanceQuery <- "
CREATE TEMP TABLE MeanDistance AS

-- Selecting all avaiable from trips that don't start and end at same point
WITH ListOfPoints AS (
  SELECT
    t1.PULocationID,
    t1.DOLocationID,
    AVG(t1.trip_miles) AS trip_miles_mean
  FROM
    NycTrips t1
  INNER JOIN
    ValidZoneCodes t2
    ON t1.PULocationID = t2.PULocationID AND
       t1.DOLocationID = t2.DOLocationID
  WHERE
    t1.PULocationID <> t1.DOLocationID AND
    t1.year = 2023
  GROUP BY
    t1.PULocationID,
    t1.DOLocationID
  HAVING
    AVG(t1.trip_miles) <= 7
),

-- Defining all available distances
ListOfPointsComplete AS (
  SELECT
    PULocationID,
    DOLocationID,
    trip_miles_mean
  FROM ListOfPoints
  UNION ALL
  SELECT
    DOLocationID AS PULocationID,
    PULocationID AS DOLocationID,
    trip_miles_mean
  FROM ListOfPoints
),
NumeredRows AS (
  SELECT
    PULocationID,
    DOLocationID,
    trip_miles_mean,
    row_number() OVER (PARTITION BY PULocationID, DOLocationID) AS n_row
  FROM ListOfPointsComplete
)

-- Selecting the first combination of distances
SELECT
  PULocationID,
  DOLocationID,
  trip_miles_mean
FROM NumeredRows
WHERE n_row = 1
ORDER BY PULocationID, trip_miles_mean;
"

dbExecute(conn, MeanDistanceQuery)


}
