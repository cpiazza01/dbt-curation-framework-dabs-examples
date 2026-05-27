{{
  config(
    materialized='view'
  )
}}

select
    provider_id,
    organization_id,
    provider_name,
    gender,
    specialty,
    address,
    city,
    state,
    zip_code as zip,
    encounter_count as total_encounters,
    procedure_count as total_procedures,
    dbx_load_time as last_updated_at
from {{ source('silver', 'providers') }}
where __END_AT IS NULL
