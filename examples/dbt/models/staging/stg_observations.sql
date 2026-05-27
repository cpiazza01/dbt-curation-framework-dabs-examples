{{
  config(
    materialized='view'
  )
}}

select
    member_id,
    encounter_id,
    observation_ts::date as observation_date,
    category,
    loinc_code,
    description,
    value,
    units,
    type as observation_type,
    dbx_load_time as last_updated_at
from {{ source('silver', 'observations') }}
where value is not null
