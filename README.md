# dbt-curation-framework-dabs — Examples

A reference example for the [dbt-curation-framework-dabs](https://github.com/cpiazza01/dbt-curation-framework-dabs) framework. The `examples/` directory contains a self-contained Databricks Asset Bundle (DABs) project demonstrating a full gold-layer dbt curation pipeline.

## Prerequisites

- [Databricks CLI](https://docs.databricks.com/dev-tools/cli/databricks-cli.html) installed and authenticated
- A Databricks workspace with Unity Catalog enabled
- A SQL warehouse

## How to use this example

1. Install the framework:
   ```bash
   pip install -r requirements.txt --force-reinstall
   ```
2. Update `examples/databricks.yml` — replace the lookup names (`"Example Warehouse"`, `"example-sp-${var.env}"`, `"Example Downstream Job"`) with the actual resource names in your workspace, and adjust the catalog naming pattern (`enterprise_${var.env}`) if needed.
3. Update `examples/dbt_curation_config.yaml` with your project details.
4. Generate and deploy:
   ```bash
   cd examples
   dbt-curation-generate --config dbt_curation_config.yaml --env dev
   databricks bundle deploy --target local_dev
   ```

See [examples/README.md](examples/README.md) for a full walkthrough of the example project.
