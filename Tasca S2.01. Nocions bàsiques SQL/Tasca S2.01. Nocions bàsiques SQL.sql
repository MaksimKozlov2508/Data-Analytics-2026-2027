-- Nivell 1
-- Exercici 1
-- Consultar la estructura
DESCRIBE transactions.company;

DESCRIBE transactions.transaction;

-- Contar los registros
SELECT COUNT(*)
FROM transactions.company;

SELECT COUNT(*)
FROM transactions.transaction;

-- Identificar las claves foráneas
SELECT TABLE_NAME,
	COLUMN_NAME, 
	CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'transactions'
AND REFERENCED_TABLE_NAME IS NOT NULL;

-- Consultar las características de almacenamiento
SHOW TABLE STATUS FROM transactions;

-- Consultar el conjunto de caracteres de la base de datos
SHOW VARIABLES LIKE 'character_set_database';


-- Exercici 2
USE transactions;

-- Listado de los países que están generando ventas
SELECT DISTINCT c.country
FROM company c
JOIN transaction t 
	ON c.id = t.company_id;

-- Desde cuántos países se generan las ventas
SELECT COUNT(*) AS total_countries
FROM (	SELECT DISTINCT c.country
		FROM company c
		JOIN transaction t 
			ON c.id = t.company_id) p;

SELECT COUNT(DISTINCT c.country) AS total_countries
FROM company c
JOIN transaction t 
	ON c.id = t.company_id;

-- Identifica a la compañía con la mayor media de ventas
SELECT c.company_name, ROUND(AVG(t.amount), 2) AS avg_amount
FROM company c
JOIN transaction t 
	ON c.id = t.company_id
GROUP BY c.id
ORDER BY avg_amount DESC
LIMIT 1;


-- Exercici 3 (sin utilizar JOINS)
-- Muestra todas las transacciones realizadas por empresas de Alemania.
SELECT *
FROM transaction t
WHERE t.company_id IN (	SELECT c.id
						FROM company c
						WHERE c.country='Germany');

-- Lista las empresas que han realizado transacciones por un amount superior a la media de todas las transacciones.
SELECT DISTINCT c.id, c.company_name
FROM company c
WHERE c.id IN (	SELECT t.company_id
				FROM transaction t
				WHERE t.amount > (	SELECT AVG(t1.amount)
									FROM transaction t1));

-- Eliminarán del sistema las empresas que carecen de transacciones registradas, entrega el listado de estas empresas.
SELECT DISTINCT c.id, c.company_name
FROM company c
WHERE c.id NOT IN (	SELECT t.company_id
					FROM transaction t
                    WHERE t.company_id IS NOT NULL);


-- Exercici 4
USE transactions;

-- Creamos la tabla credit_card
CREATE TABLE IF NOT EXISTS credit_card (
	id VARCHAR(15) PRIMARY KEY,
	iban VARCHAR(34),
    pan VARCHAR(25),
    pin VARCHAR(4),
    cvv VARCHAR(3),
    expiring_date DATE);
    
DESCRIBE credit_card;

-- Cambio el tipo de dato de DATE a VARCHAR por formato
-- de fecha incorrecto en 'dades_introduir_credit'
ALTER TABLE credit_card
MODIFY expiring_date VARCHAR(10);

SELECT COUNT(*) 
FROM credit_card;

-- Desactivo el modo seguro (restricciones) para 
-- convertir las fechas al formato DATE
SET SQL_SAFE_UPDATES = 0;

-- Convierto el formato de texto de las fechas al formato 
-- estándar de fecha (YYYY-MM-DD)
UPDATE credit_card
SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%y');

-- Restauro las restricciones
SET SQL_SAFE_UPDATES = 1;

-- Cambio el tipo de dato de la columna de VARCHAR a DATE 
-- una vez corregido el formato
ALTER TABLE credit_card
MODIFY expiring_date DATE;

-- Compruebo que todos los datos se hayan transferido 
-- correctamente (si no devuelve resultados, todo está bien)
SELECT DISTINCT t.credit_card_id
FROM transaction t
LEFT JOIN credit_card cc 
	ON t.credit_card_id = cc.id
WHERE t.credit_card_id IS NOT NULL
AND cc.id IS NULL;

-- Añado la clave foránea (FOREIGN KEY) para relacionar 
-- la tabla transaction con credit_card
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);


-- Exercici 5
UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

SELECT id, iban
FROM credit_card
WHERE id = 'CcU-2938';


-- Exercici 6

