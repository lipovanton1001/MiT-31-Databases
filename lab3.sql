-- РОЗДІЛ 1. ЛОГІЧНІ ОПЕРАТОРИ ТА БАЗОВІ ВИБІРКИ
-- Запит 1. Вибрати мешканців, які мають пільги ТА живуть на певній вулиці (AND)
SELECT full_name, address FROM residents WHERE has_benefits = TRUE AND address LIKE '%Шевченка%';

-- Запит 2. Вибрати рахунки, які мають штраф АБО сума яких більша за 1000 (OR)
SELECT * FROM bills WHERE has_penalty = TRUE OR amount > 1000;

-- Запит 3. Вибрати платежі, статус яких НЕ 'completed' (NOT)
SELECT * FROM payments WHERE NOT status = 'completed';

-- Запит 4. Вибрати послуги, категорія яких належить до визначеного списку (IN)
SELECT * FROM services WHERE category IN ('Енергетика', 'Водоканал');

-- Запит 5. Вибрати рахунки за певний період (BETWEEN)
SELECT * FROM bills WHERE billing_month BETWEEN '2023-01-01' AND '2023-12-31';


-- РОЗДІЛ 2. АГРЕГАТНІ ФУНКЦІЇ ТА ГРУПУВАННЯ
-- Запит 6. Підрахувати загальну кількість зареєстрованих мешканців (COUNT)
SELECT COUNT(id) AS total_residents FROM residents;

-- Запит 7. Знайти загальну суму всіх успішних платежів (SUM)
SELECT SUM(amount) AS total_revenue FROM payments WHERE status = 'completed';

-- Запит 8. Знайти середній розмір рахунку за комуналку (AVG)
SELECT AVG(amount) AS average_bill_amount FROM bills;

-- Запит 9. Знайти мінімальний та максимальний платіж у системі (MIN, MAX)
SELECT MIN(amount) AS min_payment, MAX(amount) AS max_payment FROM payments;

-- Запит 10. Вивести категорії послуг, де кількість послуг більше 1 (GROUP BY + HAVING)
SELECT category, COUNT(id) as service_count 
FROM services 
GROUP BY category 
HAVING COUNT(id) > 1;



-- РОЗДІЛ 3. УСІ ТИПИ JOIN
-- Запит 11. Отримати імена мешканців та суми їхніх рахунків (INNER JOIN)
SELECT r.full_name, b.amount 
FROM residents r 
INNER JOIN bills b ON r.id = b.resident_id;

-- Запит 12. Вивести всіх мешканців та їхні рахунки, навіть якщо рахунків ще немає (LEFT JOIN)
SELECT r.full_name, b.amount 
FROM residents r 
LEFT JOIN bills b ON r.id = b.resident_id;

-- Запит 13. Вивести всі послуги та виставлені за ними рахунки (RIGHT JOIN)
SELECT s.service_name, b.amount 
FROM bills b 
RIGHT JOIN services s ON b.service_id = s.id;

-- Запит 14. Об'єднати всі рахунки та всі платежі, показуючи співпадіння та пропуски (FULL JOIN)
SELECT b.id AS bill_id, p.id AS payment_id, p.amount 
FROM bills b 
FULL OUTER JOIN payments p ON b.id = p.bill_id;

-- Запит 15. Згенерувати матрицю всіх можливих комбінацій мешканців та послуг (CROSS JOIN)
SELECT r.full_name, s.service_name 
FROM residents r 
CROSS JOIN services s;

-- Запит 16. Знайти мешканців, які проживають за однаковою адресою (SELF JOIN)
SELECT r1.full_name AS resident1, r2.full_name AS resident2, r1.address 
FROM residents r1 
INNER JOIN residents r2 ON r1.address = r2.address AND r1.id != r2.id;

-- Запит 17. Складний JOIN 4-х таблиць: Хто, за що, скільки винен і скільки оплатив
SELECT r.full_name, s.service_name, b.amount AS billed, p.amount AS paid 
FROM residents r
JOIN bills b ON r.id = b.resident_id
JOIN services s ON b.service_id = s.id
LEFT JOIN payments p ON b.id = p.bill_id;



-- РОЗДІЛ 4. ПІДЗАПИТИ (SUBQUERIES)
-- Запит 18. Підзапит у WHERE: Знайти рахунки мешканця з конкретним ім'ям
SELECT * FROM bills 
WHERE resident_id = (SELECT id FROM residents WHERE full_name = 'Іваненко Іван Іванович');

-- Запит 19. Підзапит з IN: Знайти платежі за послуги категорії 'Енергетика'
SELECT * FROM payments 
WHERE bill_id IN (
    SELECT id FROM bills WHERE service_id IN (
        SELECT id FROM services WHERE category = 'Енергетика'
    )
);

-- Запит 20. Підзапит у SELECT: Вивести мешканців та їхній найбільший рахунок
SELECT full_name, 
       (SELECT MAX(amount) FROM bills WHERE resident_id = residents.id) AS max_bill 
FROM residents;

-- Запит 21. Підзапит у FROM: Знайти середню суму платежу серед успішних транзакцій
SELECT AVG(p_amount) AS avg_successful_payment 
FROM (SELECT amount AS p_amount FROM payments WHERE status = 'completed') AS sub_p;

-- Запит 22. EXISTS: Знайти мешканців, які мають хоча б один неоплачений рахунок зі штрафом
SELECT full_name FROM residents r 
WHERE EXISTS (
    SELECT 1 FROM bills b WHERE b.resident_id = r.id AND b.has_penalty = TRUE
);

-- Запит 23. NOT EXISTS: Знайти послуги, за якими ще не виставлялися рахунки
SELECT service_name FROM services s 
WHERE NOT EXISTS (
    SELECT 1 FROM bills b WHERE b.service_id = s.id
);

