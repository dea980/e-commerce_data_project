-- 오류행 격리용 (실패원인 추적 가능)
CREATE SCHEMA IF NOT EXISTS quarantine;

CREATE TABLE IF NOT EXISTS quarantine.bad_rows(
    src_table text,
    ds_utc date,
    reason text,
    payload jsonb,
    created_at timestamptz DEFAULT now()
);
