{{
  config(
    materialized='table',
    tags=['member', 'analytics']
  )
}}

select
    -- Member demographics
    p.member_id,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    floor(datediff(day, p.date_of_birth, current_timestamp()) / 365.25) as age_years,
    p.gender,
    p.race,
    p.ethnicity,
    p.marital_status,
    p.city,
    p.state,
    p.county,
    p.zip,
    p.is_active,
    p.death_date,

    -- Financial information
    p.income,
    p.healthcare_expenses,
    p.healthcare_coverage,

    -- Encounter summary
    coalesce(e.total_encounters, 0) as lifetime_encounters,
    coalesce(e.lifetime_claim_cost, 0) as lifetime_claim_cost,
    coalesce(e.lifetime_payer_coverage, 0) as lifetime_payer_coverage,
    coalesce(e.lifetime_member_responsibility, 0) as lifetime_member_responsibility,
    e.first_encounter_date,
    e.last_encounter_date,
    datediff(day, e.last_encounter_date, current_timestamp()) as days_since_last_encounter,

    -- Encounter breakdown
    coalesce(e.ambulatory_encounters, 0) as ambulatory_encounters,
    coalesce(e.emergency_encounters, 0) as emergency_encounters,
    coalesce(e.inpatient_encounters, 0) as inpatient_encounters,
    coalesce(e.wellness_encounters, 0) as wellness_encounters,
    coalesce(e.inpatient_cost, 0) as inpatient_cost,
    coalesce(e.emergency_cost, 0) as emergency_cost,

    -- Recent activity
    coalesce(e.encounters_last_12_months, 0) as encounters_last_12_months,
    coalesce(e.cost_last_12_months, 0) as cost_last_12_months,

    -- Latest vitals
    v.bmi,
    v.bmi_category,
    v.systolic_bp,
    v.diastolic_bp,
    v.blood_pressure_category,
    v.heart_rate,
    v.weight_kg,
    v.height_cm,
    v.latest_vital_sign_date,
    datediff(day, v.latest_vital_sign_date, current_timestamp()) as days_since_last_vital,

    -- Risk flags
    case when e.emergency_encounters >= 2 then true else false end as high_ed_utilizer,
    case when e.inpatient_encounters >= 1 then true else false end as has_inpatient_history,
    case when e.cost_last_12_months > 50000 then true else false end as high_cost_member,
    case when v.bmi >= 30 then true else false end as obese_flag,
    case when v.systolic_bp >= 140 or v.diastolic_bp >= 90 then true else false end as hypertension_flag,

    current_timestamp() as dbt_updated_at

from {{ ref('stg_patients') }} p
left join {{ ref('int_member_encounter_summary') }} e
    on p.member_id = e.member_id
left join {{ ref('int_member_latest_vitals') }} v
    on p.member_id = v.member_id
