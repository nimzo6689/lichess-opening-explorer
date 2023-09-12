PRAGMA foreign_keys=true;

CREATE TABLE eco (
  eco TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  pgn TEXT NOT NULL
);

CREATE TABLE events (
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

CREATE UNIQUE INDEX events_uk_ratings_speeds ON events (ratings, speeds);

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

CREATE TABLE moves_analysis (
  ratings TEXT NOT NULL CHECK(
    ratings IN ('0', '1000', '1200', '1400', '1600', '1800', '2000', '2200', '2500')
  ),
  speeds TEXT NOT NULL CHECK(
    speeds IN ('ultraBullet', 'bullet', 'blitz', 'rapid', 'classical', 'correspondence')
  ),
  pgn TEXT NOT NULL,
  white_win REAL NOT NULL,
  white_freq REAL NOT NULL,
  black_win REAL NOT NULL,
  black_freq REAL NOT NULL
);

CREATE VIEW eco_analysis AS
WITH
  moves_with_eco(ratings, speeds, name, accuracy, pgn, white_win, white_freq, black_win, black_freq) AS (
    SELECT ratings, speeds, eco.name, LENGTH(eco.pgn), ma.pgn, white_win, white_freq, black_win, black_freq
      FROM moves_analysis ma
      JOIN eco
        ON ma.pgn LIKE eco.pgn || '%'
  )
SELECT t1.ratings, t1.speeds, t1.pgn, t1.name, t1.white_win, t1.white_freq, t1.black_win, t1.black_freq
  FROM moves_with_eco t1
 WHERE t1.accuracy = (
   SELECT MAX(t2.accuracy)
     FROM moves_with_eco t2
    WHERE t1.pgn = t2.pgn
 )
;
