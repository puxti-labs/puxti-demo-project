with source as (
    select * from {{ ref('raw_order_lines') }}
),

renamed as (
    select
        order_line_id,
        opportunity_id,
        product_name,
        quantity,
        unit_price,
        total_price,
        cast(created_at as timestamp)   as created_at
    from source
)

select * from renamed
