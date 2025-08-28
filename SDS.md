# Software Design Specification (SDS)
# Olist E-Commerce ETL Pipeline

**Version:** 1.0  
**Date:** August 26, 2025  
**Author:** Data Engineering Team

## 1. Introduction

### 1.1 Purpose
This Software Design Specification (SDS) document provides a detailed technical description of the Olist E-Commerce ETL Pipeline. It outlines the system architecture, components, interfaces, data models, and implementation details to guide development and maintenance.

### 1.2 Scope
The document covers the design of a containerized ETL pipeline for processing the Brazilian E-commerce Public Dataset by Olist. It includes specifications for data extraction from object storage, transformation through multiple processing layers, and loading into a relational database for analytical purposes.

### 1.3 Definitions, Acronyms, and Abbreviations
- **ETL**: Extract, Transform, Load
- **DAG**: Directed Acyclic Graph
- **ODS**: Operational Data Store
- **SCD**: Slowly Changing Dimension
- **DDL**: Data Definition Language
- **DQ**: Data Quality
- **RDBMS**: Relational Database Management System

### 1.4 References
- Apache Airflow Documentation: https://airflow.apache.org/docs/
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- MinIO Documentation: https://min.io/docs/minio/linux/index.html
- Docker Documentation: https://docs.docker.com/
- Olist Dataset: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## 2. System Architecture

### 2.1 Architectural Overview

The system follows a containerized microservices architecture with the following key components:

1. **Data Storage Layer**
   - MinIO: S3-compatible object storage for raw data files
   - PostgreSQL: Relational database for processed data

2. **Processing Layer**
   - Apache Airflow: Workflow orchestration engine
   - Python: Data processing scripts
   - SQL: Data transformation logic

3. **Medallion Architecture**
   - Bronze Layer (Raw): Preserves source data with minimal transformations
   - Silver Layer (ODS): Applies schema enforcement and data quality checks
   - Gold Layer (Dimensional): Implements dimensional modeling for analytics

### 2.2 Component Diagram

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│  MinIO Storage  │────▶│  Apache Airflow │────▶│   PostgreSQL    │
│  (Raw Data)     │     │  (Orchestration)│     │   (Processed    │
│                 │     │                 │     │    Data)        │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │
                               │
                               ▼
                        ┌─────────────────┐
                        │                 │
                        │  Docker Engine  │
                        │  (Container     │
                        │   Runtime)      │
                        │                 │
                        └─────────────────┘
```

### 2.3 Container Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Docker Network                         │
│                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐    │
│  │               │  │               │  │               │    │
│  │ PostgreSQL    │  │ MinIO         │  │ Airflow       │    │
│  │ Container     │  │ Container     │  │ Webserver     │    │
│  │               │  │               │  │ Container     │    │
│  └───────────────┘  └───────────────┘  └───────────────┘    │
│                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐    │
│  │               │  │               │  │               │    │
│  │ Airflow       │  │ Airflow Init  │  │ MinIO Setup   │    │
│  │ Scheduler     │  │ Container     │  │ Container     │    │
│  │ Container     │  │               │  │               │    │
│  └───────────────┘  └───────────────┘  └───────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 3. Data Architecture

### 3.1 Data Flow Diagram

```
┌───────────┐     ┌───────────┐     ┌───────────┐     ┌───────────┐
│           │     │           │     │           │     │           │
│  CSV      │────▶│  Raw      │────▶│  ODS      │────▶│  Dim      │
│  Files    │     │  Tables   │     │  Tables   │     │  Tables   │
│           │     │           │     │           │     │           │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
    MinIO           PostgreSQL        PostgreSQL        PostgreSQL
    Storage          raw schema        ods schema        dim schema
```

### 3.2 Data Models

#### 3.2.1 Source Data Model
The source data consists of 9 CSV files with the following entity relationships:

```
                      ┌───────────┐
                      │           │
                      │ Customers │
                      │           │
                      └─────┬─────┘
                            │
                            │
┌───────────┐         ┌─────▼─────┐         ┌───────────┐
│           │         │           │         │           │
│ Payments  │◀────────│  Orders   │────────▶│  Reviews  │
│           │         │           │         │           │
└───────────┘         └─────┬─────┘         └───────────┘
                            │
                            │
                      ┌─────▼─────┐
                      │           │
                      │ Order     │
                      │ Items     │
                      │           │
                      └──┬─────┬──┘
                         │     │
                         │     │
                  ┌──────▼─┐ ┌─▼──────┐
                  │        │ │        │
                  │Products│ │Sellers │
                  │        │ │        │
                  └────────┘ └────────┘
