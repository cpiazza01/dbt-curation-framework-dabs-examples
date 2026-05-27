{{
  config(
    materialized='table'
  )
}}

select
    e.provider_id,
    p.provider_name,
    p.specialty,
    p.city,
    p.state,
    count(distinct e.encounter_id)                  as total_encounters,
    count(distinct e.member_id)                     as unique_members,
    sum(e.total_claim_cost)                         as total_claim_cost,
    avg(e.total_claim_cost)                         as avg_claim_cost,
    avg(e.encounter_duration_days)                  as avg_encounter_duration_days,
    -- Recent activity (last 12 months)
    count(distinct case
        when e.encounter_start_ts >= dateadd(month, -12, current_timestamp())
        then e.encounter_id
    end) as encounters_last_12_months,
    sum(case
        when e.encounter_start_ts >= dateadd(month, -12, current_timestamp())
        then e.total_claim_cost else 0
    end) as cost_last_12_months
from {{ ref('stg_encounters') }} e
left join {{ ref('stg_providers') }} p
    on e.provider_id = p.provider_id
group by
    e.provider_id,
    p.provider_name,
    p.specialty,
    p.city,
    p.state
