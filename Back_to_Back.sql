-- Created by Scott Fields on 1/21/2019

-- Create table for all base stats for each player and each game
CREATE TABLE all_stats
(
game_id NUMBER PRIMARY KEY,
game_date DATE NOT NULL,
team VARCHAR2(5) NOT NULL,
game_loc VARCHAR2(5) NOT NULL,
days_off NUMBER NOT NULL,
player_name VARCHAR2(40) NOT NULL,
player_role VARCHAR2(8) NOT NULL,
min_played NUMBER NOT NULL,
pos VARCHAR2(3) NOT NULL,
points NUMBER NOT NULL,
assists NUMBER NOT NULL,
turnovers NUMBER NOT NULL,
steals NUMBER NOT NULL,
blks NUMBER NOT NULL,
fouls NUMBER NOT NULL,
fga NUMBER NOT NULL,
fgm NUMBER NOT NULL,
two_att NUMBER NOT NULL,
two_made NUMBER NOT NULL,
three_att NUMBER NOT NULL,
three_made NUMBER NOT NULL,
fta NUMBER NOT NULL,
ftm NUMBER NOT NULL,
orb NUMBER NOT NULL,
drb NUMBER NOT NULL,
oppt VARCHAR2(5) NOT NULL,
oppt_days_off NUMBER NOT NULL
);

--Set minutes played equal to 1 where it was zero for calculations of per36 stats
UPDATE all_stats
SET min_played = 1
WHERE min_played = 0;

-- Create table of pairs of back to back games 
CREATE TABLE game_pairs
(
game_1 NUMBER REFERENCES all_stats(game_id),
game_2 NUMBER REFERENCES all_stats(game_id),
PRIMARY KEY (game_1, game_2)
);
/
-- insert games of back to backs into game_pairs
DECLARE
    stats_row all_stats%ROWTYPE;
    first_date DATE;
    first_game NUMBER;
    missing_games NUMBER := 1;
    
    CURSOR stats_cursor IS
        SELECT game_id, game_date, player_name, days_off
        FROM all_stats;

BEGIN 
    FOR stats_row IN stats_cursor LOOP
        BEGIN
            -- finds 2nd game of back to back
            IF stats_row.days_off = 1 THEN
                -- finds date of 1st game
                first_date := stats_row.game_date - 1;
                -- finds game_id of first game with same player
                SELECT game_id
                INTO first_game
                FROM all_stats
                WHERE player_name = stats_row.player_name AND
                    game_date = first_date
                FETCH FIRST 1 ROWS ONLY;
                 
                INSERT INTO game_pairs
                VALUES(
                    first_game,
                    stats_row.game_id
                    );                
            END IF;
        EXCEPTION WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE(missing_games);
                -- counts games where player didn't play in the first night of a team back to back
                missing_games := missing_games + 1;
        END;
    END LOOP;
END;
/
        
-- create table to look at points per 36 compared to average and total minutes played over a back to back        
CREATE TABLE points_eff
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_points_per36 NUMBER NOT NULL,
points_per36 NUMBER NOT NULL,
change_in_pp36 NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into points_eff table
DECLARE
    avg_pp36 NUMBER;
    pp36 NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        -- finds players name for loop iteration
        SELECT player_name
            INTO p_name
        FROM all_stats
        WHERE game_id = pair.game_2;
        
        -- finds points per 36 minutes played for all games that aren't 2nd game of back to back
        SELECT
            (SELECT SUM(points)
            FROM all_stats
            WHERE days_off != 1 AND
             player_name = p_name) / 
            (SELECT SUM(min_played)
            FROM all_stats
            WHERE days_off != 1 AND
            player_name = p_name) * 36
        INTO avg_pp36
        FROM dual;
        
        -- finds points per 36 for specific 2nd game of back to back
        SELECT 
            (SELECT points
             FROM all_stats
             WHERE game_id = pair.game_2) /
            (SELECT min_played 
             FROM all_stats
             WHERE game_id = pair.game_2) * 36
        INTO pp36
        FROM dual;
        
        -- -finds combined minutes of the game pair
        SELECT 
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_1) +
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_2)
        INTO comb_min
        FROM dual;
        
        -- eliminates games with less than 40 minutes and inserts into new table
        IF comb_min > 39.5 THEN
            INSERT INTO points_eff
            VALUES(
                pair.game_2,
                (SELECT game_date
                 FROM all_stats
                 WHERE game_id = pair.game_2),
                p_name,
                avg_pp36,
                pp36,
                pp36 - avg_pp36,
                comb_min);
        END IF;
    END LOOP;
