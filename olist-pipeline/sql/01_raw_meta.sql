-- 배치 추적/리플레이 용 메타칼럼 (모든 RAW 테이블 동일)
-- _batch_id : 이번 적재 배치 UUID(테이블별 UPDATE로 일괄 채움)
-- _ingested_at : 적재시각(UTC 권장)
-- _src_key / _src_etag : S3 소스 추적

-- 필요한 경우 pgcrypto/uuid-ossp 확장 중 하나 설치 (선택)
-- CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='raw' AND column_name='_batch_id'
    ) THEN
        -- 모든 raw.* 테이블에 공통 컬럼 추가
        PERFORM (
        SELECT string_agg(
            format('ALTER TABLE raw.%I ADD COLUMN IF NOT EXISTS _batch_id uuid;', table_name),
            ' '
        )
        FROM information_schema.tables
        WHERE table_schema='raw' AND table_type='BASE TABLE'
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='raw' AND column_name='_ingested_at'
    ) THEN
        PERFORM (
        SELECT string_agg(
            format('ALTER TABLE raw.%I ADD COLUMN IF NOT EXISTS _ingested_at timestamptz;', table_name),
            ' '
        )
        FROM information_schema.tables
        WHERE table_schema='raw' AND table_type='BASE TABLE'
        );
    END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='raw' AND column_name='_src_key'
  ) THEN
    PERFORM (
      SELECT string_agg(
        format('ALTER TABLE raw.%I ADD COLUMN IF NOT EXISTS _src_key text;', table_name),
        ' '
      )
      FROM information_schema.tables
      WHERE table_schema='raw' AND table_type='BASE TABLE'
    );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='raw' AND column_name='_src_etag'
  ) THEN
    PERFORM (
      SELECT string_agg(
        format('ALTER TABLE raw.%I ADD COLUMN IF NOT EXISTS _src_etag text;', table_name),
        ' '
      )
      FROM information_schema.tables
      WHERE table_schema='raw' AND table_type='BASE TABLE'
    );
  END IF;
END $$;