```

#### 3.2.2 Raw Layer Data Model
The raw layer preserves the source data structure with additional metadata columns:
- `_batch_id`: UUID for tracking processing batches
- `_src_key`: Source file path in object storage
- `_src_etag`: ETag for change detection
- `_ingested_at`: Timestamp of ingestion

#### 3.2.3 ODS Layer Data Model
The ODS layer implements a normalized relational model with:
- Standardized data types
- Enforced constraints (NOT NULL, unique keys)
- Referential integrity (foreign keys)
- Optimized column ordering

#### 3.2.4 Dimensional Layer Data Model
The dimensional layer implements a star schema with:
- Fact tables (orders, order_items)
- Dimension tables (d_customer, d_product, d_seller, d_date)
- SCD Type 2 for dimensions that change over time

## 4. Component Design

### 4.1 Apache Airflow

#### 4.1.1 DAG: olist_raw_load
**Purpose**: Extract data from MinIO and load into PostgreSQL raw tables
**Schedule**: Manual trigger (event-driven)
**Tasks**:
1. `run_sql("00_raw_ddl")`: Create raw tables if not exist
2. `run_sql("01_raw_meta")`: Add metadata columns
3. `run_sql("02_raw_indexes")`: Create indexes on raw tables
4. `load_raw_streaming()`: Stream data from MinIO to PostgreSQL
5. `quick_checks()`: Perform basic data validation
6. `trigger_raw_to_ods`: Trigger the next DAG

#### 4.1.2 DAG: raw_to_ods
**Purpose**: Transform raw data into ODS tables
**Schedule**: Triggered by olist_raw_load
**Tasks**:
1. `run_sql_file("10_ods_core_ddl")`: Create ODS tables if not exist
2. `run_sql_file("11_ods_core_indexes")`: Create indexes on ODS tables
3. `run_sql_file("12_ods_core_upsert")`: Transform and load data from raw to ODS
4. `run_sql_with_batch("03_dq_hard")`: Run critical data quality checks
5. `run_sql_with_batch("04_dq_soft")`: Run non-critical data quality checks
6. `trigger_dims`: Trigger the next DAG

#### 4.1.3 DAG: ods_dim
**Purpose**: Create dimensional model from ODS tables
**Schedule**: Triggered by raw_to_ods
**Tasks**:
1. `run_sql("20_ods_dim_ddl")`: Create dimension tables if not exist
2. `run_sql("21_ods_dim_indexes")`: Create indexes on dimension tables
3. `run_sql("22_ods_dim_upsert")`: Transform and load data from ODS to dimension tables

### 4.2 PostgreSQL

#### 4.2.1 Schema Design
- **raw**: Contains tables that mirror source data structure
- **ods**: Contains normalized and cleansed data
- **dim**: Contains dimensional model for analytics

#### 4.2.2 Performance Optimization
- Appropriate indexing strategy for each layer
- Partitioning for large tables (geolocation)
- Vacuum and analyze scheduling
- Connection pooling

### 4.3 MinIO

#### 4.3.1 Bucket Structure
- `olist-data`: Root bucket for all Olist data
  - Raw CSV files stored at the root level

#### 4.3.2 Access Patterns
- Read-only access from Airflow DAGs
- Initial data load via MinIO setup container

## 5. Interface Design

### 5.1 User Interfaces

#### 5.1.1 Airflow Web UI
- **URL**: http://localhost:8080
- **Authentication**: Basic authentication (username/password)
- **Key Features**:
  - DAG monitoring and management
  - Task execution history
  - Log viewing
  - Manual triggering

#### 5.1.2 MinIO Console
- **URL**: http://localhost:9001
- **Authentication**: Basic authentication (username/password)
- **Key Features**:
  - Bucket management
  - Object browsing
  - Access policy configuration

### 5.2 API Interfaces

#### 5.2.1 Airflow REST API
- **Base URL**: http://localhost:8080/api/v1
- **Authentication**: Basic authentication
- **Key Endpoints**:
  - `/dags`: List and manage DAGs
  - `/dagRuns`: List and manage DAG runs
  - `/tasks`: List and manage tasks

#### 5.2.2 MinIO S3 API
- **Base URL**: http://localhost:9000
- **Authentication**: AWS signature v4
- **Key Operations**:
  - `GetObject`: Retrieve objects from buckets
  - `ListObjects`: List objects in buckets
  - `PutObject`: Upload objects to buckets

## 6. Data Quality Framework

### 6.1 Data Quality Dimensions
- **Completeness**: Ensuring all required data is present
- **Accuracy**: Ensuring data values are correct
- **Consistency**: Ensuring data is consistent across tables
- **Timeliness**: Ensuring data is processed within expected timeframes
- **Uniqueness**: Ensuring no unexpected duplicates exist

### 6.2 Data Quality Checks

#### 6.2.1 Hard Checks (Critical)
- Primary key violations
- Foreign key violations
- Not null constraint violations
- Data type violations
- Implementation: SQL assertions that fail the pipeline if violated

#### 6.2.2 Soft Checks (Non-Critical)
- Value range validations
- Pattern matching
- Statistical outlier detection
- Implementation: SQL queries that log warnings but allow pipeline to continue

### 6.3 Data Quality Monitoring
- Metrics stored in dedicated DQ tables
- Trend analysis across processing batches
- Alerting via Slack integration

## 7. Deployment Specification

### 7.1 Docker Containers

#### 7.1.1 PostgreSQL Container
- **Image**: postgres:15
- **Environment Variables**:
  - POSTGRES_USER: kdea989
  - POSTGRES_PASSWORD: Kdea504605
  - POSTGRES_DB: olist
- **Volumes**:
  - postgres-db-volume:/var/lib/postgresql/data
- **Health Check**: pg_isready command

#### 7.1.2 MinIO Container
- **Image**: minio/minio
- **Ports**:
  - 9000: S3 API
  - 9001: Web Console
- **Environment Variables**:
  - MINIO_ROOT_USER: kdea989
  - MINIO_ROOT_PASSWORD: Kdea504605
- **Command**: server /data --console-address ":9001"
- **Health Check**: HTTP request to /minio/health/live

#### 7.1.3 Airflow Webserver Container
- **Image**: apache/airflow:2.9.3
- **Ports**:
  - 8080: Web UI
- **Environment Variables**:
  - AIRFLOW__CORE__EXECUTOR: LocalExecutor
  - AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://kdea989:Kdea504605@postgres:5432/olist
  - Additional configuration variables
- **Volumes**:
  - ./olist-pipeline/dag:/opt/airflow/dags
  - ./olist-pipeline/sql:/opt/airflow/sql
  - ./data:/opt/airflow/data
- **Health Check**: HTTP request to /health

#### 7.1.4 Airflow Scheduler Container
- **Image**: apache/airflow:2.9.3
- **Environment Variables**: Same as webserver
- **Volumes**: Same as webserver
- **Command**: airflow scheduler

#### 7.1.5 Airflow Init Container
- **Image**: apache/airflow:2.9.3
- **Purpose**: Initialize Airflow database and create user
- **Command**: 
  ```
  airflow db migrate;
  airflow users create --username kdea989 --password Kdea504605 --firstname Daeyeop --lastname Kim --role Admin --email kdea989@gmail.com
  ```

#### 7.1.6 MinIO Setup Container
- **Image**: minio/mc
- **Purpose**: Configure MinIO and load initial data
- **Command**:
  ```
  mc alias set myminio http://minio:9000 kdea989 Kdea504605;
  mc mb myminio/olist-data --ignore-existing;
  mc cp --recursive /data/raw/ myminio/olist-data/;
  ```

### 7.2 Network Configuration
- **Network Name**: airflow-network
- **Driver**: bridge
- **Service Discovery**: Container name resolution

### 7.3 Volume Configuration
- **postgres-db-volume**: Persistent volume for PostgreSQL data

### 7.4 Resource Requirements
- **CPU**: Minimum 2 cores recommended
- **Memory**: Minimum 4GB RAM
- **Disk**: Minimum 5GB free space

## 8. Testing Strategy

### 8.1 Unit Testing
- Python unit tests for custom operators and functions
- SQL unit tests for transformation logic

### 8.2 Integration Testing
- End-to-end DAG execution tests
- Database schema validation tests
- Data quality check validation

### 8.3 Performance Testing
- Load testing with full dataset
- Concurrency testing for multiple DAG runs
- Resource utilization monitoring

## 9. Security Considerations

### 9.1 Authentication
- Basic authentication for Airflow and MinIO
- Secure password storage

### 9.2 Authorization
- Role-based access control in Airflow
- Bucket policies in MinIO

### 9.3 Data Protection
- Network isolation via Docker network
- No exposure of PostgreSQL port to host
- Encryption of sensitive environment variables

## 10. Maintenance and Operations

### 10.1 Logging
- Centralized logging via Docker logging driver
- Application-specific logs in container filesystems
- Log rotation and retention policies

### 10.2 Monitoring
- Container health monitoring
- DAG execution monitoring
- Database performance monitoring

### 10.3 Backup and Recovery
- PostgreSQL database backups
- MinIO bucket snapshots
- Docker volume backups

### 10.4 Scaling Considerations
- Horizontal scaling for Airflow workers
- Vertical scaling for PostgreSQL
- Connection pooling for database access

## 11. Appendices

### 11.1 SQL Scripts
Detailed documentation of SQL transformation scripts

### 11.2 Environment Variables
Complete list of environment variables and their purposes

### 11.3 Troubleshooting Guide
Common issues and their resolutions