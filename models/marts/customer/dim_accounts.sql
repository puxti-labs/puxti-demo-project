-- Account dimension — unaffected by the opportunity cardinality change.
-- This model joins account attributes with subscription status only.
-- It does not reference opportunities or order lines.

with accounts as (
    select * from {{ ref('stg_accounts') }}
),

subscriptions as (
    select
        account_id,
        sum(case when is_active then mrr else 0 end)    as active_mrr,
        sum(case when is_active then arr else 0 end)    as active_arr,
        count(case when is_active then 1 end)           as active_subscription_count,
        max(case when is_active then plan end)          as current_plan,
        max(start_date)                                 as latest_subscription_start
    from {{ ref('stg_subscriptions') }}
    group by account_id
)

select
    a.account_id,
    a.account_name,
    a.industry,
    a.tier,
    a.arr                                           as crm_arr,
    coalesce(s.active_mrr, 0)                       as active_mrr,
    coalesce(s.active_arr, 0)                       as billing_arr,
    coalesce(s.active_subscription_count, 0)        as active_subscription_count,
    s.current_plan,
    s.latest_subscription_start,
    s.active_subscription_count > 0                 as is_customer,
    a.created_at
from accounts a
left join subscriptions s on a.account_id = s.account_id
