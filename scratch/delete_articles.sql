WITH RankedArticles AS (
    SELECT a.id,
           ROW_NUMBER() OVER(PARTITION BY d.region ORDER BY a.published_at DESC NULLS LAST, a.created_at DESC) as rnk
    FROM content_articles a
    JOIN destinations d ON a.destination_id = d.id
)
DELETE FROM content_articles
WHERE id IN (
    SELECT id FROM RankedArticles WHERE rnk > 5
);
