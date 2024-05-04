/* Curso practico mySQL
Este trabajo se basa en el video: https://youtu.be/96s2i-H7e0w 
Creado por midulive */

--Create table users
CREATE TABLE users (
    user_id INT NOT NULL AUTO_INCREMENT,
    user_handle VARCHAR(50) NOT NULL UNIQUE,
    email_address VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    phonenumber CHAR(10) UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT (NOW()), -- Valor por defecto para saber cuando se creo
    PRIMARY KEY (user_id)
)

--('kingthor', 'emmaa44@outlook.com', 'Emmanuel', 'Zarazua', '4569083214')

INSERT INTO users(user_handle, email_address, first_name, last_name, phonenumber)
VALUES
('juanito', 'user123@gmail.com', 'Juan', 'Pérez', '1234567890'),
('ana', 'user456@yahoo.com', 'Ana', 'Gómez', '2345678901'),
('carlos22', 'user789@hotmail.com', 'Carlos', 'Rodríguez', '3456789012'),
('masha', 'user012@outlook.com', 'María', 'Martínez', '4567890123'),
('jorgito99', 'user345@icloud.com', 'Jorge', 'Hernández', '5678901234')

--Consultar tabla:
SELECT * FROM twitter_db.users;

--DROP TABLE IF EXISTS twitter_db;
--DROP TABLE IF EXISTS users;
--DROP TABLE IF EXISTS followers;

--Create table followers:
CREATE TABLE followers (
    follower_id INT NOT NULL,
    following_id INT NOT NULL,
    FOREIGN KEY(follower_id) REFERENCES users(user_id),
    FOREIGN KEY(following_id) REFERENCES users(user_id),
    PRIMARY KEY(follower_id, following_id)
);


--Desde la version 8 de mySQL se pueden añadir constrains para hacer checks (restriccion)
--Modificar tabla:
ALTER TABLE followers
ADD CONSTRAINT check_follower_id
CHECK (follower_id <> following_id);

INSERT INTO followers(follower_id, following_id)
VALUES
(1, 3),
(3, 4),
(3, 1),
(1, 4),
(1, 7),
(4, 3);

--Con el CONSTRAINT ya no puedo agregar (1, 1)
--ya que no tendria sentido que un usuario se siga a si mismo

INSERT INTO followers(follower_id, following_id)
VALUES
(4, 1),
(4, 5),
(3, 7),
(1, 6);

INSERT INTO followers(follower_id, following_id)
VALUES
(5, 1),
(6, 1),
(7, 1),
(7, 3),
(5, 3);

--Consultas:
--Top 4 usuarios con mayor numero de seguidores
SELECT following_id, COUNT(follower_id) AS followers
FROM followers
GROUP BY following_id
ORDER BY followers DESC
LIMIT 4

--Top 4 usuarios con mayor numero de seguidores using JOIN
SELECT users.user_id, users.user_handle, users.first_name, following_id, COUNT(follower_id) AS followers
FROM followers
JOIN users ON users.user_id = followers.following_id --Para JOIN se usa la tabla de donde queremos extraer
GROUP BY following_id
ORDER BY followers DESC
LIMIT 4

--Create table tweets
CREATE TABLE tweets(
    tweet_id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    tweet_text VARCHAR(300) NOT NULL,
    num_likes INT DEFAULT 0,
    num_retweets INT DEFAULT 0, --En este caso se pone 0 como inicializacion por defecto
    created_at TIMESTAMP NOT NULL DEFAULT (NOW()),
    FOREIGN KEY(user_id) REFERENCES users(user_id),
    PRIMARY KEY(tweet_id)
);