END;
/

-- create table for assists efficiency stats
CREATE TABLE assists_eff
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_assists_per36 NUMBER NOT NULL,
assists_per36 NUMBER NOT NULL,
change_in_ap36 NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into assists_eff table
DECLARE
    avg_ap36 NUMBER;
    ap36 NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT player_name
            INTO p_name
        FROM all_stats
        WHERE game_id = pair.game_2;
        
        SELECT
            (SELECT SUM(assists)
            FROM all_stats
            WHERE days_off != 1 AND
             player_name = p_name) / 
            (SELECT SUM(min_played)
            FROM all_stats
            WHERE days_off != 1 AND
            player_name = p_name) * 36
        INTO avg_ap36
        FROM dual;
        
        SELECT 
            (SELECT assists
             FROM all_stats
             WHERE game_id = pair.game_2) /
            (SELECT min_played 
             FROM all_stats
             WHERE game_id = pair.game_2) * 36
        INTO ap36
        FROM dual;
        
        SELECT 
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_1) +
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_2)
        INTO comb_min
        FROM dual;
        
        IF comb_min > 39.5 THEN
            INSERT INTO assists_eff
            VALUES(
                pair.game_2,
                (SELECT game_date
                 FROM all_stats
                 WHERE game_id = pair.game_2),
                p_name,
                avg_ap36,
                ap36,
                ap36 - avg_ap36,
                comb_min);
        END IF;
    END LOOP;
END;
/

-- cretae table for turnovers efficiency
CREATE TABLE turnovers_eff
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_turnovers_per36 NUMBER NOT NULL,
turnovers_per36 NUMBER NOT NULL,
change_in_tp36 NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into turnovers_eff table
DECLARE
    avg_tp36 NUMBER;
    tp36 NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT player_name
            INTO p_name
        FROM all_stats
        WHERE game_id = pair.game_2;
        
        SELECT
            (SELECT SUM(turnovers)
            FROM all_stats
            WHERE days_off != 1 AND
             player_name = p_name) / 
            (SELECT SUM(min_played)
            FROM all_stats
            WHERE days_off != 1 AND
            player_name = p_name) * 36
        INTO avg_tp36
        FROM dual;
        
        SELECT 
            (SELECT turnovers
             FROM all_stats
             WHERE game_id = pair.game_2) /
            (SELECT min_played 
             FROM all_stats
             WHERE game_id = pair.game_2) * 36
        INTO tp36
        FROM dual;
        
        SELECT 
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_1) +
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_2)
        INTO comb_min
        FROM dual;
        
        IF comb_min > 39.5 THEN
            INSERT INTO turnovers_eff
            VALUES(
                pair.game_2,
                (SELECT game_date
                 FROM all_stats
                 WHERE game_id = pair.game_2),
                p_name,
                avg_tp36,
                tp36,
                tp36 - avg_tp36,
                comb_min);
        END IF;
    END LOOP;
END;
/

-- Create table for steals efficiency
CREATE TABLE steals_eff
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_steals_per36 NUMBER NOT NULL,
steals_per36 NUMBER NOT NULL,
change_in_sp36 NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data steals_eff table
DECLARE
    avg_sp36 NUMBER;
    sp36 NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT player_name
            INTO p_name
        FROM all_stats
        WHERE game_id = pair.game_2;
        
        SELECT
            (SELECT SUM(steals)
            FROM all_stats
            WHERE days_off != 1 AND
             player_name = p_name) / 
            (SELECT SUM(min_played)
            FROM all_stats
            WHERE days_off != 1 AND
            player_name = p_name) * 36
        INTO avg_sp36
        FROM dual;
        
        SELECT 
            (SELECT steals
             FROM all_stats
             WHERE game_id = pair.game_2) /
            (SELECT min_played 
             FROM all_stats
             WHERE game_id = pair.game_2) * 36
        INTO sp36
        FROM dual;
        
        SELECT 
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_1) +
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_2)
        INTO comb_min
        FROM dual;
        
        IF comb_min > 39.5 THEN
            INSERT INTO steals_eff
            VALUES(
                pair.game_2,
                (SELECT game_date
                 FROM all_stats
                 WHERE game_id = pair.game_2),
                p_name,
                avg_sp36,
                sp36,
                sp36 - avg_sp36,
                comb_min);
        END IF;
    END LOOP;
