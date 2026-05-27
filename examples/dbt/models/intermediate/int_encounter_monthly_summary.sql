{{
  config(
    materialized='table'
  )
}}

select
    date_trunc('month', encounter_start_ts) as encounter_month,
    encounter_class,
    count(distinct encounter_id)                    as encounter_count,
    count(distinct member_id)                       as unique_members,
    count(distinct provider_id)                     as unique_providers,
    sum(total_claim_cost)                           as total_claim_cost,
    sum(payer_coverage)                             as total_payer_coverage,
    sum(member_responsibility)                      as total_member_responsibility,
    avg(total_claim_cost)                           as avg_claim_cost,
    avg(encounter_duration_days)                    as avg_encounter_duration_days
from {{ ref('stg_encounters') }}
group by
    date_trunc('month', encounter_start_ts),
    encounter_class