-- Añado los nuevos IDs en company y credit_card
-- antes de insertar la transacción, ya que sin 
-- ellos daría un error de integridad referencial
INSERT INTO company(id)
VALUES ('b-9999');

INSERT INTO credit_card(id)
VALUES ('Ccu-9999');

INSERT INTO transaction (
    id,
    credit_card_id,
    company_id,
    user_id,
    lat,
    longitude,
    amount,
    declined
)
VALUES (
    '108B1D1D-5B23-A76C-55EF-C568E49A99DD',
    'CcU-9999',
    'b-9999',
    9999,
    829.999,
    -117.999,
    111.11,
    0
);


-- Exercici 7
ALTER TABLE credit_card
DROP COLUMN pan;

DESCRIBE credit_card;

-- Exercici 8
-- Creación nueva base de datos
CREATE DATABASE IF NOT EXISTS transactions_star;
USE transactions_star;

-- Creación de tablas para el esquema de estrella
-- (dimensiones y hechos)

-- Tabla de dimensión de usuarios: unifica los 
-- datos de american_users y european_users
CREATE TABLE IF NOT EXISTS dim_users (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(255),
    birth_date DATE,
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    address VARCHAR(255),
    signup_date DATE,
    user_segment VARCHAR(100),
    income_band VARCHAR(50)
);

-- Tabla de dimensión de empresas: almacena la 
-- información de los comercios (companies)
CREATE TABLE IF NOT EXISTS dim_companies (
	company_id VARCHAR(20) PRIMARY KEY,
    company_name VARCHAR(150),
    phone VARCHAR(30),
    email VARCHAR(255),
	country VARCHAR(100),
    website VARCHAR(255),
    merchant_category VARCHAR(100),
	merchant_price_position VARCHAR(50)
);

-- Tabla de dimensión de tarjetas de crédito: contiene
-- los detalles y fechas de caducidad de cada tarjeta
CREATE TABLE IF NOT EXISTS dim_credit_cards (
	id VARCHAR(15) PRIMARY KEY,
    user_id INT,
    iban VARCHAR(34),
    pan VARCHAR(30),
    pin VARCHAR(10),
	cvv VARCHAR(5),
    track1 TEXT,
    track2 TEXT,
    expiring_date DATE,
    card_type VARCHAR(50),
    card_renewal_flag TINYINT(1)
    );

-- Tabla de hechos de transacciones: registra cada operación 
-- financiera y enlaza con las dimensiones
CREATE TABLE IF NOT EXISTS fact_transactions (
	id VARCHAR(36) PRIMARY KEY,
    card_id VARCHAR(15),
    business_id VARCHAR(20),
    timestamp DATETIME,
    amount DECIMAL(10,2),
    declined TINYINT(1),
    product_ids TEXT,
    user_id INT,
    lat DECIMAL(10,7),
    longitude DECIMAL(10,7),
    discount_amount DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    shipping_amount DECIMAL(10,2),
    channel VARCHAR(50),
    campaign_id VARCHAR(50),
    device_type VARCHAR(50),
    is_international TINYINT(1),
    decline_reason VARCHAR(255),
    distance_km DECIMAL(10,2)
    );
    
-- Verifico si la carga de archivos locales
-- (local_infile) está activada en el servidor
SHOW VARIABLES LIKE 'local_infile';

-- Activo globalmente local_infile para permitir 
-- la importación de datos desde los archivos CSV
SET GLOBAL local_infile = 1;

-- Carga de datos desde archivos csv
LOAD DATA LOCAL INFILE
'C:/Users/kozlo/OneDrive/Desktop/IT Academia/Data Analytics/Ejercicio/N1-Ex.8__companies.csv'
INTO TABLE dim_companies
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    company_id,
    company_name,
    phone,
    email,
    country,
    website,
    merchant_category,
    merchant_price_position
);

LOAD DATA LOCAL INFILE
'C:/Users/kozlo/OneDrive/Desktop/IT Academia/Data Analytics/Ejercicio/N1-Ex.8__american_users.csv'
INTO TABLE dim_users
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    id,
    name,
    surname,
    phone,
    email,
    @birth_date,
    country,
    city,
    postal_code,
    address,
    @signup_date,
    user_segment,
    income_band
)
SET
    birth_date = STR_TO_DATE(@birth_date, '%b %e, %Y'),
    signup_date = STR_TO_DATE(@signup_date, '%Y-%m-%d');
    
