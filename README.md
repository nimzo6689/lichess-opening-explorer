```bash
# Download this as tsv file.
# https://github.com/lichess-org/chess-openings
aria2c https://raw.githubusercontent.com/lichess-org/chess-openings/master/a.tsv
aria2c https://raw.githubusercontent.com/lichess-org/chess-openings/master/b.tsv
aria2c https://raw.githubusercontent.com/lichess-org/chess-openings/master/c.tsv
aria2c https://raw.githubusercontent.com/lichess-org/chess-openings/master/d.tsv
aria2c https://raw.githubusercontent.com/lichess-org/chess-openings/master/e.tsv

# Remove 1st line to use .import command in SQLite.
sed -i '1d' a.tsv
sed -i '1d' b.tsv
sed -i '1d' c.tsv
sed -i '1d' d.tsv
sed -i '1d' e.tsv

cat *.tsv > eco.tsv
rm {a,b,c,d,e}.tsv

sqlite3 lichess.db

>.mode tabs
>.import eco.tsv eco
```

```sql
.mode table
.width 40 30

SELECT pgn, name, white_win, white_freq, black_win, black_freq
  FROM eco_analysis
 WHERE ratings = '1400' AND speeds = 'blitz'
 ORDER BY white_win DESC
 LIMIT 20
;
```
