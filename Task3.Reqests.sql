/* 1. Вывести количество фильмов в каждой категории, отсортировать по убыванию*/

select count(pc.category_id), pc.name
from public.category as pc 
	join public.film_category as fc
	on pc.category_id=fc.category_id
group by pc.name
order by count(pc.category_id) desc


/* 2. Вывести 10 актеров, чьи фильмы большего всего арендовали, отсортировать по убыванию*/

--1 вариант
select * 
from (select a.last_name, a.first_name, sum(f.rental_duration) as sum,
	row_number() over (order by sum(f.rental_duration) desc) as row_number
from public.actor a 
INNER JOIN  public.film_actor fa
ON a.actor_id=fa.actor_id
INNER JOIN public.film f
ON fa.film_id=f.film_id
Group by a.first_name, a.last_name
order by sum(f.rental_duration) desc
	  )t
where row_number <=10


--2 вариант
select distinct a.last_name, a.first_name, sum(f.rental_duration) as sum
from public.actor a 
INNER JOIN  public.film_actor fa
ON a.actor_id=fa.actor_id
INNER JOIN public.film f
ON fa.film_id=f.film_id
group by a.last_name, a.first_name
order by sum(f.rental_duration) desc
limit 10


/* 3. Вывести категорию фильмов, на которую потратили больше всего денег*/

select c.name, sum(p.amount) as sum
from public.category c 
inner join public.film_category fc
	on c.category_id=fc.category_id
inner join public.inventory i
	on fc.film_id=i.film_id
inner join public.rental r
	on i.inventory_id=r.inventory_id
inner join public.payment p
	on r.rental_id=p.rental_id
group by c.name
limit 1


/* 4.Вывести названия фильмов, которых нет в inventory. Написать запрос без использования оператора IN*/

-- 1 способ
WITH name_title AS (
	SELECT film_id
	FROM public.film 
	EXCEPT
		SELECT i.film_id
		FROM public.inventory i
		INNER JOIN public.film f
			ON f.film_id=i.film_id
	ORDER BY 1 ASC
)
SELECT p.film_id, p.title
FROM public.film p
JOIN name_title t
ON p.film_id=t.film_id


-- 2 способ
SELECT f.title
FROM public.film f 
LEFT JOIN public.inventory i
		ON f.film_id=i.film_id
WHERE i.inventory_id IS NULL


/* 5.Вывести топ 3 актеров, которые больше всего появлялись в фильмах в категории “Children”. 
Если у нескольких актеров одинаковое кол-во фильмов, вывести всех*/

SELECT *
FROM public.actor

SELECT *
FROM public.category

SELECT *
FROM (SELECT COUNT(a.actor_id) as count, a.first_name, a.last_name, c.name,
DENSE_RANK () OVER (ORDER BY(COUNT(a.actor_id)) DESC) AS rank
FROM public.category c
JOIN public.film_category fc
ON c.category_id=fc.category_id
JOIN public.film_actor fa
ON fc.film_id=fa.film_id
JOIN public.actor a
ON fa.actor_id=a.actor_id
WHERE c.name = 'Children'
GROUP BY a.first_name, a.last_name, c.name
)t
WHERE rank <=3


/* 6. Вывести города с количеством активных и неактивных клиентов (активный — customer.active = 1). 
Отсортировать по количеству неактивных клиентов по убыванию*/

select a.district, 
       count(case when cs.active = '1' then cs.customer_id end) as Active,
       count(case when cs.active = '0' then cs.customer_id end) as NOactive
from public.customer cs
	join public.address a
	ON a.address_id=cs.address_id
	join public.city ct
	ON a.city_id=ct.city_id
group by a.district, cs.active
order by NOactive desc


/* 7.Вывести категорию фильмов, у которой самое большое кол-во часов суммарной аренды в городах 
(customer.address_id в этом city), и которые начинаются на букву “a”. То же самое сделать для городов 
в которых есть символ “-”. Написать все в одном запросе*/


-- 1 вариант

select ctg.name, c.city,
	   count(cst.address_id) 
from public.category ctg
join public.film_category fc
	on ctg.category_id=fc.category_id
join public.inventory i
	on fc.film_id=i.film_id
join public.customer cst
	on i.store_id=cst.store_id
join public.address a
	on cst.address_id=a.address_id
join public.city c
	ON a.city_id=c.city_id
where c.city like 'a%' or c.city like '%-%'
group by ctg.name, c.city
order by count(cst.address_id) desc
--limit 1


-- 2 вариант

select *
from (select ctg.name, c.city, count(cst.address_id), 
	   row_number() over (order by count(cst.address_id) desc) as r
from public.category ctg
join public.film_category fc
	on ctg.category_id=fc.category_id
join public.inventory i
	on fc.film_id=i.film_id
join public.customer cst
	on i.store_id=cst.store_id
join public.address a
	on cst.address_id=a.address_id
join public.city c
	ON a.city_id=c.city_id
where c.city like 'a%' or c.city like '%-%'
group by ctg.name, c.city
	 ) t
--where r = 1
