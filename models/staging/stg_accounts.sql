with source as (
    select * from {{ ref('raw_accounts') }}
),

renamed as (
    select
        account_id,
        name                            as account_name,
        industry,
        arr,
        tier,
        cast(created_at as timestamp)   as created_at
    from source
)

select * from renamed
