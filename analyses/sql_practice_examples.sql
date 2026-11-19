-- analyses/ are compiled by dbt but never run: a good place for practice queries.
-- dbt compile, then open target/compiled/... and run it in Snowsight.

-- 1. Top 3 suppliers by spend in each level-1 category (window function + QUALIFY)
select c.l1_category_name, s.supplier_name, round(sum(f.amount_eur), 0) as spend_eur
from {{ ref('fct_spend') }} f
join {{ ref('dim_supplier') }} s on s.supplier_id = f.supplier_id
join {{ ref('dim_category') }} c on c.category_id = f.category_id
group by 1, 2
qualify dense_rank() over (partition by c.l1_category_name order by sum(f.amount_eur) desc) <= 3
order by 1, 3 desc