END;
/

-- Create table for blocks efficiency
CREATE TABLE blocks_eff
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_blocks_per36 NUMBER NOT NULL,
blocks_per36 NUMBER NOT NULL,
change_in_bp36 NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into blocks_eff table
DECLARE
    avg_bp36 NUMBER;
    bp36 NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT player_name
            INTO p_name
        FROM all_stats
        WHERE game_id = pair.game_2;
        
        SELECT
            (SELECT SUM(blks)
            FROM all_stats
            WHERE days_off != 1 AND
             player_name = p_name) / 
            (SELECT SUM(min_played)
            FROM all_stats
            WHERE days_off != 1 AND
            player_name = p_name) * 36
        INTO avg_bp36
        FROM dual;
        
        SELECT 
            (SELECT blks
             FROM all_stats
             WHERE game_id = pair.game_2) /
            (SELECT min_played 
             FROM all_stats
             WHERE game_id = pair.game_2) * 36
        INTO bp36
        FROM dual;
        
        SELECT 
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_1) +
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_2)
        INTO comb_min
        FROM dual;
        
        IF comb_min > 39.5 THEN
            INSERT INTO blocks_eff
            VALUES(
                pair.game_2,
                (SELECT game_date
                 FROM all_stats
                 WHERE game_id = pair.game_2),
                p_name,
                avg_bp36,
                bp36,
                bp36 - avg_bp36,
                comb_min);
        END IF;
    END LOOP;
END;
/

-- Create table for fouls efficiency
CREATE TABLE fouls_eff
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_fouls_per36 NUMBER NOT NULL,
fouls_per36 NUMBER NOT NULL,
change_in_fp36 NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into fouls_eff table
DECLARE
    avg_fp36 NUMBER;
    fp36 NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT player_name
            INTO p_name
        FROM all_stats
        WHERE game_id = pair.game_2;
        
        SELECT
            (SELECT SUM(fouls)
            FROM all_stats
            WHERE days_off != 1 AND
             player_name = p_name) / 
            (SELECT SUM(min_played)
            FROM all_stats
            WHERE days_off != 1 AND
            player_name = p_name) * 36
        INTO avg_fp36
        FROM dual;
        
        SELECT 
            (SELECT fouls
             FROM all_stats
             WHERE game_id = pair.game_2) /
            (SELECT min_played 
             FROM all_stats
             WHERE game_id = pair.game_2) * 36
        INTO fp36
        FROM dual;
        
        SELECT 
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_1) +
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_2)
        INTO comb_min
        FROM dual;
        
        IF comb_min > 39.5 THEN
            INSERT INTO fouls_eff
            VALUES(
                pair.game_2,
                (SELECT game_date
                 FROM all_stats
                 WHERE game_id = pair.game_2),
                p_name,
                avg_fp36,
                fp36,
                fp36 - avg_fp36,
                comb_min);
        END IF;
    END LOOP;
END;
/

