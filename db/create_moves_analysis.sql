CREATE TEMPORARY TABLE __parameters (
  key TEXT PRIMARY KEY CHECK (key IN ('ratings', 'speeds')),
  value TEXT NOT NULL
);

CREATE TEMPORARY VIEW __create_moves_analysis AS
WITH RECURSIVE
  analyzed_events(ratings, speeds, game_count) AS (
    SELECT ratings, speeds, game_count
      FROM events
     WHERE ratings = (SELECT value FROM __parameters WHERE key = 'ratings')
       AND speeds = (SELECT value FROM __parameters WHERE key = 'speeds')
  ),
  boards (
    id, game_count, moves, move_count, moved_by,
    white_win_rate, frequency_for_white, black_win_rate, frequency_for_black
  ) AS (
    SELECT o1.id, o1.game_count, '1. ' || o1.moves, 1, 0,
           CAST(o1.white_wins AS REAL) / o1.game_count, 1,
           CAST(o1.black_wins AS REAL) / o1.game_count,
           CAST(o1.game_count AS REAL) / (SELECT game_count FROM analyzed_events)
      FROM openings o1 JOIN analyzed_events USING (ratings, speeds)
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
           CASE
             WHEN (b1.moved_by = 1 AND o2.moves LIKE '%#') THEN 1.0 
             WHEN (b1.moved_by = 0 AND o2.moves LIKE '%#') THEN 0.0 
             ELSE CAST(o2.white_wins AS REAL) / o2.game_count
           END,
           CASE b1.moved_by WHEN 0
             THEN b1.frequency_for_white * (CAST(o2.game_count AS REAL) / b1.game_count)
             ELSE b1.frequency_for_white
           END,
           CASE
             WHEN (b1.moved_by = 1 AND o2.moves LIKE '%#') THEN 0.0 
             WHEN (b1.moved_by = 0 AND o2.moves LIKE '%#') THEN 1.0 
             ELSE CAST(o2.black_wins AS REAL) / o2.game_count
           END,
           CASE b1.moved_by WHEN 0
             THEN b1.frequency_for_black
             ELSE b1.frequency_for_black * (CAST(o2.game_count AS REAL) / b1.game_count)
           END
      FROM openings o2 JOIN analyzed_events USING (ratings, speeds)
      JOIN boards b1
        ON b1.id = o2.previous_opening_id
  )
SELECT (SELECT value FROM __parameters WHERE key = 'ratings') AS ratings,
       (SELECT value FROM __parameters WHERE key = 'speeds') AS speeds,
       b1.moves AS pgn,
       ROUND(b1.white_win_rate * 100, 2) AS white_win,
       ROUND(b1.frequency_for_white * 100, 2) AS white_freq,
       ROUND(b1.black_win_rate * 100, 2) AS black_win,
       ROUND(b1.frequency_for_black * 100, 2) AS black_freq
  FROM boards b1
 WHERE NOT EXISTS (
   SELECT 'X'
     FROM boards b2
    WHERE b2.moves LIKE b1.moves || ' %'
 )
;

-- bullet
REPLACE INTO __parameters VALUES ('ratings', '1200'), ('speeds', 'bullet');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
REPLACE INTO __parameters VALUES ('ratings', '1400'), ('speeds', 'bullet');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
REPLACE INTO __parameters VALUES ('ratings', '1600'), ('speeds', 'bullet');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
REPLACE INTO __parameters VALUES ('ratings', '1800'), ('speeds', 'bullet');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;

-- blitz
REPLACE INTO __parameters VALUES ('ratings', '1200'), ('speeds', 'blitz');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
REPLACE INTO __parameters VALUES ('ratings', '1400'), ('speeds', 'blitz');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
REPLACE INTO __parameters VALUES ('ratings', '1600'), ('speeds', 'blitz');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
REPLACE INTO __parameters VALUES ('ratings', '1800'), ('speeds', 'blitz');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;

-- rapid
REPLACE INTO __parameters VALUES ('ratings', '1200'), ('speeds', 'rapid');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
REPLACE INTO __parameters VALUES ('ratings', '1400'), ('speeds', 'rapid');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
REPLACE INTO __parameters VALUES ('ratings', '1600'), ('speeds', 'rapid');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
REPLACE INTO __parameters VALUES ('ratings', '1800'), ('speeds', 'rapid');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;

-- classical
REPLACE INTO __parameters VALUES ('ratings', '1200'), ('speeds', 'classical');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
REPLACE INTO __parameters VALUES ('ratings', '1400'), ('speeds', 'classical');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
REPLACE INTO __parameters VALUES ('ratings', '1600'), ('speeds', 'classical');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
REPLACE INTO __parameters VALUES ('ratings', '1800'), ('speeds', 'classical');
INSERT INTO moves_analysis SELECT * FROM __create_moves_analysis;
