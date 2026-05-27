{{
  config(
    materialized='view'
  )
}}

select
    member_id,
    first_name,
    last_name,
    date_of_birth,
    death_date,
    case when death_date is null then true else false end as is_active,
    gender,
    race,
    ethnicity,
    marital_status,
    address,
    city,
    state,
    county,
    zip,
    healthcare_expenses,
    healthcare_coverage,
    income,
    dbx_load_time as last_updated_at
from {{ source('silver', 'patients') }}
