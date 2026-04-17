with source as (
    select * from {{ ref('raw_opportunities') }}
),

renamed as (
    select
        opportunity_id,
        account_id,
        name                                    as opportunity_name,
        stage,
        amount                                  as total_value,
        cast(close_date as date)                as close_date,
        cast(created_at as timestamp)           as created_at,

        stage = 'Closed Won'                    as is_won,
        stage in ('Closed Won', 'Closed Lost')  as is_closed

    from source
)

select * from renamed