-- Create table for field goal percentage
CREATE TABLE field_goal_percentage
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_fgp NUMBER NOT NULL,
fg_percentage NUMBER NOT NULL,
change_in_fgp NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into field_goal_percentage table
DECLARE
    avg_fgp NUMBER;
    fgp NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
    fg_a NUMBER;
    total_fga NUMBER;
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT fga
        INTO fg_a
        FROM all_stats
        WHERE game_id = pair.game_2;
        
        SELECT SUM(fga)
        INTO total_fga
        FROM all_stats
        WHERE days_off != 1 AND player_name = (SELECT player_name FROM all_stats where game_id = pair.game_2);
        
        IF fg_a > 0 AND total_fga > 0 THEN
            SELECT player_name
                INTO p_name
            FROM all_stats
            WHERE game_id = pair.game_2;
            
            SELECT
                (SELECT SUM(fgm)
                FROM all_stats
                WHERE days_off != 1 AND
                 player_name = p_name) / 
                total_fga * 100
            INTO avg_fgp
            FROM dual;
            
            SELECT 
                (SELECT fgm
                 FROM all_stats
                 WHERE game_id = pair.game_2) /
                 fg_a * 100
            INTO fgp
            FROM dual;
            
            SELECT 
                (SELECT min_played
                 FROM all_stats
                 WHERE game_id = pair.game_1) +
                (SELECT min_played
                 FROM all_stats
                 WHERE game_id = pair.game_2)
            INTO comb_min
            FROM dual;
            
            IF comb_min > 39.5 THEN
                INSERT INTO field_goal_percentage
                VALUES(
                    pair.game_2,
                    (SELECT game_date
                     FROM all_stats
                     WHERE game_id = pair.game_2),
                    p_name,
                    avg_fgp,
                    fgp,
                    fgp - avg_fgp,
                    comb_min);
            END IF;
        END IF;
    END LOOP;
END;
/

-- Create table for 2 pointers attempted efficiency
CREATE TABLE two_att_eff
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_two_att_per36 NUMBER NOT NULL,
two_att_per36 NUMBER NOT NULL,
change_in_tpap36 NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into two_att_eff table
DECLARE
    avg_tpap36 NUMBER;
    tpap36 NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT 
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_1) +
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_2)
        INTO comb_min
        FROM dual;
        
        -- halfway thropugh I realized I should eliminate too small combined minutes first so my program runs faster so that's 
        -- why its in a different order from here down
        IF comb_min > 39.5 THEN
            SELECT player_name
                INTO p_name
            FROM all_stats
            WHERE game_id = pair.game_2;
            
            SELECT
                (SELECT SUM(two_att)
                FROM all_stats
                WHERE days_off != 1 AND
                 player_name = p_name) / 
                (SELECT SUM(min_played)
                FROM all_stats
                WHERE days_off != 1 AND
                player_name = p_name) * 36
            INTO avg_tpap36
            FROM dual;
            
            SELECT 
                (SELECT two_att
                 FROM all_stats
                 WHERE game_id = pair.game_2) /
                (SELECT min_played 
                 FROM all_stats
                 WHERE game_id = pair.game_2) * 36
            INTO tpap36
            FROM dual;
            
            INSERT INTO two_att_eff
            VALUES(
                pair.game_2,
                (SELECT game_date
                 FROM all_stats
                 WHERE game_id = pair.game_2),
                p_name,
                avg_tpap36,
                tpap36,
                tpap36 - avg_tpap36,
                comb_min);
        END IF;
    END LOOP;
END;
/

-- Create table for 3 pointers attempted efficiency
CREATE TABLE three_att_eff
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_three_att_per36 NUMBER NOT NULL,
three_att_per36 NUMBER NOT NULL,
change_in_thpap36 NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into three_att_eff table
DECLARE
    avg_thpap36 NUMBER;
    thpap36 NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT 
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_1) +
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_2)
        INTO comb_min
        FROM dual;
        
        IF comb_min > 39.5 THEN
            SELECT player_name
                INTO p_name
            FROM all_stats
            WHERE game_id = pair.game_2;
            
            SELECT
                (SELECT SUM(three_att)
                FROM all_stats
                WHERE days_off != 1 AND
                 player_name = p_name) / 
                (SELECT SUM(min_played)
                FROM all_stats
                WHERE days_off != 1 AND
                player_name = p_name) * 36
            INTO avg_thpap36
            FROM dual;
            
            SELECT 
                (SELECT three_att
                 FROM all_stats
                 WHERE game_id = pair.game_2) /
                (SELECT min_played 
                 FROM all_stats
                 WHERE game_id = pair.game_2) * 36
            INTO thpap36
            FROM dual;
            
            INSERT INTO three_att_eff
            VALUES(
                pair.game_2,
                (SELECT game_date
                 FROM all_stats
                 WHERE game_id = pair.game_2),
                p_name,
                avg_thpap36,
                thpap36,
                thpap36 - avg_thpap36,
                comb_min);
        END IF;
    END LOOP;