LOAD DATA LOCAL INFILE
'C:/Users/kozlo/OneDrive/Desktop/IT Academia/Data Analytics/Ejercicio/N1-Ex.8__european_users.csv'
INTO TABLE dim_users
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    id,
    name,
    surname,
    phone,
    email,
    @birth_date,
    country,
    city,
    postal_code,
    address,
    @signup_date,
    user_segment,
    income_band
)
SET
    birth_date = STR_TO_DATE(@birth_date, '%b %e, %Y'),
    signup_date = STR_TO_DATE(@signup_date, '%Y-%m-%d');    

LOAD DATA LOCAL INFILE
'C:/Users/kozlo/OneDrive/Desktop/IT Academia/Data Analytics/Ejercicio/N1-Ex.8__credit_cards.csv'
INTO TABLE dim_credit_cards
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    id,
    user_id,
    iban,
    pan,
    pin,
    cvv,
    track1,
    track2,
    @expiring_date,
    card_type,
    card_renewal_flag
)
SET
    expiring_date = STR_TO_DATE(@expiring_date, '%m/%d/%y');

LOAD DATA LOCAL INFILE
'C:/Users/kozlo/OneDrive/Desktop/IT Academia/Data Analytics/Ejercicio/N1-Ex.8__transactions.csv'
INTO TABLE fact_transactions
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    id,
    card_id,
    business_id,
    @timestamp,
    amount,
    declined,
    product_ids,
    user_id,
    lat,
    longitude,
    discount_amount,
    tax_amount,
    shipping_amount,
    channel,
    campaign_id,
    device_type,
    is_international,
    decline_reason,
    distance_km
)
SET
    timestamp = STR_TO_DATE(@timestamp, '%Y-%m-%d %H:%i:%s');
    
-- creación de claves foráneas (relaciones del esquema de estrella)
ALTER TABLE fact_transactions
ADD CONSTRAINT fk_transactions_users
FOREIGN KEY (user_id)
REFERENCES dim_users(id);

ALTER TABLE fact_transactions
ADD CONSTRAINT fk_transactions_companies
FOREIGN KEY (business_id)
REFERENCES dim_companies(company_id);

ALTER TABLE fact_transactions
ADD CONSTRAINT fk_transactions_cards
FOREIGN KEY (card_id)
REFERENCES dim_credit_cards(id);


-- Exercisi 9
USE transactions_star;

SELECT du.id, du.name, du.surname
FROM dim_users du
WHERE du.id IN (	SELECT ft.user_id
					FROM fact_transactions ft
					GROUP BY ft.user_id
					HAVING COUNT(*) > 80
				);

SELECT du.id, du.name, du.surname
FROM dim_users du
JOIN fact_transactions ft 
	ON du.id = ft.user_id
GROUP BY ft.user_id
HAVING COUNT(*) > 80;


-- Exercici 10
SELECT dcc.iban, ROUND(AVG(ft.amount), 2) AS avg_amount
FROM fact_transactions ft
JOIN dim_companies dc 
	ON  ft.business_id = dc.company_id
JOIN dim_credit_cards dcc 
	ON ft.card_id = dcc.id
WHERE dc.company_name = 'Donec Ltd'
GROUP BY dcc.iban
ORDER BY avg_amount;


-- Nivell 2

-- Exercici 1
SELECT DATE(timestamp) AS sale_date,
	ROUND(SUM(amount), 2) AS total_sales
FROM fact_transactions
WHERE declined = 0
GROUP BY sale_date
ORDER BY total_sales DESC
LIMIT 5;


-- Exercici 2
SELECT dc.company_name, dc.phone, dc.country, 
	DATE(ft.timestamp) AS transaction_day, ft.amount
FROM dim_companies dc
JOIN fact_transactions ft
	ON dc.company_id = ft.business_id
