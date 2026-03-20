PRAGMA table_info(facebook);
--1 Avg engagement by credibility group
SELECT
  CASE
    WHEN LOWER(TRIM(Rating)) IN ('true','no factual content')
    THEN 'Human_Content'
    ELSE 'AI_Like_Content'
  END AS content_group,

  AVG(reaction_count + comment_count + share_count) AS avg_engagement

FROM facebook
GROUP BY content_group;
--2. Total posts in each group
SELECT
  CASE
    WHEN LOWER(TRIM(Rating)) IN ('true','no factual content')
    THEN 'Human_Content'
    ELSE 'AI_Like_Content'
  END AS content_group,
  COUNT(*) AS total_posts
FROM facebook
GROUP BY content_group;
--3. Overall average engagement
SELECT
  AVG(reaction_count + comment_count + share_count) AS overall_avg_engagement
FROM facebook;
--4.Engagement by Page (publisher)
SELECT
  Page,
  AVG(reaction_count + comment_count + share_count) AS avg_engagement
FROM facebook
GROUP BY Page
ORDER BY avg_engagement DESC;
--5.Engagement by Category
SELECT
  Category,
  AVG(reaction_count + comment_count + share_count) AS avg_engagement
FROM facebook
GROUP BY Category
ORDER BY avg_engagement DESC;
--6.Engagement by Post Type
SELECT
  "Post Type",
  AVG(reaction_count + comment_count + share_count) AS avg_engagement
FROM facebook
GROUP BY "Post Type"
ORDER BY avg_engagement DESC;
--7.Top 10 most engaging posts
SELECT
  post_id,
  Page,
  "Post URL",
  (reaction_count + comment_count + share_count) AS total_engagement
FROM facebook
ORDER BY total_engagement DESC
LIMIT 10;
--8.Avg shares by credibility group
SELECT
  CASE
    WHEN LOWER(TRIM(Rating)) IN ('true','no factual content')
    THEN 'Human_Content'
    ELSE 'AI_Like_Content'
  END AS content_group,
  AVG(share_count) AS avg_shares
FROM facebook
GROUP BY content_group;
--9.Avg comments by credibility group
SELECT
  CASE
    WHEN LOWER(TRIM(Rating)) IN ('true','no factual content')
    THEN 'Human_Content'
    ELSE 'AI_Like_Content'
  END AS content_group,
  AVG(comment_count) AS avg_comments
FROM facebook
GROUP BY content_group;
--10.Posts with zero engagement
SELECT COUNT(*) AS zero_engagement_posts
FROM facebook
WHERE (reaction_count + comment_count + share_count) = 0;
--11.Highest discussion posts (top comments)
SELECT
  post_id,
  Page,
  comment_count
FROM facebook
ORDER BY comment_count DESC
LIMIT 10;
--12. Engagement by weekday
SELECT
  STRFTIME('%w', "Date Published") AS weekday,
  AVG(reaction_count + comment_count + share_count) AS avg_engagement
FROM facebook
GROUP BY weekday;
--13.% engagement driven by AI-like content
SELECT
  SUM(CASE WHEN LOWER(TRIM(Rating)) NOT IN ('true','no factual content')
           THEN (reaction_count + comment_count + share_count)
           ELSE 0 END) * 1.0
  / SUM(reaction_count + comment_count + share_count) AS ai_engagement_share
FROM facebook;
--14.Engagement buckets (Low/Medium/High)
SELECT
  CASE
    WHEN (reaction_count + comment_count + share_count) < 50 THEN 'Low'
    WHEN (reaction_count + comment_count + share_count) < 200 THEN 'Medium'
    ELSE 'High'
  END AS engagement_bucket,
  COUNT(*) AS posts
FROM facebook
GROUP BY engagement_bucket;
--15 High-risk viral misinformation posts
SELECT
  post_id,
  Page,
  Rating,
  (share_count * 1.0 / (reaction_count + 1)) AS virality_score
FROM facebook
WHERE LOWER(TRIM(Rating)) NOT IN ('true','no factual content')
  AND (share_count * 1.0 / (reaction_count + 1)) > 1
ORDER BY virality_score DESC;
--16.Risky content count by Page
SELECT
  Page,
  COUNT(*) AS risky_posts
FROM facebook
WHERE LOWER(TRIM(Rating)) NOT IN ('true','no factual content')
GROUP BY Page
ORDER BY risky_posts DESC;
--17. Engagement per post (efficiency)
SELECT
  Page,
  SUM(reaction_count + comment_count + share_count) * 1.0 / COUNT(*) AS engagement_per_post
FROM facebook
GROUP BY Page;
--Monthly engagement trend
SELECT
  STRFTIME('%Y-%m', "Date Published") AS month,
  AVG(reaction_count + comment_count + share_count) AS avg_engagement