END;
/

-- Create table for free throws attempted efficiency
CREATE TABLE ft_att_eff
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_ft_att_per36 NUMBER NOT NULL,
ft_att_per36 NUMBER NOT NULL,
change_in_ftap36 NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into ft_att_eff table
DECLARE
    avg_ftap36 NUMBER;
    ftap36 NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT 
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_1) +
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_2)
        INTO comb_min
        FROM dual;
        
        IF comb_min > 39.5 THEN
            SELECT player_name
                INTO p_name
            FROM all_stats
            WHERE game_id = pair.game_2;
            
            SELECT
                (SELECT SUM(fta)
                FROM all_stats
                WHERE days_off != 1 AND
                 player_name = p_name) / 
                (SELECT SUM(min_played)
                FROM all_stats
                WHERE days_off != 1 AND
                player_name = p_name) * 36
            INTO avg_ftap36
            FROM dual;
            
            SELECT 
                (SELECT fta
                 FROM all_stats
                 WHERE game_id = pair.game_2) /
                (SELECT min_played 
                 FROM all_stats
                 WHERE game_id = pair.game_2) * 36
            INTO ftap36
            FROM dual;
            
            INSERT INTO ft_att_eff
            VALUES(
                pair.game_2,
                (SELECT game_date
                 FROM all_stats
                 WHERE game_id = pair.game_2),
                p_name,
                avg_ftap36,
                ftap36,
                ftap36 - avg_ftap36,
                comb_min);
        END IF;
    END LOOP;
END;
/

-- Create table for free throw percentage
CREATE TABLE ft_percentage
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_ftp NUMBER NOT NULL,
ft_percentage NUMBER NOT NULL,
change_in_ftp NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into ft_percentage table
DECLARE
    avg_ftp NUMBER;
    ftp NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
    ft_a NUMBER;
    total_fta NUMBER;
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT fta
        INTO ft_a
        FROM all_stats
        WHERE game_id = pair.game_2;
        SELECT SUM(fta)
        INTO total_fta
        FROM all_stats
        WHERE days_off != 1 AND player_name = (SELECT player_name FROM all_stats where game_id = pair.game_2);
        IF ft_a > 0 AND total_fta > 0 THEN
            SELECT player_name
                INTO p_name
            FROM all_stats
            WHERE game_id = pair.game_2;
            
            SELECT
                (SELECT SUM(ftm)
                FROM all_stats
                WHERE days_off != 1 AND
                 player_name = p_name) / 
                total_fta * 100
            INTO avg_ftp
            FROM dual;
            
            SELECT 
                (SELECT ftm
                 FROM all_stats
                 WHERE game_id = pair.game_2) /
                 ft_a * 100
            INTO ftp
            FROM dual;
            
            SELECT 
                (SELECT min_played
                 FROM all_stats
                 WHERE game_id = pair.game_1) +
                (SELECT min_played
                 FROM all_stats
                 WHERE game_id = pair.game_2)
            INTO comb_min
            FROM dual;
            
            IF comb_min > 39.5 THEN
                INSERT INTO ft_percentage
                VALUES(
                    pair.game_2,
                    (SELECT game_date
                     FROM all_stats
                     WHERE game_id = pair.game_2),
                    p_name,
                    avg_ftp,
                    ftp,
                    ftp - avg_ftp,
                    comb_min);
            END IF;
        END IF;
    END LOOP;
END;
/

