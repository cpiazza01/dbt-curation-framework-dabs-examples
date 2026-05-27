# Example — Healthcare Analytics

This example uses a synthetic healthcare claims dataset to demonstrate a gold-layer curation pipeline built with the [dbt-curation-framework-dabs](https://github.com/cpiazza01/dbt-curation-framework-dabs) framework. It covers member demographics, encounter history, clinical observations, and provider performance — a realistic cross-domain use case that exercises the full staging → intermediate → marts model architecture.

## What This Example Shows

- **Three-layer dbt architecture**: Staging views in `pre_gold`, intermediate tables in `pre_gold`, and gold marts in `gold` — all routed automatically via `+schema` in `dbt_project.yml` and the generated `generate_schema_name` macro
- **Multi-environment configuration**: `databricks.yml` defines `local_dev`, `dev`, `test`, and `prod` targets — catalog names are derived automatically from the `env` variable (`enterprise_${var.env}`), and the warehouse and upstream service principal are resolved by name lookup rather than hard-coded IDs
- **Full `dbt_curation_config.yaml`**: Demonstrates all available configuration options including schedule, downstream job trigger, service principals, custom tags, success email notifications, job timeout, retry behaviour, auto-optimization, and performance target
- **Risk stratification**: `mart_member_360` joins demographics, encounter history, and vitals to produce member-level risk flags (high ED utilizer, high cost, hypertension, obesity)
- **Trend reporting**: `mart_monthly_financial_summary` computes month-over-month and year-over-year cost and volume changes using window functions
- **Provider benchmarking**: `mart_provider_performance_metrics` compares each provider's cost and volume against their specialty average

## Model Structure

```
dbt/models/
├── staging/                          # Views in pre_gold schema
│   ├── schema.yml                    # Source definitions and model tests
│   ├── stg_patients.sql              # Member demographics + is_active flag
│   ├── stg_encounters.sql            # Claims with calculated member_responsibility
│   ├── stg_observations.sql          # Vital signs (LOINC-coded)
│   └── stg_providers.sql             # Provider attributes
├── intermediate/                     # Tables in pre_gold schema
│   ├── int_member_encounter_summary.sql     # Lifetime and recent encounter/cost metrics per member
│   ├── int_member_latest_vitals.sql         # Latest vital signs with clinical categorization
│   ├── int_encounter_monthly_summary.sql    # Monthly encounter counts and costs by class
│   └── int_provider_current_metrics.sql     # Provider encounter volume and cost metrics
└── marts/                            # Tables in gold schema
    ├── schema.yml                    # Model documentation and tests
    ├── mart_member_360.sql           # Comprehensive member profile with risk flags
    ├── mart_monthly_financial_summary.sql   # Monthly financials with MoM and YoY trends
    └── mart_provider_performance_metrics.sql # Provider performance vs specialty benchmark
```

## Files in This Example

| File | Handwritten / Generated | Description |
|------|------------------------|-------------|
| `databricks.yml` | Handwritten | DABs bundle with local_dev, dev, test, and prod targets |
| `dbt_curation_config.yaml` | Handwritten | Full curation job config |
| `dbt/dbt_project.yml` | Handwritten | dbt project with `+schema` routing config |
| `dbt/packages.yml` | Handwritten | dbt package dependencies |
| `dbt/models/staging/*` | Handwritten | Staging views sourced from the silver layer |
| `dbt/models/intermediate/*` | Handwritten | Intermediate aggregation tables |
| `dbt/models/marts/*` | Handwritten | Gold-layer mart tables |
| `resources/dbt_job.yml` | **Generated** | Databricks Workflow job — gitignored; produced by CI and local generate runs |
| `dbt/profiles.yml` | **Generated** | Local dev connection profile — gitignored |
| `dbt/macros/generate_schema_name.sql` | **Generated** | Schema routing macro — gitignored; produced by CI and local generate runs |

## How to Deploy

```bash
# From the examples/ directory:

# 1. Generate the DABs and dbt artifacts
dbt-curation-generate --config dbt_curation_config.yaml --env prod

# 2. Deploy
databricks bundle deploy --target prod
```

> Generated files (`resources/dbt_job.yml`, `dbt/macros/generate_schema_name.sql`, `dbt/profiles.yml`) are gitignored — they are produced on the fly by `dbt-curation-generate` before each deploy, both locally and in CI.

## Key Configuration Decisions

| Decision | Detail |
|----------|--------|
| `job_name` | The name given to the generated Databricks Workflow job — replaces the old `project_name` field |
| `domain` | Required field used as the `Domain` governance tag on the job — replaces the old `github_repo` field |
| `catalog: enterprise_${var.env}` | Single `env` variable drives catalog naming across all targets — no need to repeat the catalog name per target |
| Warehouse lookup by name | `warehouse_id` uses a DABs name lookup (`"Example Warehouse"`) so the workflow isn't tied to a hard-coded warehouse ID |
| SP lookup by name | `upstream_service_principal_id` resolves the correct SP per environment via `"example-sp-${var.env}"` — no hard-coded client IDs in config |
| `local_dev` vs `dev` target | `local_dev` uses `mode: development` (username-prefixed resources for local work); `dev` uses `mode: production` and is what CI deploys to |
| `dbt_commands` with `--vars` | Passes `${var.catalog}` into dbt so `var('catalog')` in `schema.yml` resolves to the correct source catalog per environment — `dbt deps` doesn't need it, but `dbt build` and `dbt test` do |
| `trigger_downstream_job` | Chains to a downstream reporting pipeline job after dbt completes — see `downstream_job_id` |
| `+schema: pre_gold` on staging/intermediate | Both layers share the same holding schema before promotion to gold |
| `+schema: gold` on marts | Final consumer-facing tables land in the gold schema, cleanly separated from pre_gold |
| `timeout_seconds` | Hard ceiling of 2 hours on the job — prevents runaway builds from holding the warehouse indefinitely |
| `max_retries` / `retry_on_timeout` | One automatic retry with a 60-second back-off; also retries if the job hits the timeout limit |
| `disable_auto_optimization` | Disables Databricks auto-optimization for predictable, deterministic task execution |
| `performance_target` | Set to `STANDARD` here; switch to `PERFORMANCE_OPTIMIZED` to enable Photon acceleration for large datasets |
