-- 1. СТВОРЕННЯ КОРИСТУВАЦЬКОГО ТИПУ ДАНИХ (ENUM)
-- Створюємо тип для статусів платежу, щоб обмежити можливі значення
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');

-- Змінюємо тип існуючого стовпця status у таблиці payments з VARCHAR на новий ENUM
ALTER TABLE payments 
ALTER COLUMN status DROP DEFAULT,
ALTER COLUMN status TYPE payment_status USING status::payment_status,
ALTER COLUMN status SET DEFAULT 'completed';



-- 2. СТВОРЕННЯ КОРИСТУВАЦЬКОЇ ФУНКЦІЇ
-- Функція для розрахунку загальної суми боргу конкретного мешканця
CREATE OR REPLACE FUNCTION calculate_resident_debt(p_resident_id INT) 
RETURNS NUMERIC AS $$
DECLARE
    total_billed NUMERIC;
    total_paid NUMERIC;
BEGIN
    -- Рахуємо загальну суму виставлених рахунків
    SELECT COALESCE(SUM(amount), 0) INTO total_billed 
    FROM bills WHERE resident_id = p_resident_id;
    
    -- Рахуємо загальну суму успішних оплат
    SELECT COALESCE(SUM(p.amount), 0) INTO total_paid
    FROM payments p
    JOIN bills b ON p.bill_id = b.id
    WHERE b.resident_id = p_resident_id AND p.status = 'completed';

    -- Повертаємо різницю
    RETURN total_billed - total_paid;
END;
$$ LANGUAGE plpgsql;


-- 3. СТВОРЕННЯ ТРИГЕРІВ
-- 3.1. Тригер для логування змін у таблиці платежів
CREATE TABLE payments_log (
    log_id SERIAL PRIMARY KEY,
    payment_id INT,
    operation VARCHAR(10),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_payment_changes() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO payments_log (payment_id, operation) VALUES (OLD.id, TG_OP);
        RETURN OLD;
    ELSE
        INSERT INTO payments_log (payment_id, operation) VALUES (NEW.id, TG_OP);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER track_payment_changes
AFTER INSERT OR UPDATE OR DELETE ON payments
FOR EACH ROW EXECUTE FUNCTION log_payment_changes();

-- 3.2. Тригер для автоматичного оновлення пов'язаних таблиць
-- Додаємо нове поле "Оплачена сума" до рахунків, щоб мінімізувати дублювання обчислень
ALTER TABLE bills ADD COLUMN paid_amount DECIMAL(10, 2) DEFAULT 0.00;

-- Функція тригера: автоматично додає суму платежу до paid_amount у відповідному рахунку
CREATE OR REPLACE FUNCTION update_bill_paid_amount() RETURNS TRIGGER AS $$
BEGIN
    -- Якщо додано новий успішний платіж
    IF (TG_OP = 'INSERT' AND NEW.status = 'completed') THEN
        UPDATE bills SET paid_amount = paid_amount + NEW.amount WHERE id = NEW.bill_id;
    -- Якщо статус платежу змінено на успішний
    ELSIF (TG_OP = 'UPDATE' AND NEW.status = 'completed' AND OLD.status != 'completed') THEN
        UPDATE bills SET paid_amount = paid_amount + NEW.amount WHERE id = NEW.bill_id;
    -- Якщо статус успішного платежу скасовано (наприклад, refunded)
    ELSIF (TG_OP = 'UPDATE' AND NEW.status != 'completed' AND OLD.status = 'completed') THEN
        UPDATE bills SET paid_amount = paid_amount - OLD.amount WHERE id = NEW.bill_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_bill_paid_amount
AFTER INSERT OR UPDATE ON payments
FOR EACH ROW EXECUTE FUNCTION update_bill_paid_amount();


-- 4. ПЕРЕВІРКА РОБОТИ (ТЕСТОВІ ЗАПИТИ)
-- Тест 1: Перевірка роботи тригера логування та автооновлення рахунку
-- Додаємо новий платіж для рахунку з id = 1
INSERT INTO payments (bill_id, payment_date, amount, payment_method, status) 
VALUES (1, CURRENT_DATE, 50.00, 'online', 'completed');

-- Перевіряємо лог (повинен з'явитися запис з operation = 'INSERT')
SELECT * FROM payments_log;

-- Перевіряємо, чи оновилося поле paid_amount у таблиці bills для рахунку 1
SELECT id, amount AS total_billed, paid_amount FROM bills WHERE id = 1;

-- Тест 2: Перевірка користувацької функції
-- Розраховуємо борг для мешканця з id = 2
SELECT full_name, calculate_resident_debt(id) AS current_debt 
FROM residents WHERE id = 2;

-- Тест 3: Перевірка ENUM та оновлення статусу (викличе тригери)
UPDATE payments SET status = 'refunded' WHERE id = (SELECT MAX(id) FROM payments);

-- Знову перевіряємо лог (має з'явитися 'UPDATE') та рахунок (paid_amount має зменшитись)
SELECT * FROM payments_log;
SELECT id, amount AS total_billed, paid_amount FROM bills WHERE id = 1;