-- Create table for free throw rate
CREATE TABLE ft_rate
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_ftr NUMBER NOT NULL,
ft_rate NUMBER NOT NULL,
change_in_ftr NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into ft_rate table
DECLARE
    avg_ftr NUMBER;
    ftr NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
    fg_a NUMBER;
    total_fga NUMBER;
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT fga
        INTO fg_a
        FROM all_stats
        WHERE game_id = pair.game_2;
        SELECT SUM(fga)
        INTO total_fga
        FROM all_stats
        WHERE days_off != 1 AND player_name = (SELECT player_name FROM all_stats where game_id = pair.game_2);
        IF fg_a > 0 AND total_fga > 0 THEN
            SELECT player_name
                INTO p_name
            FROM all_stats
            WHERE game_id = pair.game_2;
            
            SELECT
                (SELECT SUM(fta)
                FROM all_stats
                WHERE days_off != 1 AND
                 player_name = p_name) / 
                total_fga * 100
            INTO avg_ftr
            FROM dual;
            
            SELECT 
                (SELECT fta
                 FROM all_stats
                 WHERE game_id = pair.game_2) /
                 fg_a * 100
            INTO ftr
            FROM dual;
            
            SELECT 
                (SELECT min_played
                 FROM all_stats
                 WHERE game_id = pair.game_1) +
                (SELECT min_played
                 FROM all_stats
                 WHERE game_id = pair.game_2)
            INTO comb_min
            FROM dual;
            
            IF comb_min > 39.5 THEN
                INSERT INTO ft_rate
                VALUES(
                    pair.game_2,
                    (SELECT game_date
                     FROM all_stats
                     WHERE game_id = pair.game_2),
                    p_name,
                    avg_ftr,
                    ftr,
                    ftr - avg_ftr,
                    comb_min);
            END IF;
        END IF;
    END LOOP;
END;
/

-- Create table for offensive rebound efficiency
CREATE TABLE orb_eff
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_orb_per36 NUMBER NOT NULL,
orb_per36 NUMBER NOT NULL,
change_in_orbp36 NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into orb_eff table
DECLARE
    avg_orbp36 NUMBER;
    orbp36 NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT 
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_1) +
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_2)
        INTO comb_min
        FROM dual;
        
        IF comb_min > 39.5 THEN
            SELECT player_name
                INTO p_name
            FROM all_stats
            WHERE game_id = pair.game_2;
            
            SELECT
                (SELECT SUM(orb)
                FROM all_stats
                WHERE days_off != 1 AND
                 player_name = p_name) / 
                (SELECT SUM(min_played)
                FROM all_stats
                WHERE days_off != 1 AND
                player_name = p_name) * 36
            INTO avg_orbp36
            FROM dual;
            
            SELECT 
                (SELECT orb
                 FROM all_stats
                 WHERE game_id = pair.game_2) /
                (SELECT min_played 
                 FROM all_stats
                 WHERE game_id = pair.game_2) * 36
            INTO orbp36
            FROM dual;
            
            INSERT INTO orb_eff
            VALUES(
                pair.game_2,
                (SELECT game_date
                 FROM all_stats
                 WHERE game_id = pair.game_2),
                p_name,
                avg_orbp36,
                orbp36,
                orbp36 - avg_orbp36,
                comb_min);
        END IF;
    END LOOP;
END;
/

-- Create table for total rebound efficiency
CREATE TABLE trb_eff
(
second_game NUMBER PRIMARY KEY REFERENCES all_stats(game_id),
game_date DATE NOT NULL,
player_name VARCHAR2(40) NOT NULL,
avg_trb_per36 NUMBER NOT NULL,
trb_per36 NUMBER NOT NULL,
change_in_trbp36 NUMBER NOT NULL,
combined_minutes NUMBER NOT NULL
);
/

-- insert data into trb_eff table
DECLARE
    avg_trbp36 NUMBER;
    trbp36 NUMBER;
    comb_min NUMBER;
    p_name VARCHAR2(40);
