-- Win rate by stage entry. This model counts opportunities — not amounts —
-- so it is less directly affected by the cardinality change. However,
-- if the migration causes duplicate opportunity records, opportunity_count
-- and won_count could be inflated.

with closed_opportunities as (
    select
        opportunity_id,
        account_id,
        stage,
        is_won,
        close_date,
        date_part('year', close_date)       as close_year,
        date_trunc('quarter', close_date)   as close_quarter
    from {{ ref('stg_opportunities') }}
    where is_closed = true
),

accounts as (
    select account_id, tier
    from {{ ref('stg_accounts') }}
),

joined as (
    select
        o.stage,
        o.is_won,
        o.close_year,
        o.close_quarter,
        a.tier
    from closed_opportunities o
    left join accounts a on o.account_id = a.account_id
)

select
    close_year,
    close_quarter,
    tier,
    count(*)                                                    as opportunity_count,
    sum(case when is_won then 1 else 0 end)                    as won_count,
    round(
        sum(case when is_won then 1 else 0 end)::decimal
        / nullif(count(*), 0) * 100,
        1
    )                                                           as win_rate_pct
from joined
group by close_year, close_quarter, tier
order by close_year, close_quarter, tier
