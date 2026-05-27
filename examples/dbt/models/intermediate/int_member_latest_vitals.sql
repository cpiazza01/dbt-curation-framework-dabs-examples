{{
  config(
    materialized='table'
  )
}}

with vitals_ranked as (
    select
        member_id,
        observation_date,
        -- BMI (LOINC 39156-5)
        max(case when loinc_code = '39156-5' then cast(value as double) end) as bmi,
        -- Body height (LOINC 8302-2), cm
        max(case when loinc_code = '8302-2' then cast(value as double) end) as height_cm,
        -- Body weight (LOINC 29463-7), kg
        max(case when loinc_code = '29463-7' then cast(value as double) end) as weight_kg,
        -- Systolic BP (LOINC 8480-6), mm[Hg]
        max(case when loinc_code = '8480-6' then cast(value as double) end) as systolic_bp,
        -- Diastolic BP (LOINC 8462-4), mm[Hg]
        max(case when loinc_code = '8462-4' then cast(value as double) end) as diastolic_bp,
        -- Heart rate (LOINC 8867-4), /min
        max(case when loinc_code = '8867-4' then cast(value as double) end) as heart_rate,
        row_number() over (partition by member_id order by observation_date desc) as rn
    from {{ ref('stg_observations') }}
    where category = 'vital-signs'
    group by member_id, observation_date
),

latest as (
    select * from vitals_ranked where rn = 1
)

select
    member_id,
    observation_date as latest_vital_sign_date,
    bmi,
    case
        when bmi < 18.5 then 'Underweight'
        when bmi < 25.0 then 'Normal'
        when bmi < 30.0 then 'Overweight'
        when bmi >= 30.0 then 'Obese'
    end as bmi_category,
    height_cm,
    weight_kg,
    systolic_bp,
    diastolic_bp,
    case
        when systolic_bp >= 140 or diastolic_bp >= 90 then 'Hypertension Stage 2+'
        when systolic_bp >= 130 or diastolic_bp >= 80 then 'Hypertension Stage 1'
        when systolic_bp >= 120 then 'Elevated'
        else 'Normal'
    end as blood_pressure_category,
    heart_rate
from latest
