-- 파이프라인 이력·워터마크

CREATE SCHEMA IF NOT EXISTS meta;

CREATE TABLE IF NOT EXISTS meta.watermarks(
    layer text,               -- raw/ods/dim/fact/gold
    entity text,              -- 테이블/마트명
    ds_utc date,              -- 처리 기준일
    row_count bigint,
    checksum text,
    updated_at timestamptz DEFAULT now(),
    PRIMARY KEY(layer, entity, ds_utc)
);

CREATE TABLE IF NOT EXISTS meta.lineage(
    target_schema text,
    target_table  text,
    source_schema text,
    source_table  text,
    ds_utc date,
    created_at timestamptz DEFAULT now()
);
