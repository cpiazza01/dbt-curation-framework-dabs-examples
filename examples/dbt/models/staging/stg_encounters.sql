{{
  config(
    materialized='view'
  )
}}

select
    encounter_id,
    member_id,
    organization_id,
    provider_id,
    payer_id,
    encounter_class,
    encounter_code,
    encounter_description,
    encounter_start_ts,
    encounter_end_ts,
    base_encounter_cost,
    total_claim_cost,
    payer_coverage,
    total_claim_cost - payer_coverage as member_responsibility,
    reason_code,
    reason_description,
    case
        when encounter_end_ts is not null
        then datediff(hour, encounter_start_ts, encounter_end_ts) / 24.0
        else null
    end as encounter_duration_days,
    dbx_load_time as last_updated_at
from {{ source('silver', 'encounters') }}
where encounter_start_ts is not null
