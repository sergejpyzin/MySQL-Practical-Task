/*
	Создайте функцию, которая принимает кол-во сек и формат их в кол-во дней, часов, минут и секунд.
	Пример: 123456 ->'1 days 10 hours 17 minutes 36 seconds '
*/

DELIMITER $$ 
CREATE FUNCTION sec_to_date
(
	sec INT UNSIGNED
) 
	RETURNS VARCHAR(500) 
	DETERMINISTIC 
	BEGIN 
		DECLARE days INT;
		DECLARE hours INT;
		DECLARE minutes INT;
		DECLARE seconds INT;
		DECLARE result VARCHAR(500) DEFAULT "";
		-- Присваиваем пременным значения (86400 - кол-во секунд в одном дне, 3600 - кол-во секунд в одном часе, 60 - кол-во секунд в одной минуте)
		SET 
		  days = FLOOR(sec / 86400);
		SET 
		  hours = FLOOR((sec % 86400) / 3600);
		SET 
		  minutes = FLOOR(((123456 % 86400) % 3600) / 60);
		SET 
		  seconds = (((123456 % 86400) % 3600) % 60) % 60;
		 
		IF days > 0 THEN 
		SET 
		  result = CONCAT(result, days, " days ");
		END IF;
		
		IF hours > 0 THEN 
		SET 
		  result = CONCAT(result, hours, " hours ");
		END IF;
	
		IF minutes > 0 THEN 
		SET 
		  result = CONCAT(result, minutes, " minutes ");
		END IF;
	
		IF seconds > 0 THEN 
		SET 
		  result = CONCAT(result, seconds, " seconds ");
		END IF;
		
		RETURN result;
	END

/*
	Выведите только четные числа от 1 до 10 (Через цикл).
	Пример: 2,4,6,8,10
*/

DROP PROCEDURE IF EXISTS print_event_number;
DELIMITER $$ 
CREATE PROCEDURE print_event_number()
BEGIN
	DECLARE result VARCHAR(25) DEFAULT "";
	DECLARE i INT DEFAULT 1;
    WHILE i <= 10 DO
		IF i % 2 = 0 THEN
			SET result = CONCAT(result, i, " ");
		END IF;
        SET i = i + 1;
	END WHILE;
    SELECT result;

END ;

CALL print_event_number();

-- Создать функцию, вычисляющей коэффициент популярности пользователя (по количеству друзей)
DROP FUNCTION IF EXISTS get_popularity_coefficient;
DELIMITER $$
CREATE FUNCTION get_popularity_coefficient(
	user_id INT
)
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE result INT DEFAULT 0;
	SELECT 
		(   
			SELECT count(f.id)
			FROM (
				SELECT fr_init.initiator_user_id AS id
				FROM friend_requests fr_init
				WHERE fr_init.target_user_id = users.id AND fr_init.status='approved'
				UNION
				SELECT fr_targ.target_user_id 
				FROM friend_requests fr_targ
				WHERE fr_targ.initiator_user_id = users.id AND fr_targ.status='approved'
			) f
		) AS count_friends INTO result
	FROM users
    WHERE users.id = user_id;
    
    RETURN result;
END$$
 

/*
	Создать процедуру, которая решает следующую задачу
	Выбрать для одного пользователя 5 пользователей в случайной комбинации, которые удовлетворяют хотя бы одному критерию:
	а) из одного города
	б) состоят в одной группе
	в) друзья друзей
*/
DROP PROCEDURE IF EXISTS five_users;
DELIMITER $$
CREATE PROCEDURE five_users
(
	IN id_user_find INT
)
BEGIN
	
    SELECT target.id
    FROM
    (
		SELECT id 
		FROM users u
		INNER JOIN profiles p
		ON u.id = p.user_id
		AND u.id <> id_user_find
		AND (
			SELECT prof.hometown
			FROM users u1
			INNER JOIN profiles prof
			ON u1.id = prof.user_id
			AND u1.id = id_user_find
		) = p.hometown
		UNION    
		SELECT DISTINCT u.id 
		FROM users u
		INNER JOIN users_communities uc
		ON u.id = uc.user_id
		WHERE uc.community_id IN 
		(
			SELECT community_id
			FROM users_communities
			WHERE users_communities.user_id = id_user_find
		)    
		UNION
		SELECT id
		FROM users 
		WHERE users.id IN (
			(
				SELECT initiator_user_id AS id 
				FROM friend_requests
				WHERE status='approved' 
				AND target_user_id IN (
					SELECT initiator_user_id AS id 
					FROM friend_requests
					WHERE target_user_id = id_user_find AND status='approved'
					UNION ALL
					SELECT target_user_id 
					FROM friend_requests
					WHERE initiator_user_id = id_user_find AND status='approved'
				) 
				UNION
				SELECT target_user_id 
				FROM friend_requests
				WHERE status='approved' 
				AND initiator_user_id IN (
					SELECT initiator_user_id AS id 
					FROM friend_requests
					WHERE target_user_id = id_user_find AND status='approved'
					UNION ALL
					SELECT target_user_id 
					FROM friend_requests
					WHERE initiator_user_id = id_user_find AND status='approved'
				)
			)
		)
	) target
    ORDER BY RAND() 
    LIMIT 5;

END$$

CALL five_users(4);

/*
	Создайте хранимую функцию hello(), которая будет возвращать приветствие, в зависимости от текущего времени суток. 
	С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", с 12:00 до 18:00 функция должна возвращать фразу "Добрый день", 
	с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".
*/

DELIMITER $$
CREATE FUNCTION greeting() 
	RETURNS VARCHAR(25)
	DETERMINISTIC
BEGIN
	DECLARE greeting_text VARCHAR(25);
	SELECT CASE 
		WHEN CURTIME() >= '00:00:00' AND  CURTIME() < '06:00:00' THEN 'Доброй ночи'	
		WHEN CURTIME() >= '06:00:00' AND  CURTIME() < '12:00:00' THEN 'Доброе утро'
		WHEN CURTIME() >= '12:00:00' AND  CURTIME() < '18:00:00' THEN 'Добрый день'
		ELSE 'Добрый вечер'
	END INTO greeting_text;
	RETURN greeting_text;
END;


/*
	Создайте таблицу logs типа Archive. Пусть при каждом создании записи в таблицах users, communities и messages в таблицу logs 
	помещается время и дата создания записи, название таблицы, идентификатор первичного ключа. (Триггеры)
*/

DROP TABLE IF EXISTS logs;

CREATE TABLE logs (
    created_at DATETIME DEFAULT now(),
    table_name VARCHAR(20) NOT NULL,
    pk_id INT UNSIGNED NOT NULL
)  ENGINE=ARCHIVE;

CREATE 
    TRIGGER  users_log
 AFTER INSERT ON users FOR EACH ROW 
    INSERT INTO logs SET table_name = 'users' , pk_id = NEW.id;

CREATE 
    TRIGGER  communities_log
 AFTER INSERT ON communities FOR EACH ROW 
    INSERT INTO logs SET table_name = 'communities' , pk_id = NEW.id;

CREATE 
    TRIGGER  messages_log
AFTER INSERT ON messages FOR EACH ROW	
    INSERT INTO logs SET table_name = 'messages' , pk_id = NEW.id;
    
    
