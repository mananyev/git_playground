with
revenue as (
    select
        extract(year FROM cast(pickup_datetime as timestamp)) as year,
        extract(quarter FROM cast(pickup_datetime as timestamp)) as quarter,
        service_type,
        sum(total_amount) as quarterly_revenue
    from {{ ref('fact_trips') }}
    group by
        year,
        quarter,
        service_type

)
select
    revenue.*,
    100.0 * (
        revenue.quarterly_revenue - prev_year.quarterly_revenue
    ) / prev_year.quarterly_revenue as yoy_growth,
    revenue.quarterly_revenue / prev_year.quarterly_revenue as yoy_growth_fixed
from revenue
    left join revenue prev_year
        on revenue.service_type = prev_year.service_type
        and revenue.quarter = prev_year.quarter
        and revenue.year = prev_year.year + 1
