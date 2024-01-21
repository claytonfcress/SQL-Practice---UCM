
#EJERCICIO 1

USE prestamos_2015;

CREATE TABLE prestamos_2015.merchants(
merchant_id VARCHAR(50),
name VARCHAR(50)
);

CREATE TABLE prestamos_2015.orders(
order_id VARCHAR(50),
created_at DATETIME,
status VARCHAR(50),
amount FLOAT,
merchant_id VARCHAR(50),
country VARCHAR(50)
);


CREATE TABLE refunds(
order_id VARCHAR(50),
refunded_at DATETIME,
amount FLOAT
);

DELETE FROM prestamos_2015.merchants WHERE merchant_id = "merchant_id";


#EJERCICIO 2

#Pregunta 1 
# Realizamos una consulta donde obtengamos por país y estado de operación, el
#total de operaciones y su importe promedio. La consulta debe cumplir las
#siguientes condiciones:
	#a. Operaciones posteriores al 01-07-2015
	#b. Operaciones realizadas en Francia, Portugal y España.
	#c. Operaciones con un valor mayor de 100 € y menor de 1500€
#Ordenamos los resultados por el promedio del importe de manera descendente

SELECT
    country AS 'pais',
    status AS 'estado',
    ROUND(SUM(amount),2) AS total_operaciones,
    ROUND(AVG(amount),2) AS promedio 
FROM
    orders
WHERE
    created_at > '2015-07-01' AND country IN ('España', 'Portugal', 'Francia') AND amount BETWEEN 100 AND 1500
GROUP BY
    country, status
ORDER BY
    promedio DESC;
    

#Pregunta 2
#Realizamos una consulta donde obtengamos los 3 países con el mayor número de
#operaciones, el total de operaciones, la operación con un valor máximo y la
#operación con el valor mínimo para cada país. La consulta debe cumplir las
#siguientes condiciones:
	#a. Excluimos aquellas operaciones con el estado “Delinquent” y “Cancelled”
	#b. Operaciones con un valor mayor de 100 €
    
SELECT 
	country AS 'pais', 
    COUNT(order_id) AS 'operaciones', 
    MAX(amount) AS 'maximo', 
    MIN(amount) AS 'minimo'
FROM
	orders
WHERE 
	status NOT IN ('DELINQUENT', 'CANCELLED')
    AND amount>100
GROUP BY 
	country
ORDER BY
	operaciones DESC
LIMIT 3;

#EJERCICIO 3
#A partir de las tablas incluidas en la base de datos prestamos 2015 vamos a realizar las siguientes consultas:


#Pregunta 1 
#Realizamos una consulta donde obtengamos, por país y comercio, el total 
#de operaciones, su valor promedio y el total de devoluciones. La consulta
#debe cumplir las siguientes condiciones:
	#a. Se debe mostrar el nombre y el id del comercio.
	#b. Comercios con más de 10 ventas.
	#c. Comercios de Marruecos, Italia, España y Portugal.
	#d. Creamos un campo que identifique si el comercio acepta o no devoluciones.
#Si no acepta (total de devoluciones es igual a cero) el campo debe contener el
#valor “No” y si sí lo acepta (total de devoluciones es mayor que cero) el campo
#debe contener el valor “Sí”. Llamaremos al campo “acepta_devoluciones”.
#Ordenamos los resultados por el total de operaciones de manera ascendente.

SELECT
  merchants.merchant_id, 
  name,
  country AS pais,
  ROUND(SUM(orders.amount), 2) AS 'total_operaciones',
  ROUND(AVG(orders.amount), 2) AS promedio,
  COALESCE(ROUND(SUM(order_refunds.total_refunds), 2), 0) AS 'total_devoluciones',
  CASE
    WHEN COALESCE(ROUND(SUM(order_refunds.total_refunds), 2), 0) = 0 THEN 'No'
    ELSE 'Si'
  END AS 'acepta_devoluciones'
FROM
  orders
INNER JOIN 
  merchants ON orders.merchant_id = merchants.merchant_id
LEFT JOIN 
  (
   SELECT order_id, COALESCE(SUM(amount), 0) AS total_refunds
   FROM refunds
   GROUP BY order_id
  ) AS order_refunds ON orders.order_id = order_refunds.order_id
WHERE 
  country IN ('Marruecos', 'Italia', 'España', 'Portugal')
GROUP BY 
  merchants.merchant_id, name, country
HAVING
  COUNT(orders.merchant_id) > 10
ORDER BY 
  total_operaciones ASC;



#Pregunta 2 

#Realizamos una consulta donde vamos a traer todos los campos de las tablas operaciones
#y comercios. De la tabla devoluciones vamos a traer el conteo de devoluciones por
#operación y la suma del valor de las devoluciones. 

    
 SELECT
    o.*, 
    m.*,
    COUNT(r.order_id) / COUNT(DISTINCT o.order_id) AS devol_por_oper,
    COALESCE(ROUND(SUM(r.amount),2), "No hay datos") AS total_devolucion
FROM 
    orders AS o
LEFT JOIN
    merchants AS m ON o.merchant_id = m.merchant_id
LEFT JOIN
    refunds AS r ON o.order_id = r.order_id
GROUP BY
	r.order_id,
    o.order_id,
    m.merchant_id
ORDER BY 
	total_devolucion ASC;
    
    
    
#Una vez tengamos la consulta anterior,
#creamos una vista con el nombre orders_view dentro del esquema tarea_ucm con esta consulta.
#Nota: La tabla refunds contiene más de una devolución por operación por lo que, para
#hacer el cruce, es muy importante que agrupemos las devoluciones.

