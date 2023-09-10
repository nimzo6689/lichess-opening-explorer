PRAGMA foreign_keys=true;

CREATE TABLE statistics (
  white_wins INTEGER NOT NULL,
  black_wins INTEGER NOT NULL,
  draws INTEGER NOT NULL,
  game_count INTEGER GENERATED ALWAYS AS (white_wins + black_wins + draws) VIRTUAL,
  ratings TEXT NOT NULL CHECK(
    ratings IN ('0', '1000', '1200', '1400', '1600', '1800', '2000', '2200', '2500')
  ),
  speeds TEXT NOT NULL CHECK(
    speeds IN ('ultraBullet', 'bullet', 'blitz', 'rapid', 'classical', 'correspondence')
  )
);

CREATE UNIQUE INDEX uk_statistics_ratings_speeds ON statistics (ratings, speeds);

CREATE TABLE openings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  moves TEXT NOT NULL,
  white_wins INTEGER NOT NULL,
  black_wins INTEGER NOT NULL,
  draws INTEGER NOT NULL,
  game_count INTEGER GENERATED ALWAYS AS (white_wins + black_wins + draws) VIRTUAL,
  ratings TEXT NOT NULL CHECK(
    ratings IN ('0', '1000', '1200', '1400', '1600', '1800', '2000', '2200', '2500')
  ),
  speeds TEXT NOT NULL CHECK(
    speeds IN ('ultraBullet', 'bullet', 'blitz', 'rapid', 'classical', 'correspondence')
  ),
  previous_opening_id INTEGER,
  FOREIGN KEY (previous_opening_id) REFERENCES openings (id)
);

CREATE VIEW win_rate_and_frequency AS 
WITH RECURSIVE
  boards (
    id, game_count, moves, move_count, moved_by,
    white_win_rate, frequency_for_white,
    black_win_rate, frequency_for_black
  ) AS (
    SELECT o1.id, o1.game_count, '1. ' || o1.moves, 1, 0,
           CAST(o1.white_wins AS REAL) / o1.game_count, 1,
           CAST(o1.black_wins AS REAL) / o1.game_count,
           CAST(o1.game_count AS REAL) / (SELECT s1.game_count FROM statistics s1)
      FROM openings o1
     WHERE previous_opening_id IS NULL
     UNION ALL
    SELECT o2.id,
           o2.game_count,
           b1.moves || ' ' || 
           CASE b1.moved_by WHEN 0
             THEN o2.moves ELSE b1.move_count || '. ' || o2.moves
           END,
           CASE b1.moved_by WHEN 0
             THEN b1.move_count + 1 ELSE b1.move_count
           END,
           CASE b1.moved_by WHEN 0
             THEN 1 ELSE 0
           END,
           CAST(o2.white_wins AS REAL) / o2.game_count,
           CASE b1.moved_by WHEN 0
             THEN b1.frequency_for_white * (CAST(o2.game_count AS REAL) / b1.game_count)
             ELSE b1.frequency_for_white
           END,
           CAST(o2.black_wins AS REAL) / o2.game_count,
           CASE b1.moved_by WHEN 0
             THEN b1.frequency_for_black
             ELSE b1.frequency_for_black * (CAST(o2.game_count AS REAL) / b1.game_count)
           END
      FROM boards b1
      JOIN openings o2
        ON b1.id = o2.previous_opening_id
     WHERE b1.frequency_for_white <= 0.6 OR b1.frequency_for_black <= 0.6
  )
SELECT ROW_NUMBER() OVER (ORDER BY b1.moves) AS row_no,
       b1.moves,
       ROUND(b1.white_win_rate * 100, 2) AS white_win, ROUND(b1.frequency_for_white * 100, 2) AS freq_white,
       ROUND(b1.black_win_rate * 100, 2) AS black_win, ROUND(b1.frequency_for_black * 100, 2) AS freq_black
  FROM boards b1
 WHERE NOT EXISTS (
   SELECT 'X'
     FROM boards b2
    WHERE b2.moves LIKE b1.moves || ' %'
 )
 ORDER BY black_win DESC
 LIMIT 20
;
