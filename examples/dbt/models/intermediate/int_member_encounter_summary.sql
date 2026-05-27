{{
  config(
    materialized='table'
  )
}}

with encounter_metrics as (
    select
        member_id,
        count(distinct encounter_id) as total_encounters,
        sum(total_claim_cost) as lifetime_claim_cost,
        sum(payer_coverage) as lifetime_payer_coverage,
        sum(member_responsibility) as lifetime_member_responsibility,
        min(encounter_start_ts) as first_encounter_date,
        max(encounter_start_ts) as last_encounter_date,
        datediff(day, min(encounter_start_ts), max(encounter_start_ts)) as days_between_first_last_encounter,

        -- Encounter counts by class
        count(distinct case when encounter_class = 'ambulatory' then encounter_id end) as ambulatory_encounters,
        count(distinct case when encounter_class = 'emergency' then encounter_id end) as emergency_encounters,
        count(distinct case when encounter_class = 'inpatient' then encounter_id end) as inpatient_encounters,
        count(distinct case when encounter_class = 'wellness' then encounter_id end) as wellness_encounters,
        count(distinct case when encounter_class = 'outpatient' then encounter_id end) as outpatient_encounters,
        count(distinct case when encounter_class = 'urgentcare' then encounter_id end) as urgentcare_encounters,

        -- Cost by class
        sum(case when encounter_class = 'inpatient' then total_claim_cost else 0 end) as inpatient_cost,
        sum(case when encounter_class = 'emergency' then total_claim_cost else 0 end) as emergency_cost,

        -- Recent activity (last 12 months)
        count(distinct case
            when encounter_start_ts >= dateadd(month, -12, current_timestamp())
            then encounter_id
        end) as encounters_last_12_months,

        sum(case
            when encounter_start_ts >= dateadd(month, -12, current_timestamp())
            then total_claim_cost
            else 0
        end) as cost_last_12_months

    from {{ ref('stg_encounters') }}
    group by member_id
)

select * from encounter_metrics