-- Запит 24. Багаторівневий вкладений підзапит (для вищої оцінки): 
-- Знайти імена мешканців, чия сума платежів вища за середню суму всіх платежів у системі
SELECT full_name FROM residents WHERE id IN (
    SELECT b.resident_id FROM bills b JOIN payments p ON b.id = p.bill_id
    GROUP BY b.resident_id
    HAVING SUM(p.amount) > (SELECT AVG(amount) FROM payments)
);

-- Запит 25. Корельований підзапит: Рахунки, сума яких більша за середній рахунок ДЛЯ ЦІЄЇ ж послуги
SELECT * FROM bills b1 
WHERE amount > (SELECT AVG(amount) FROM bills b2 WHERE b1.service_id = b2.service_id);



-- РОЗДІЛ 5. ОПЕРАЦІЇ НАД МНОЖИНАМИ
-- Запит 26. UNION: Об'єднати унікальні суми з рахунків та платежів (усі можливі фінансові суми)
SELECT amount FROM bills
UNION
SELECT amount FROM payments;

-- Запит 27. UNION ALL: Те саме, але зі збереженням дублікатів
SELECT amount FROM bills
UNION ALL
SELECT amount FROM payments;

-- Запит 28. INTERSECT: Знайти ідентифікатори рахунків, які були виставлені І які мають хоча б спробу оплати
SELECT id FROM bills
INTERSECT
SELECT bill_id FROM payments;

-- Запит 29. EXCEPT: Знайти рахунки, за якими ще не було жодного платежу (Боржники)
SELECT id FROM bills
EXCEPT
SELECT bill_id FROM payments;



-- РОЗДІЛ 6. COMMON TABLE EXPRESSIONS (CTE)
-- Запит 30. Базове CTE: Підрахунок загальної суми виставлених рахунків для кожного мешканця
WITH ResidentTotals AS (
    SELECT resident_id, SUM(amount) AS total_billed
    FROM bills GROUP BY resident_id
)
SELECT r.full_name, rt.total_billed 
FROM residents r JOIN ResidentTotals rt ON r.id = rt.resident_id;

-- Запит 31. CTE для фільтрації: Знайти мешканців з пільгами, чиї рахунки перевищують 500
WITH BeneficiaryBills AS (
    SELECT r.full_name, b.amount 
    FROM residents r JOIN bills b ON r.id = b.resident_id 
    WHERE r.has_benefits = TRUE
)
SELECT * FROM BeneficiaryBills WHERE amount > 500;

-- Запит 32. Використання кількох CTE у одному запиті (порівняння нарахувань та оплат)
WITH Billed AS (
    SELECT resident_id, SUM(amount) as total_billed FROM bills GROUP BY resident_id
),
Paid AS (
    SELECT b.resident_id, SUM(p.amount) as total_paid 
    FROM bills b JOIN payments p ON b.id = p.bill_id WHERE p.status = 'completed' GROUP BY b.resident_id
)
SELECT b.resident_id, b.total_billed, COALESCE(p.total_paid, 0) as total_paid
FROM Billed b LEFT JOIN Paid p ON b.resident_id = p.resident_id;

-- Запит 33. CTE для аналізу категорій послуг: відсоток оплат по категоріях
WITH CategoryStats AS (
    SELECT s.category, COUNT(b.id) as total_bills, COUNT(p.id) as paid_bills
    FROM services s 
    LEFT JOIN bills b ON s.id = b.service_id
    LEFT JOIN payments p ON b.id = p.bill_id AND p.status = 'completed'
    GROUP BY s.category
)
SELECT category, total_bills, paid_bills, 
       (paid_bills::numeric / NULLIF(total_bills, 0)) * 100 AS payment_rate 
FROM CategoryStats;



-- РОЗДІЛ 7. ВІКОННІ ФУНКЦІЇ (WINDOW FUNCTIONS)
-- Запит 34. ROW_NUMBER: Пронумерувати платежі для кожного рахунку за датою
SELECT bill_id, payment_date, amount,
       ROW_NUMBER() OVER (PARTITION BY bill_id ORDER BY payment_date) as payment_num
FROM payments;

-- Запит 35. RANK: Ранжування мешканців за сумою рахунку (з пропусками рангів при нічиїй)
SELECT r.full_name, b.amount,
       RANK() OVER (ORDER BY b.amount DESC) as rank_by_amount
FROM residents r JOIN bills b ON r.id = b.resident_id;

-- Запит 36. DENSE_RANK: Ранжування послуг за вартістю (без пропусків рангів)
SELECT service_id, amount,
       DENSE_RANK() OVER (ORDER BY amount DESC) as dense_rank_amount
FROM bills;

-- Запит 37. SUM OVER: Наростаючий підсумок (кумулятивна сума) платежів за часом
SELECT payment_date, amount,
       SUM(amount) OVER (ORDER BY payment_date) as cumulative_revenue
FROM payments WHERE status = 'completed';

-- Запит 38. AVG OVER: Порівняння конкретного рахунку з середнім по даній послузі
SELECT id, service_id, amount,
       AVG(amount) OVER (PARTITION BY service_id) as avg_for_service
FROM bills;

-- Запит 39. LAG: Отримання суми попереднього рахунку для мешканця (для пошуку трендів споживання)
SELECT resident_id, billing_month, amount,
       LAG(amount) OVER (PARTITION BY resident_id ORDER BY billing_month) as previous_month_amount
FROM bills;

-- Запит 40. LEAD: Отримання дати наступного платежу для аналізу затримок
SELECT bill_id, payment_date, amount,
       LEAD(payment_date) OVER (PARTITION BY bill_id ORDER BY payment_date) as next_payment_date
FROM payments;