BEGIN
    FOR pair IN (SELECT * FROM game_pairs)LOOP
        SELECT 
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_1) +
            (SELECT min_played
             FROM all_stats
             WHERE game_id = pair.game_2)
        INTO comb_min
        FROM dual;
        
        IF comb_min > 39.5 THEN
            SELECT player_name
                INTO p_name
            FROM all_stats
            WHERE game_id = pair.game_2;
            
            SELECT
                ((SELECT SUM(orb)
                FROM all_stats
                WHERE days_off != 1 AND
                 player_name = p_name) + 
                 (SELECT SUM(drb)
                 FROM all_stats
                 WHERE days_off != 1 AND
                 player_name = p_name)) / 
                (SELECT SUM(min_played)
                FROM all_stats
                WHERE days_off != 1 AND
                player_name = p_name) * 36
            INTO avg_trbp36
            FROM dual;
            
            SELECT 
                ((SELECT orb
                 FROM all_stats
                 WHERE game_id = pair.game_2) + 
                 (SELECT drb
                  FROM all_stats
                  WHERE game_id = pair.game_2)) /
                (SELECT min_played 
                 FROM all_stats
                 WHERE game_id = pair.game_2) * 36
            INTO trbp36
            FROM dual;
            
            INSERT INTO trb_eff
            VALUES(
                pair.game_2,
                (SELECT game_date
                 FROM all_stats
                 WHERE game_id = pair.game_2),
                p_name,
                avg_trbp36,
                trbp36,
                trbp36 - avg_trbp36,
                comb_min);
        END IF;
    END LOOP;
END;
/

-- Comparing minutes played in game 2 of back to backs to average to see if more rest was given to starters
SELECT
(SELECT AVG(min_played)
FROM all_stats
WHERE player_role = 'Starter' AND days_off = 1) AS "Average Stater Minutes on Day 2",
(SELECT AVG(min_played)
FROM all_stats
WHERE player_role = 'Starter' AND days_off != 1) AS "Average Starter Minutes on All Other Days"
FROM dual;

-- Ranking players in points per 36 change
CREATE TABLE points_rank AS
    SELECT count(*) AS num_pairs, player_name, AVG(change_in_pp36) AS average_change, 1 AS rank
    FROM points_eff
    GROUP BY player_name
    HAVING count(*) > 40
    ORDER BY 3 DESC;

UPDATE points_rank SET rank = ROWNUM;

-- Ranking players in assists per 36 change
CREATE TABLE assists_rank AS
    SELECT count(*) AS num_pairs, player_name, AVG(change_in_ap36) AS average_change, 1 AS rank
    FROM assists_eff
    GROUP BY player_name
    HAVING count(*) > 40
    ORDER BY 3 DESC;

UPDATE assists_rank SET rank = ROWNUM;

-- Ranking players in turnovers per 36 change
CREATE TABLE turnovers_rank AS
    SELECT count(*) AS num_pairs, player_name, AVG(change_in_tp36) AS average_change, 1 AS rank
    FROM turnovers_eff
    GROUP BY player_name
    HAVING count(*) > 40
    ORDER BY 3;
    

UPDATE turnovers_rank SET rank = ROWNUM;

-- Ranking players in steals per 36 change
CREATE TABLE steals_rank AS
    SELECT count(*) AS num_pairs, player_name, AVG(change_in_sp36) AS average_change, 1 AS rank
    FROM steals_eff
    GROUP BY player_name
    HAVING count(*) > 40
    ORDER BY 3 DESC;

UPDATE steals_rank SET rank = ROWNUM;

-- Ranking players in blocks per 36 change
CREATE TABLE blocks_rank AS
    SELECT count(*) AS num_pairs, player_name, AVG(change_in_bp36) AS average_change, 1 AS rank
    FROM blocks_eff
    GROUP BY player_name
    HAVING count(*) > 40
    ORDER BY 3 DESC;

UPDATE blocks_rank SET rank = ROWNUM;

-- Ranking players in fouls per 36 change
CREATE TABLE fouls_rank AS
    SELECT count(*) AS num_pairs, player_name, AVG(change_in_fp36) AS average_change, 1 AS rank
    FROM fouls_eff
    GROUP BY player_name
    HAVING count(*) > 40
    ORDER BY 3;

UPDATE fouls_rank SET rank = ROWNUM;

-- Ranking players in field goal percentage change
CREATE TABLE fgp_rank AS
    SELECT count(*) AS num_pairs, player_name, AVG(change_in_fgp) AS average_change, 1 AS rank
    FROM field_goal_percentage
    WHERE player_name IN (SELECT player_name FROM points_eff GROUP BY player_name HAVING count(*) > 40)
    GROUP BY player_name
    ORDER BY 3 DESC;

