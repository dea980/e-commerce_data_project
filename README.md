# Olist E-Commerce ETL Pipeline

## Overview

This repository implements a scalable, containerized ETL (Extract, Transform, Load) pipeline for the Brazilian E-commerce Public Dataset by Olist. The architecture leverages industry-standard data engineering tools:

- **Apache Airflow 2.9.3**: Orchestration engine for workflow scheduling and dependency management
- **PostgreSQL 15**: RDBMS for structured data storage with transactional integrity
- **MinIO**: S3-compatible object storage for raw data persistence

The pipeline follows a medallion architecture pattern with progressive data refinement through multiple processing layers.

## Data Source

The pipeline processes the Olist Brazilian E-commerce dataset comprising 9 normalized CSV files with the following specifications:

| Entity | Records | Key Attributes |
|--------|---------|----------------|
| Orders | 99,441 | order_id, customer_id, status, timestamps |
| Order Items | 112,650 | order_id, product_id, seller_id, price |
| Customers | 99,441 | customer_id, location data |
| Sellers | 3,095 | seller_id, location data |
| Products | 32,951 | product_id, category, dimensions |
| Reviews | 104,719 | review_id, order_id, score, comments |
| Payments | 103,886 | order_id, payment_type, installments |
| Geolocation | 1,000,163 | zip_code_prefix, lat/lng coordinates |
| Category Translation | 71 | Portuguese to English mappings |

## Pipeline Architecture

The data pipeline implements a three-layer medallion architecture:

### 1. Raw Layer (Bronze)
**DAG: olist_raw_load**
- Ingests data from MinIO S3 to PostgreSQL raw tables
- Preserves source data integrity with minimal transformations
- Implements metadata tracking (batch_id, ingestion timestamp, source)
- Executes lightweight data validation checks
- Technical implementation:
  ```python
  # Key operations in raw layer
  batch_id = str(uuid.uuid4())  # Unique processing ID
  s3 = _s3()  # S3/MinIO client initialization
  
  # Stream data directly from object storage to PostgreSQL
  for tbl, key in RAW_FILES.items():
      obj = s3.get_object(Bucket=S3_BUCKET, Key=s3key)
      with io.TextIOWrapper(obj["Body"], encoding="utf-8") as f:
          cur.copy_expert(f"COPY raw.{tbl} FROM STDIN WITH (FORMAT CSV, HEADER TRUE)", f)
  ```

### 2. ODS Layer (Silver)
**DAG: raw_to_ods**
- Applies schema enforcement and data type standardization
- Executes data quality checks (hard constraints and soft validations)
- Implements error handling with configurable failure thresholds
- Integrates with alerting system for DQ violations
- Technical implementation:
  ```sql
  -- Example of ODS layer transformation (simplified)
  INSERT INTO ods.orders
  SELECT
    order_id,
    customer_id,
    CASE
      WHEN order_status IN ('delivered', 'shipped', 'canceled') THEN order_status
      ELSE 'other'
    END AS order_status,
    CAST(order_purchase_timestamp AS TIMESTAMP),
    -- Additional transformations
  FROM raw.orders_raw
  WHERE _batch_id = '{{BATCH_ID}}'
  ON CONFLICT (order_id) DO UPDATE
  SET /* update logic */;
  ```

### 3. Dimensional Layer (Gold)
**DAG: ods_dim**
- Implements dimensional modeling (fact/dimension tables)
- Optimizes for analytical query performance
- Applies appropriate indexing strategies
- Handles SCD (Slowly Changing Dimension) patterns
- Technical implementation:
  ```sql
  -- Example of dimension table creation
  CREATE TABLE IF NOT EXISTS dim.d_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    customer_city VARCHAR(50),
    customer_state CHAR(2),
    geolocation_lat NUMERIC(15,10),
    geolocation_lng NUMERIC(15,10),
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE,
    UNIQUE(customer_id, valid_from)
  );
  ```

## Technical Requirements

- Docker Engine 20.10+ and Docker Compose v2+
- Minimum 4GB RAM allocated to Docker
- Available ports: 8080 (Airflow), 9000-9001 (MinIO)
- 5GB+ available disk space

## Deployment

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd e-commerce_data_project
   ```

2. Deploy the containerized infrastructure:
   ```bash
   docker-compose up -d
   ```

3. Verify deployment status:
   ```bash
   docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
   ```

## Service Access

| Service | URL | Credentials | Purpose |
|---------|-----|-------------|---------|
| Airflow | http://localhost:8080 | kdea989/Kdea504605 | Workflow orchestration |
| MinIO Console | http://localhost:9001 | kdea989/Kdea504605 | Object storage management |

## Repository Structure

```
e-commerce_data_project/
├── data/
│   └── raw/                  # Source CSV files
├── olist-pipeline/
│   ├── dag/                  # Airflow DAG definitions
│   │   ├── _alerts.py        # Alerting framework
│   │   ├── _common.py        # Shared utilities
│   │   ├── olist_raw_load.py # Raw ingestion DAG
│   │   ├── raw_to_ods.py     # ODS transformation DAG
│   │   └── ods_dim.py        # Dimensional modeling DAG
│   ├── docker/               # Docker configuration
│   └── sql/                  # SQL transformation scripts
│       ├── 00_raw_ddl.sql    # Raw schema definitions
│       ├── 01_raw_meta.sql   # Metadata column definitions
│       ├── 02_raw_indexes.sql # Raw layer indexing
│       ├── 03_dq_hard.sql    # Critical data quality checks
│       ├── 04_dq_soft.sql    # Non-critical data quality checks
│       ├── 10_ods_core_ddl.sql # ODS schema definitions
│       ├── 11_ods_core_indexes.sql # ODS performance optimization
│       ├── 12_ods_core_upsert.sql # ODS incremental loading
│       └── 20_ods_dim_ddl.sql # Dimensional model definitions
└── docker-compose.yml        # Infrastructure as code
```

## Execution

The pipeline implements event-driven orchestration with DAG dependencies:

1. Access Airflow UI: http://localhost:8080
2. Authenticate with provided credentials
3. Navigate to DAGs view
4. Activate DAGs (toggle switch if paused)
5. Trigger `olist_raw_load` DAG
   - Subsequent DAGs (`raw_to_ods` → `ods_dim`) will be automatically triggered via TriggerDagRunOperator

## Monitoring and Troubleshooting

### Logs
```bash
# View container logs
docker logs e-commerce_data_project-airflow-webserver-1 -f

# View Airflow task logs via UI
# DAGs > [DAG_NAME] > [TASK_NAME] > Log
```

### Common Issues

#### Port Conflicts
Modify port mappings in `docker-compose.yml` if conflicts occur:
```yaml
ports:
  - "8081:8080"  # Map to alternate host port
```

#### Container Health
```bash
# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# Restart specific container
docker restart e-commerce_data_project-airflow-webserver-1
```

#### Data Quality Alerts
Data quality issues are logged to:
1. Airflow task logs
2. Slack notifications (if configured)

## License and Attribution

This project utilizes the Brazilian E-commerce Public Dataset by Olist, available under [Kaggle's terms](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Commercial usage requires appropriate attribution.

## Contributors

- Data Engineering Team

## Acknowledgements

- Olist for dataset publication
- Apache Airflow, PostgreSQL, and MinIO open-source communities
