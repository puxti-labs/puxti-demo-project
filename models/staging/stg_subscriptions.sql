with source as (
    select * from {{ ref('raw_subscriptions') }}
),

renamed as (
    select
        subscription_id,
        account_id,
        plan,
        mrr,
        mrr * 12                            as arr,
        cast(start_date as date)            as start_date,
        cast(end_date as date)              as end_date,
        status,
        status = 'active'                   as is_active
    from source
)

select * from renamed
