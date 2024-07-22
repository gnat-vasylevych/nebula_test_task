-- #1
-- Кількість чатів в залежності від рівня астролога;

select astrologer_level, count(*) as total_chats from
chats inner join astrologers on chats.astrologer_id = astrologers.astrologer_id
group by astrologer_level 


-- #2
-- Ім'я астролога, кількість користувачів, які з ним спілкувалися, 
-- кількість чатів з максимальною оцінкою та максимальну тривалість чату з астрологом;

-- I assume `astrologer_name` is not unique.
-- Therefore I will use `astrologer_id` as a unique identifier.

-- I assume that 'кількість користувачів, які з ним спілкувалися' means only unique users.
-- If the astrologer had several chats with the same user, I should count this user only once. 

with total_customers as (
  select astrologer_id, count(distinct user_id) as num_users, max(session_duration) as max_duration
  from chats 
  group by astrologer_id
),

max_rate_chats as (
  select astrologer_id, count(*) num_rate_chats from
  ratings inner join chats on ratings.chat_id = chats.chat_id
  where rating = 5
  group by astrologer_id
),

-- There may be chats with no rating, or some astrologers with no rated chats at all.
max_rate_astrologers as (
  select astrologer_id, astrologer_name, COALESCE(num_rate_chats, 0) num_max_rate_chats
  from astrologers a left join max_rate_chats r on a.astrologer_id = r.astrologer_id
)

select c.astrologer_id, astrologer_name, num_users, num_max_rate_chats, max_duration
from total_customers c join max_rate_astrologers r on c.astrologer_id = r.astrologer_id


-- #3
-- Ім'я астролога, середній рейтинг астролога, суму зароблених ним грошей та
-- долю його заробітку від усієї заробленої суми. 
-- Обмежте результат виконання запиту п'ятьма астрологами, доля заробітку яких була найвища.

with chat_price as (
  select
  chat_id,
  (session_duration * price) chat_price
  from chats c inner join astrologers a on c.astrologer_id = a.astrologer_id
  inner join chat_pricing p on a.astrologer_level = p.astrologer_level
),

astrologer_money as (
  select
  astrologer_id, sum(chat_price) as astrologer_money
  from chat_price
  group by astrologer_id
),

SET @all_money = (select sum(chat_price) from chat_price);


avg_rating as (
  select 
  astrologer_id, avg(rating) avg_rating
  from chats c inner join ratings r on c.chat_id = r.chat_id
  group by astrologer_id
),

percentage_earned as (
  select
  astrologer_id,
  round((astrologer_money / select @all_money ) * 100, 2) percentage_earned 
  from astrologer_money
)

select 
  r.astrologer_id, astrologer_name, astrologer_money, percentage_earned
  from avg_rating r inner join astrologer_money m on r.astrologer_id = m.astrologer_id
  inner join percentage_earned p on r.astrologer_id = p.astrologer_id
  inner join astrologers a on r.astrologer_id = a.astrologer_id
  order by percentage_earned desc
  limit 5