INSERT INTO tweets(user_id, tweet_text)
VALUES
(1, 'Hola soy nuevo en la plataforma'),
(3, 'La AI dominara el mundo? Abro hilo...'),
(1, 'Ayer vi esto jajajaja'),
(4, '¡Buenos días a todos! Espero que tengan un gran día.'),
(5, '¿Alguien más está emocionado por el partido de fútbol de esta noche? #VamosEquipo'),
(6, 'Acabo de terminar de leer un libro increíble. Lo recomiendo a todos los amantes de la lectura.'),
(7, '¿Alguien puede recomendarme una buena serie para ver este fin de semana?'),
(1, 'Hoy es un gran día para aprender algo nuevo. #AprendizajeContinuo'),
(3, 'Me encanta la música. ¿Cuál es tu canción favorita en este momento?'),
(4, 'La comida casera siempre es la mejor. #AmoCocinar'),
(5, 'Hoy hice yoga por primera vez y me encantó. #SaludYBienestar'),
(6, 'El café de la mañana es esencial para empezar bien el día. #AmanteDelCafé'),
(7, 'Estoy planeando un viaje. ¿Alguien tiene sugerencias de lugares para visitar?');

--¿Cuantos tweets ha hecho un usuario?
SELECT user_id, COUNT(*) AS tweet_count
FROM tweets
GROUP BY user_id;
--WHERE user_id = 1;

SELECT following_id, COUNT(*) as followers
FROM followers
GROUP BY following_id
HAVING followers > 2;

-- Sub consulta
--Obtener los tweets de los usuarios que tienen mas de 2 seguidores
SELECT tweet_id, tweet_text, user_id
FROM tweets
WHERE user_id IN (
    SELECT following_id
    FROM followers
    GROUP BY following_id
    HAVING COUNT(*) > 2
);

--Se agrega una columna mas
ADD COLUMN num_comments INT DEFAULT 0;


--DELETE
--SET SQL_SAFE_UPDATES = 0; Sirve para forzar eliminar datos de tablas pero por defecto viene activo por seguridad
DELETE FROM tweets WHERE tweet_id = 7;

SELECT * from tweets;

--UPDATE
UPDATE tweets SET num_comments = num_comments + 1 WHERE tweet_id = 16;


--remplazar texto
UPDATE tweets SET tweet_text = REPLACE(tweet_text, 'Hola', 'Hi')
WHERE tweet_text LIKE '%Hola%';

CREATE TABLE tweet_likes(
    user_id INT NOT NULL,
    tweet_id INT NOT NULL,
    FOREIGN KEY(user_id) REFERENCES users(user_id),
    FOREIGN KEY(tweet_id) REFERENCES tweets(tweet_id),
    PRIMARY KEY(user_id, tweet_id) --Se referencia nuevamente que a un usuario no le puede gustar mas de una vez un tweet
);

INSERT INTO tweet_likes
VALUES
(1, 15),
(3, 15),
(4, 17),
(5, 18),
(6, 20),
(7, 20),
(7, 15),
(5, 16),
(1, 17);


SELECT * FROM tweet_likes;

--Obtener el numero de likes por tweet
SELECT tweet_id, COUNT(*) AS like_count
FROM tweet_likes
GROUP BY tweet_id;

-- TRIGGERS // Si ocurre algo en nuestra BD hacer algo por ejmplo si alguien modifica algo
--          //se registre quien fue, cuando, etc. Puede aplicarse en otros sentidos

-- Registrar cada vez que se deje de seguir a alguien
DELIMITER $$

CREATE TRIGGER increase_follower_count
    AFTER INSERT ON followers
    FOR EACH ROW
    BEGIN
        UPDATE users SET follower_count = follower_count + 1
        WHERE user_id = NEW.following_id;   --NEW se refiere al nuevo, es decir a lo que estamos añadiendo en la linea
    END $$
DELIMITER; -- Nos aseguramos de delimitar correctamente el TRIGGER

-- Borrar cada vez que se deje de seguir a alguien
DELIMITER $$

CREATE TRIGGER decrease_follower_count
    AFTER DELETE ON followers
    FOR EACH ROW
    BEGIN
        UPDATE users SET follower_count = follower_count - 1
        WHERE user_id = NEW.following_id;
    END $$
DELIMITER;

