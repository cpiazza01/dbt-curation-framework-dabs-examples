{{
  config(
    materialized='table',
    tags=['financial', 'reporting']
  )
}}

with monthly_totals as (
    select
        encounter_month,

        sum(encounter_count) as total_encounters,
        sum(unique_members) as total_unique_members,
        sum(unique_providers) as total_unique_providers,

        sum(total_claim_cost) as total_claim_cost,
        sum(total_payer_coverage) as total_payer_coverage,
        sum(total_member_responsibility) as total_member_responsibility,

        sum(total_claim_cost) / nullif(sum(encounter_count), 0) as avg_cost_per_encounter,
        sum(total_claim_cost) / nullif(sum(unique_members), 0) as avg_cost_per_member

    from {{ ref('int_encounter_monthly_summary') }}
    group by encounter_month
)

, with_prior_month as (
    select
        *,
        lag(total_claim_cost, 1) over (order by encounter_month) as prior_month_cost,
        lag(total_encounters, 1) over (order by encounter_month) as prior_month_encounters,
        lag(total_claim_cost, 12) over (order by encounter_month) as prior_year_cost
    from monthly_totals
)

select
    encounter_month,
    total_encounters,
    total_unique_members,
    total_unique_providers,
    total_claim_cost,
    total_payer_coverage,
    total_member_responsibility,
    avg_cost_per_encounter,
    avg_cost_per_member,

    -- Month-over-month changes
    total_claim_cost - prior_month_cost as mom_cost_change,
    case
        when prior_month_cost > 0
        then (total_claim_cost - prior_month_cost) / prior_month_cost
        else null
    end as mom_cost_change_pct,

    total_encounters - prior_month_encounters as mom_encounter_change,

    -- Year-over-year changes
    total_claim_cost - prior_year_cost as yoy_cost_change,
    case
        when prior_year_cost > 0
        then (total_claim_cost - prior_year_cost) / prior_year_cost
        else null
    end as yoy_cost_change_pct,

    current_timestamp() as dbt_updated_at

from with_prior_month
order by encounter_month desc
