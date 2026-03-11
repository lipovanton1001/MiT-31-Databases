--Створення користувачів
CREATE USER admin_user WITH PASSWORD 'admin123';
CREATE USER moderator_user WITH PASSWORD 'mod123';
CREATE USER regular_user WITH PASSWORD 'user123';

--Надання прав
GRANT ALL PRIVILEGES ON DATABASE utility_payments_db TO admin_user;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO moderator_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO regular_user;

--Створення таблиць
CREATE TABLE residents (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    has_benefits BOOLEAN DEFAULT FALSE
);

CREATE TABLE services (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL
);

CREATE TABLE bills (
    id SERIAL PRIMARY KEY,
    resident_id INT REFERENCES residents(id),
    service_id INT REFERENCES services(id),
    billing_month DATE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    has_penalty BOOLEAN DEFAULT FALSE
);

CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    bill_id INT REFERENCES bills(id),
    payment_date DATE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'completed'
);

--Заповнення таблиць тестовими даними
INSERT INTO residents (full_name, address, has_benefits) VALUES
('Іваненко Іван Іванович', 'вул. Шевченка 1, кв 2', TRUE),
('Петренко Петро Петрович', 'вул. Франка 5, кв 10', FALSE),
('Сидоренко Анна', 'вул. Лесі Українки 12, кв 3', FALSE);

INSERT INTO services (service_name, category) VALUES
('Електроенергія', 'Енергетика'),
('Водопостачання', 'Водоканал'),
('Опалення', 'Тепломережа');

INSERT INTO bills (resident_id, service_id, billing_month, amount, has_penalty) VALUES
(1, 1, '2023-10-01', 450.00, FALSE),
(2, 2, '2023-10-01', 320.50, TRUE),
(3, 3, '2023-10-01', 1200.00, FALSE),
(1, 2, '2023-10-01', 210.00, FALSE);

INSERT INTO payments (bill_id, payment_date, amount, payment_method, status) VALUES
(1, '2023-10-15', 450.00, 'online', 'completed'),
(2, '2023-10-20', 100.00, 'bank', 'completed'), --часткова оплата, заборгованість
(3, '2023-10-18', 1200.00, 'online', 'refunded'),
(4, '2023-10-15', 210.00, 'cash', 'completed');
--Тестові запити--
--1) Виведемо всі унікальні методи оплати (наприклад, онлайн, готівка, банк), які використовувалися.
SELECT DISTINCT payment_method 
FROM payments;
--2) Знайдемо найбільшу та найменшу суму серед усіх виставлених рахунків.
SELECT 
    MAX(amount) AS max_bill_amount, 
    MIN(amount) AS min_bill_amount 
FROM bills;
--3) Рахуємо середню кількість виставлених рахунків на одного мешканця.
SELECT AVG(bill_count) AS avg_bills_per_resident
FROM (
    SELECT resident_id, COUNT(id) AS bill_count
    FROM bills
    GROUP BY resident_id
) AS subquery;
--4) Порахуємо, скільки всього успішних транзакцій (оплат) було здійснено.
SELECT COUNT(*) AS successful_payments_count 
FROM payments 
WHERE status = 'completed';
--5) Підрахуємо загальну суму всіх успішних платежів, що надійшли в систему.
SELECT SUM(amount) AS total_transactions_sum 
FROM payments 
WHERE status = 'completed';