UPDATE fgp_rank SET rank = ROWNUM;

-- Ranking players in 2 pointers attempted per 36 change
SELECT count(*), player_name, AVG(change_in_tpap36)
FROM two_att_eff
GROUP BY player_name
HAVING count(*) > 40
ORDER BY 3 DESC;

-- Ranking players in 3 pointers attmpted per 36 change
SELECT count(*), player_name, AVG(change_in_thpap36)
FROM three_att_eff
GROUP BY player_name
HAVING count(*) > 40
ORDER BY 3 DESC;

-- Ranking players in free throws attempted per 36 change
SELECT count(*), player_name, AVG(change_in_ftap36)
FROM ft_att_eff
GROUP BY player_name
HAVING count(*) > 40
ORDER BY 3 DESC;

-- Ranking players in free throw percentage change
CREATE TABLE ftp_rank AS
    SELECT count(*) AS num_pairs, player_name, AVG(change_in_ftp) AS average_change, 1 AS rank
    FROM ft_percentage
    WHERE player_name IN (SELECT player_name FROM points_eff GROUP BY player_name HAVING count(*) > 40)
    GROUP BY player_name
    ORDER BY 1 DESC;

UPDATE ftp_rank SET rank = ROWNUM;

-- Ranking players in free throw rate change
SELECT count(*), player_name, AVG(change_in_ftr)
FROM ft_rate
WHERE player_name IN (SELECT player_name FROM points_eff GROUP BY player_name HAVING count(*) > 40)
GROUP BY player_name
ORDER BY 3 DESC;

-- Ranking players in offensive rebounds per 36 change
CREATE TABLE orb_rank AS
    SELECT count(*) AS num_pairs, player_name, AVG(change_in_orbp36) AS average_change, 1 AS rank
    FROM orb_eff
    GROUP BY player_name
    HAVING count(*) > 40
    ORDER BY 3 DESC;

UPDATE orb_rank SET rank = ROWNUM;

-- Ranking players in total rebounds per 36 change
CREATE TABLE trb_rank AS
    SELECT count(*) AS num_pairs, player_name, AVG(change_in_trbp36) AS average_change, 1 AS rank
    FROM trb_eff
    GROUP BY player_name
    HAVING count(*) > 40
    ORDER BY 3 DESC;

UPDATE trb_rank SET rank = ROWNUM;

CREATE TABLE average_rank
(
player_name VARCHAR2(40) PRIMARY KEY,
average_rank NUMBER NOT NULL
);

-- Finding average rank for positive categories (not Free Throw Rate or FT/ 2P/ 3P Attempted)
DECLARE 
    avg_rank NUMBER;
BEGIN
    FOR rowline IN (SELECT * FROM points_rank) LOOP
        SELECT
        (rowline.rank +
        (SELECT rank
        FROM assists_rank
        WHERE player_name = rowline.player_name) +
        (SELECT rank
        FROM turnovers_rank
        WHERE player_name = rowline.player_name) +
        (SELECT rank
        FROM steals_rank
        WHERE player_name = rowline.player_name) +
        (SELECT rank
        FROM blocks_rank
        WHERE player_name = rowline.player_name) +
        (SELECT rank
        FROM fouls_rank
        WHERE player_name = rowline.player_name) +
        (SELECT rank
        FROM fgp_rank
        WHERE player_name = rowline.player_name) +
        (SELECT rank
        FROM ftp_rank
        WHERE player_name = rowline.player_name) +
        (SELECT rank
        FROM orb_rank
        WHERE player_name = rowline.player_name) +
        (SELECT rank
        FROM trb_rank
        WHERE player_name = rowline.player_name))/10
        INTO avg_rank
        FROM dual;
        
        INSERT INTO average_rank
        VALUES (rowline.player_name, avg_rank);
    END LOOP;
END;
/

-- viewing overall ranks with number of game pairs
SELECT player_name, average_rank, num_pairs
FROM average_rank JOIN points_rank USING(player_name)
ORDER BY average_rank;