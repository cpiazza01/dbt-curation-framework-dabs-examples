{{
  config(
    materialized='table',
    tags=['provider', 'analytics']
  )
}}

with provider_metrics as (
    select * from {{ ref('int_provider_current_metrics') }}
),

specialty_benchmarks as (
    select
        specialty,
        avg(avg_claim_cost)             as specialty_avg_claim_cost,
        avg(avg_encounter_duration_days) as specialty_avg_encounter_duration_days,
        avg(encounters_last_12_months)  as specialty_avg_encounters_last_12_months
    from provider_metrics
    group by specialty
)

select
    p.provider_id,
    p.provider_name,
    p.specialty,
    p.city,
    p.state,
    p.total_encounters,
    p.unique_members,
    p.total_claim_cost,
    p.avg_claim_cost,
    p.avg_encounter_duration_days,
    p.encounters_last_12_months,
    p.cost_last_12_months,

    -- Specialty benchmarking
    b.specialty_avg_claim_cost,
    p.avg_claim_cost - b.specialty_avg_claim_cost as cost_vs_specialty_avg,
    case
        when b.specialty_avg_claim_cost > 0
        then (p.avg_claim_cost - b.specialty_avg_claim_cost) / b.specialty_avg_claim_cost
        else null
    end as cost_vs_specialty_avg_pct,

    b.specialty_avg_encounters_last_12_months,
    p.encounters_last_12_months - b.specialty_avg_encounters_last_12_months as volume_vs_specialty_avg,

    current_timestamp() as dbt_updated_at

from provider_metrics p
left join specialty_benchmarks b on p.specialty = b.specialty