CREATE VIEW orders_view AS
SELECT
    o.*, 
    m.merchant_id AS vendor_id,
    m.name,
    COUNT(r.order_id) / COUNT(DISTINCT o.order_id) AS devol_por_oper,
    COALESCE(ROUND(SUM(r.amount),2), "No hay datos") AS total_devolucion
FROM 
    orders AS o
LEFT JOIN
    merchants AS m ON o.merchant_id = m.merchant_id
LEFT JOIN
    refunds AS r ON o.order_id = r.order_id
GROUP BY
	r.order_id,
    o.order_id,
    m.merchant_id
ORDER BY 
	total_devolucion ASC; 
    
SELECT * FROM orders_view;
    
    
#EJERCICIO 4

#A partir de los datos disponibles diseñar una funcionalidad a tu elección que permita obtener
#un insight de interés sobre el caso de uso estudiado.
#Para ello debes plantear primeramente en un breve texto el objetivo de tu funcionalidad, la
#queries desarrollada y una reflexión sobre el insight obtenido. Para ello puedes usar cualquier
#recurso estudiado en clase.
#Algunas funcionalidades podrían ser: segmentación de clientes en función del valor de las
#operaciones, sistema de alertas para operaciones delictivas, identificación de estacionalidad,
#etc.. Tienes libertad total para desarrollar tu funcionalidad, lo importante es que tenga tu sello
#personal.

#ESTUDIO LA SATISFACCION DEL CLIENTE SEGUN LA TASAS DE RETORNO DE LAS EMPRESAS EN CADA PAIS

# Análisis exploratorio de las operaciones y devoluciones de cada establecimiento en cada país para determinar si un establecimiento acepta o no devoluciones  

SELECT
  merchants.name AS nombre,
  country AS pais,
  COUNT(orders.amount) AS operaciones,
  COUNT(order_refunds.refund_count) AS devoluciones,
  CASE
    WHEN COALESCE(COUNT(order_refunds.refund_count), 0) = 0 THEN 'No'
    ELSE 'Si'
  END AS 'acepta_devoluciones'
FROM
  orders
INNER JOIN 
  merchants ON orders.merchant_id = merchants.merchant_id
LEFT JOIN 
  (
   SELECT order_id, COALESCE(COUNT(amount), 0) AS refund_count
   FROM refunds
   GROUP BY order_id
  ) AS order_refunds ON orders.order_id = order_refunds.order_id
GROUP BY 
  merchants.merchant_id, nombre, country
ORDER BY 
  devoluciones DESC;
	
#Calcular la "tasa de éxito" para aquellos establecimientos que aceptan devoluciones

WITH RefundCounts AS (
	SELECT
		merchants.name AS nombre,
        country AS pais,
		COUNT(orders.amount) AS operaciones,
		COUNT(order_refunds.refund_count) AS devoluciones,
		CASE
			WHEN COALESCE(COUNT(order_refunds.refund_count), 0) = 0 THEN 'No'
			ELSE 'Si'
		END AS 'acepta_devoluciones'
	FROM
		orders
	INNER JOIN merchants ON orders.merchant_id = merchants.merchant_id
	LEFT JOIN (
		SELECT 
			order_id, 
            COALESCE(COUNT(amount), 0) AS refund_count
		FROM refunds
		GROUP BY order_id
		) AS order_refunds ON orders.order_id = order_refunds.order_id
	GROUP BY 
		merchants.merchant_id, nombre, country
	ORDER BY 
		devoluciones DESC
)
SELECT
	nombre,
    pais,
    operaciones,
    devoluciones,
    acepta_devoluciones,
    CASE
		WHEN acepta_devoluciones = 'Si' THEN ROUND(1-(devoluciones/operaciones),2)
        ELSE 'No hay datos'
	END AS Tasa_de_exito    
FROM
    RefundCounts;

#Utilizar nuestra "tasa de éxito" para analizar la satisfacción de los clientes en cada establecimiento de cada país que acepta devoluciones.
    
SELECT 
    nombre,
    pais,
    operaciones,
    devoluciones,
    acepta_devoluciones,
    Tasa_de_exito,    
    CASE
		WHEN Tasa_de_exito <= 0.85 THEN 'BAJO'
        WHEN Tasa_de_exito > 0.85 AND Tasa_de_exito <= 0.925 THEN 'MEDIO'
        WHEN Tasa_de_exito > 0.925 AND Tasa_de_exito < 1.0 THEN 'ALTO'
        ELSE "PERFECTO"
    END AS 'Nivel de satisfaccion'
FROM (WITH RefundCounts AS (
	SELECT
		merchants.name AS nombre,
        country AS pais,
		COUNT(orders.amount) AS operaciones,
		COUNT(order_refunds.refund_count) AS devoluciones,
		CASE
			WHEN COALESCE(COUNT(order_refunds.refund_count), 0) = 0 THEN 'No'
			ELSE 'Si'
		END AS 'acepta_devoluciones'
	FROM
		orders
	INNER JOIN merchants ON orders.merchant_id = merchants.merchant_id
	LEFT JOIN (
		SELECT 
			order_id, 
            COALESCE(COUNT(amount), 0) AS refund_count
		FROM refunds
		GROUP BY order_id
		) AS order_refunds ON orders.order_id = order_refunds.order_id
	GROUP BY 
		merchants.merchant_id, nombre, country
	ORDER BY 
		devoluciones DESC
)
SELECT
	nombre,
    pais,
    operaciones,
    devoluciones,
    acepta_devoluciones,
    CASE
		WHEN acepta_devoluciones = 'Si' THEN ROUND(1-(devoluciones/operaciones),2)
        ELSE 'No hay datos'
	END AS Tasa_de_exito        
FROM
    RefundCounts) AS rc
WHERE Tasa_de_exito !='No hay datos'
ORDER BY Tasa_de_exito DESC;
    



    