FROM facebook
GROUP BY month
ORDER BY month;
--19.Monthly volume of risky content
SELECT
  STRFTIME('%Y-%m', "Date Published") AS month,
  COUNT(*) AS risky_posts
FROM facebook
WHERE LOWER(TRIM(Rating)) NOT IN ('true','no factual content')
GROUP BY month;
--20 Debate vs engagement relationship
SELECT
  Debate,
  AVG(reaction_count + comment_count + share_count) AS avg_engagement
FROM facebook
GROUP BY Debate;
--21.Posts with high engagement but low virality
SELECT
  post_id,
  Page
FROM facebook
WHERE (reaction_count + comment_count + share_count) > 200
  AND (share_count * 1.0 / (reaction_count + 1)) < 0.2;
--22.Rank posts within each Rating group
SELECT
  post_id,
  Rating,
  (reaction_count + comment_count + share_count) AS total_engagement,
  RANK() OVER (
    PARTITION BY Rating
    ORDER BY (reaction_count + comment_count + share_count) DESC
  ) AS rank_in_rating
FROM facebook;
--23. Top 10% engagement posts
SELECT *
FROM (
  SELECT
    post_id,
    (reaction_count + comment_count + share_count) AS total_engagement,
    PERCENT_RANK() OVER (
      ORDER BY (reaction_count + comment_count + share_count)
    ) AS pr
  FROM facebook
)
WHERE pr >= 0.9;
--24..Engagement share contribution per post
SELECT
  post_id,
  (reaction_count + comment_count + share_count) AS total_engagement,
  (reaction_count + comment_count + share_count) * 1.0 /
  SUM(reaction_count + comment_count + share_count) OVER () AS engagement_share
FROM facebook;
--25.Rolling 7-day engagement trend

SELECT
  DATE("Date Published") AS day,
  AVG(reaction_count + comment_count + share_count) AS daily_avg,
  AVG(AVG(reaction_count + comment_count + share_count)) OVER (
    ORDER BY DATE("Date Published")
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS rolling_7_day_avg
FROM facebook
GROUP BY day;

--26.. Engagement quartiles
SELECT
  post_id,
  NTILE(4) OVER (
    ORDER BY (reaction_count + comment_count + share_count) DESC
  ) AS engagement_quartile
FROM facebook;
--27..Top post per Page

SELECT *
FROM (
  SELECT
    post_id,
    Page,
    (reaction_count + comment_count + share_count) AS total_engagement,
    RANK() OVER (
      PARTITION BY Page
      ORDER BY (reaction_count + comment_count + share_count) DESC
    ) AS page_rank
  FROM facebook
)
WHERE page_rank = 1;
--28High-risk posts inside top engagement tier
SELECT *
FROM (
  SELECT
    post_id,
    Rating,
    (reaction_count + comment_count + share_count) AS total_engagement,
    NTILE(3) OVER (
      ORDER BY (reaction_count + comment_count + share_count) DESC
    ) AS tier
  FROM facebook
)
WHERE tier = 1
  AND LOWER(TRIM(Rating)) NOT IN ('true','no factual content');

--
--29Rank posts by engagement within each Page
SELECT
  post_id,
  Page,
  (reaction_count + comment_count + share_count) AS total_engagement,
  RANK() OVER (
    PARTITION BY Page
    ORDER BY (reaction_count + comment_count + share_count) DESC
  ) AS rank_on_page
FROM facebook;

--30 .High-risk posts inside top engagement tier
WITH ranked_posts AS (
  SELECT
    post_id,
    Rating,
    (reaction_count + comment_count + share_count) AS total_engagement,
    NTILE(3) OVER (
      ORDER BY (reaction_count + comment_count + share_count) DESC
    ) AS tier
  FROM facebook
)

SELECT *
FROM ranked_posts
WHERE tier = 1
  AND LOWER(TRIM(Rating)) NOT IN ('true','no factual content');

--31 31. Publisher performance above platform average
WITH platform_avg AS (
  SELECT
    AVG(reaction_count + comment_count + share_count) AS avg_engagement
  FROM facebook
)

SELECT
  Page,
  AVG(reaction_count + comment_count + share_count) AS page_avg
FROM facebook, platform_avg
GROUP BY Page
HAVING page_avg > avg_engagement;
--32 32 Monthly misinformation engagement share
WITH monthly AS (
  SELECT
    STRFTIME('%Y-%m', "Date Published") AS month,
    SUM(reaction_count + comment_count + share_count) AS total_engagement,
    SUM(CASE
          WHEN LOWER(TRIM(Rating)) NOT IN ('true','no factual content')
          THEN (reaction_count + comment_count + share_count)
          ELSE 0
        END) AS misleading_engagement
  FROM facebook
  GROUP BY month
)

SELECT
  month,
  misleading_engagement * 1.0 / total_engagement AS misinformation_share
FROM monthly
ORDER BY month;







