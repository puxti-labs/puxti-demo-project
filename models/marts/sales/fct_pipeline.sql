-- This model aggregates open pipeline by stage and account tier.
-- It sums stg_opportunities.total_value — the same field that breaks after
-- the Salesforce migration. Once opportunities have multiple order lines,
-- total_value no longer represents full deal value and pipeline totals
-- reported here will be understated.

with open_opportunities as (
    select
        o.opportunity_id,
        o.account_id,
        o.stage,
        o.total_value,
        o.close_date,
        o.created_at
    from {{ ref('stg_opportunities') }} o
    where o.is_closed = false
),

accounts as (
    select
        account_id,
        tier
    from {{ ref('stg_accounts') }}
),

joined as (
    select
        o.opportunity_id,
        o.stage,
        o.total_value,
        o.close_date,
        a.tier
    from open_opportunities o
    left join accounts a on o.account_id = a.account_id
)

select
    stage,
    tier,
    count(opportunity_id)   as opportunity_count,
    sum(total_value)        as pipeline_value,
    avg(total_value)        as avg_deal_size
from joined
group by stage, tier
order by stage, tier
