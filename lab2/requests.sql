-- 1. Які рахунки є в системі? 
SELECT * FROM bills;

-- 2. Скільки мешканців оплатили комунальні послуги в цьому місяці?
SELECT COUNT(DISTINCT b.resident_id) AS paid_residents_count
FROM payments p
JOIN bills b ON p.bill_id = b.id
WHERE EXTRACT(MONTH FROM p.payment_date) = 10 AND p.status = 'completed';

-- 3. Яка середня сума комунальних платежів за місяць?
SELECT DATE_TRUNC('month', payment_date) AS month, AVG(amount) AS avg_payment
FROM payments
WHERE status = 'completed'
GROUP BY DATE_TRUNC('month', payment_date);

-- 4. Які мешканці мають заборгованість по оплаті?
SELECT r.full_name, b.amount AS billed, COALESCE(SUM(p.amount), 0) AS paid
FROM residents r
JOIN bills b ON r.id = b.resident_id
LEFT JOIN payments p ON b.id = p.bill_id AND p.status = 'completed'
GROUP BY r.id, r.full_name, b.id, b.amount
HAVING b.amount > COALESCE(SUM(p.amount), 0);

-- 5. Які записи містять інформацію про повернення коштів?
SELECT * FROM payments 
WHERE status = 'refunded';

-- 6. Яка кількість оплат була здійснена через онлайн-методи?
SELECT COUNT(*) AS online_payments_count 
FROM payments 
WHERE payment_method = 'online' AND status = 'completed';

-- 7. Яка кількість мешканців отримала штрафи за несвоєчасну оплату?
SELECT COUNT(DISTINCT resident_id) AS penalized_residents_count 
FROM bills 
WHERE has_penalty = TRUE;

-- 8. Які послуги були найбільше оплачені?
SELECT s.service_name, SUM(p.amount) AS total_paid
FROM payments p
JOIN bills b ON p.bill_id = b.id
JOIN services s ON b.service_id = s.id
WHERE p.status = 'completed'
GROUP BY s.service_name
ORDER BY total_paid DESC;

-- 9. Яка сума загальних платежів по кожній категорії послуг?
SELECT s.category, SUM(p.amount) AS total_paid
FROM payments p
JOIN bills b ON p.bill_id = b.id
JOIN services s ON b.service_id = s.id
WHERE p.status = 'completed'
GROUP BY s.category;

-- 10. Скільки осіб мають платіжні пільги?
SELECT COUNT(*) AS residents_with_benefits 
FROM residents 
WHERE has_benefits = TRUE;