SELECT 
    c.full_name AS "Клієнт",
    s.title AS "Абонемент",
    t.name AS "Тренер",
    t.specialty AS "Напрямок"
FROM clients c
JOIN subscriptions s ON c.subscription_id = s.subscription_id
JOIN trainers t ON c.trainer_id = t.trainer_id;