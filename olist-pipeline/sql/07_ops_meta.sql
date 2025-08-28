CREATE SCHEMA IF NOT EXISTS ops;

CREATE TABLE IF NOT EXISTS ops.dq_results (
    check_name text,
    table_name text,
    level text,                 -- 'hard' | 'soft'
    status text,                -- 'pass' | 'fail'
    actual numeric,
    threshold numeric,
    details text,
    checked_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_ops_dq_checked_at ON ops.dq_results(checked_at DESC);
