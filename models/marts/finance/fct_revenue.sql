-- NOTE: this model assumes one amount per opportunity.
-- Will break if opportunity structure changes.
--
-- After the Salesforce migration, each opportunity has multiple order lines.
-- Joining stg_opportunities directly and summing total_value now produces
-- inflated revenue because the same opportunity_id appears in multiple rows
-- in stg_order_lines — but this model never looks at order lines at all.
-- The fix is to sum stg_order_lines.total_price grouped by opportunity_id
-- instead of reading amount from stg_opportunities.

with won_opportunities as (
    select
        o.opportunity_id,
        o.account_id,
        o.opportunity_name,
        o.total_value,
        o.close_date
    from {{ ref('stg_opportunities') }} o
    where o.is_won = true
),

accounts as (
    select
        account_id,
        account_name,
        industry,
        tier
    from {{ ref('stg_accounts') }}
),

joined as (
    select
        o.opportunity_id,
        o.opportunity_name,
        o.close_date,
        o.total_value,
        a.account_id,
        a.account_name,
        a.industry,
        a.tier,
        date_trunc('month', o.close_date)   as close_month,
        date_trunc('quarter', o.close_date) as close_quarter,
        date_part('year', o.close_date)     as close_year
    from won_opportunities o
    left join accounts a on o.account_id = a.account_id
)

select
    *,
    sum(total_value) over (
        partition by close_month
    )                                       as monthly_revenue,
    sum(total_value) over (
        partition by close_quarter
    )                                       as quarterly_revenue
from joined