WHERE ft.amount BETWEEN 350 AND 400
	AND DATE(ft.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
    AND declined = 0
    ORDER BY ft.amount DESC;
    

-- Exercici 3
SELECT dc.company_name, COUNT(*) AS number_transactions,
    CASE
        WHEN COUNT(*) >= 400 THEN '400 or more transactions'
        ELSE 'Fewer than 400 transactions'
    END AS transaction_category
FROM dim_companies dc
JOIN fact_transactions ft
    ON dc.company_id = ft.business_id
GROUP BY dc.company_id, dc.company_name
ORDER BY number_transactions DESC;


-- Exercici 4
-- Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.
DELETE FROM fact_transactions
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';


-- Exercici 5
CREATE VIEW VistaMarketing AS
SELECT dc.company_name AS Nom_companyia, dc.phone AS Telefon_contacte, 
	dc.country AS Pais_residencia, ROUND(AVG(ft.amount), 2) AS Mitjana_compra
FROM dim_companies dc
JOIN fact_transactions ft
	ON dc.company_id = ft.business_id
GROUP BY dc.company_id, dc.company_name, dc.phone, dc.country;

-- Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.
SELECT * FROM VistaMarketing
ORDER BY Mitjana_compra DESC;


-- Nivell 3

-- Exercici 1

-- Creo la tabla card_status para almacenar el estado actual ('active' o 'inactive') de cada tarjeta
-- Enlazo card_id como clave primaria y foránea con la dimensión dim_credit_cards
CREATE TABLE card_status (
	card_id VARCHAR(15) PRIMARY KEY,
    status VARCHAR(10) NOT NULL,
    
    FOREIGN KEY (card_id) REFERENCES dim_credit_cards(id)
);
-- Inserto en la tabla el estado calculado para cada tarjeta
INSERT INTO card_status (card_id, status)
-- CTE para enumerar las transacciones de cada tarjeta desde la más reciente hasta la más antigua
WITH ranked_transactions AS (
	SELECT card_id, declined, 
		ROW_NUMBER() OVER (
			PARTITION BY card_id
            ORDER BY timestamp DESC, id DESC
		) AS rt
	FROM fact_transactions
)
SELECT card_id,
	CASE
		WHEN SUM(declined) = 3 THEN 'inactive'
        ELSE 'active'
	END AS status
FROM ranked_transactions
WHERE rt <= 3
GROUP BY card_id;

-- Quantes targetes estan actives?
SELECT COUNT(*) AS active_cards
FROM card_status
WHERE status = 'active';

-- Exercici 2

-- Creo la tabla de dimensión dim_productos para integrar los datos del archivo csv
CREATE TABLE dim_products (
	id INT PRIMARY KEY,
    product_name VARCHAR(100),
    price VARCHAR(20),
    colour VARCHAR(20),
    weight DECIMAL(10,2),
    warehouse_id VARCHAR(20),
    category VARCHAR(50),
    brand VARCHAR(50),
    cost VARCHAR(20),
    launch_date date
);

-- Carga de datos desde archivo csv
LOAD DATA LOCAL INFILE
'C:/Users/kozlo/OneDrive/Desktop/IT Academia/Data Analytics/Ejercicio/N1-Ex.8__products.csv'
INTO TABLE dim_products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    id,
    product_name,
    price,
    colour,
    weight,
    warehouse_id,
    category,
    brand,
    cost,
    launch_date
);

-- Creo la tabla puente transaction_products para resolver la relación mucho a muchos (N:M)
-- Permite enlazar cada transacción de fact_transactions con sus productos individuales en dim_productos
CREATE TABLE transaction_products (
	transaction_id VARCHAR(36) NOT NULL,
    product_id INT NOT NULL,
    
    PRIMARY KEY (transaction_id, product_id),
    
    FOREIGN KEY (transaction_id) REFERENCES fact_transactions(id),
    
    FOREIGN KEY (product_id) REFERENCES dim_products(id)
);

-- Separo la lista de product_ids (delimitado por comas) en filas individuales mediante un CTE recursivo
-- Extraigo, limpio y convierto cada ID a entero para insertar las relaciones en transaction_products
INSERT INTO transaction_products (transaction_id, product_id)

WITH RECURSIVE split_products AS (

    SELECT
        id AS transaction_id,
        product_ids,
        1 AS n,
        1 + LENGTH(product_ids)
            - LENGTH(REPLACE(product_ids, ',', '')) AS total
    FROM fact_transactions
    WHERE product_ids IS NOT NULL
      AND TRIM(product_ids) <> ''

    UNION ALL

    SELECT
        transaction_id,
        product_ids,
        n + 1,
        total
    FROM split_products
    WHERE n < total
)

SELECT
    transaction_id,
    CAST(
        TRIM(
            SUBSTRING_INDEX(
                SUBSTRING_INDEX(product_ids, ',', n),
                ',',
                -1
            )
        ) AS UNSIGNED
    ) AS product_id
FROM split_products;

-- Necesitamos conocer el número de veces que se ha vendido cada producto
SELECT
    p.id AS product_id,
    p.product_name,
    COUNT(tp.product_id) AS times_sold
FROM dim_products AS p
LEFT JOIN transaction_products AS tp
    ON p.id = tp.product_id
GROUP BY
    p.id,
    p.product_name
ORDER BY times_sold DESC;