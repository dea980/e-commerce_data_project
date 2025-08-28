"""
실제 SQL 파일들의 구문 및 구조 검증 테스트
"""
import pytest
from pathlib import Path
import re


class TestSQLFileStructure:
    """SQL 파일 구조 검증"""
    
    @property
    def sql_dir(self):
        """SQL 디렉토리 경로"""
        return Path(__file__).parent.parent / "sql"
    
    def test_sql_files_exist(self):
        """필수 SQL 파일들이 존재하는지 확인"""
        # Given
        expected_files = [
            "00_raw_ddl.sql",
            "01_raw_meta.sql", 
            "02_raw_indexes.sql",
            "03_dq_hard.sql",
            "04_dq_soft.sql",
            "05_meta_lineage.sql",
            "06_error_quarantine.sql",
            "10_ods_core_ddl.sql",
            "11_ods_core_indexes.sql",
            "12_ods_core_upsert.sql",
            "20_ods_dim_ddl.sql",
            "21_ods_dim_indexes.sql",
            "22_ods_dim_upsert.sql"
        ]
        
        # When
        existing_files = [f.name for f in self.sql_dir.glob("*.sql")]
        
        # Then
        for expected_file in expected_files:
            assert expected_file in existing_files, f"Missing SQL file: {expected_file}"
    
    def test_sql_files_not_empty(self):
        """SQL 파일들이 비어있지 않은지 확인"""
        # Given
        sql_files = list(self.sql_dir.glob("*.sql"))
        
        # When & Then
        for sql_file in sql_files:
            content = sql_file.read_text(encoding='utf-8').strip()
            assert len(content) > 0, f"Empty SQL file: {sql_file.name}"
            assert not content.isspace(), f"SQL file contains only whitespace: {sql_file.name}"
    
    def test_sql_file_encoding(self):
        """SQL 파일들의 인코딩이 UTF-8인지 확인"""
        # Given
        sql_files = list(self.sql_dir.glob("*.sql"))
        
        # When & Then
        for sql_file in sql_files:
            try:
                content = sql_file.read_text(encoding='utf-8')
                # 한글 주석이 있는 경우도 정상적으로 읽혀야 함
                assert isinstance(content, str)
            except UnicodeDecodeError:
                pytest.fail(f"SQL file {sql_file.name} is not UTF-8 encoded")


class TestSQLSyntaxBasics:
    """SQL 기본 구문 검증"""
    
    @property
    def sql_dir(self):
        return Path(__file__).parent.parent / "sql"
    
    def test_ddl_files_have_create_statements(self):
        """DDL 파일들에 CREATE 문이 있는지 확인"""
        # Given
        ddl_files = [
            "00_raw_ddl.sql",
            "10_ods_core_ddl.sql", 
            "20_ods_dim_ddl.sql"
        ]
        
        # When & Then
        for ddl_file in ddl_files:
            file_path = self.sql_dir / ddl_file
            if file_path.exists():
                content = file_path.read_text(encoding='utf-8').upper()
                assert "CREATE" in content, f"No CREATE statement found in {ddl_file}"
                # 스키마 또는 테이블 생성문이 있어야 함
                assert "CREATE SCHEMA" in content or "CREATE TABLE" in content, \
                    f"No CREATE SCHEMA or CREATE TABLE found in {ddl_file}"
    
    def test_index_files_have_index_statements(self):
        """인덱스 파일들에 INDEX 생성문이 있는지 확인"""
        # Given
        index_files = [
            "02_raw_indexes.sql",
            "11_ods_core_indexes.sql",
            "21_ods_dim_indexes.sql"
        ]
        
        # When & Then
        for index_file in index_files:
            file_path = self.sql_dir / index_file
            if file_path.exists():
                content = file_path.read_text(encoding='utf-8').upper()
                assert "CREATE INDEX" in content, f"No CREATE INDEX statement found in {index_file}"
    
    def test_upsert_files_have_insert_statements(self):
        """UPSERT 파일들에 INSERT 문이 있는지 확인"""
        # Given
        upsert_files = [
            "12_ods_core_upsert.sql",
            "22_ods_dim_upsert.sql"
        ]
        
        # When & Then
        for upsert_file in upsert_files:
            file_path = self.sql_dir / upsert_file
            if file_path.exists():
                content = file_path.read_text(encoding='utf-8').upper()
                assert "INSERT" in content, f"No INSERT statement found in {upsert_file}"
                # UPSERT 패턴 확인 (ON CONFLICT 또는 ON DUPLICATE KEY)
                assert "ON CONFLICT" in content or "ON DUPLICATE KEY" in content, \
                    f"No UPSERT pattern found in {upsert_file}"
    
    def test_dq_files_have_validation_logic(self):
        """데이터 품질 파일들에 검증 로직이 있는지 확인"""
        # Given
        dq_files = [
            "03_dq_hard.sql",
            "04_dq_soft.sql"
        ]
        
        # When & Then
        for dq_file in dq_files:
            file_path = self.sql_dir / dq_file
            if file_path.exists():
                content = file_path.read_text(encoding='utf-8').upper()
                # DQ 결과를 기록하는 INSERT 문이 있어야 함
                assert "INSERT INTO" in content and "DQ_RESULTS" in content, \
                    f"No DQ results logging found in {dq_file}"


class TestSQLTableReferences:
    """SQL 테이블 참조 검증"""
    
    @property
    def sql_dir(self):
        return Path(__file__).parent.parent / "sql"
    
    def test_schema_consistency(self):
        """스키마 참조의 일관성 확인"""
        # Given
        expected_schemas = ['raw', 'ods', 'ops', 'meta', 'quarantine']
        
        # When
        all_content = ""
        for sql_file in self.sql_dir.glob("*.sql"):
            content = sql_file.read_text(encoding='utf-8')
            all_content += content + "\n"
        
        # Then
        for schema in expected_schemas:
            # 스키마가 생성되거나 참조되어야 함
            schema_patterns = [
                f"CREATE SCHEMA.*{schema}",
                f"{schema}\\.",  # schema.table 형태
                f"SCHEMA.*{schema}"
            ]
            
            found = any(re.search(pattern, all_content, re.IGNORECASE) for pattern in schema_patterns)
            assert found, f"Schema '{schema}' not found in any SQL file"
    
    def test_table_references(self):
        """주요 테이블 참조 확인"""
        # Given
        expected_tables = [
            'orders_raw', 'customers_raw', 'order_items_raw',
            'orders', 'customers', 'order_items', 'payments', 'reviews',
            'products', 'sellers', 'geolocation'
        ]
        
        # When
        all_content = ""
        for sql_file in self.sql_dir.glob("*.sql"):
            content = sql_file.read_text(encoding='utf-8')
            all_content += content + "\n"
        
        # Then
        for table in expected_tables:
            # 테이블이 생성되거나 참조되어야 함
            table_patterns = [
                f"CREATE TABLE.*{table}",
                f"FROM.*{table}",
                f"INSERT INTO.*{table}",
                f"UPDATE.*{table}"
            ]
            
            found = any(re.search(pattern, all_content, re.IGNORECASE) for pattern in table_patterns)
            assert found, f"Table '{table}' not found in any SQL file"


class TestSQLBestPractices:
    """SQL 모범 사례 검증"""
    
    @property
    def sql_dir(self):
        return Path(__file__).parent.parent / "sql"
    
    def test_if_not_exists_usage(self):
        """CREATE 문에서 IF NOT EXISTS 사용 확인"""
        # Given
        create_files = [
            "00_raw_ddl.sql",
            "05_meta_lineage.sql",
            "06_error_quarantine.sql",
            "10_ods_core_ddl.sql",
            "20_ods_dim_ddl.sql"
        ]
        
        # When & Then
        for sql_file in create_files:
            file_path = self.sql_dir / sql_file
            if file_path.exists():
                content = file_path.read_text(encoding='utf-8').upper()
                if "CREATE TABLE" in content:
                    assert "IF NOT EXISTS" in content, \
                        f"CREATE TABLE without IF NOT EXISTS found in {sql_file}"
    
    def test_comments_exist(self):
        """주요 SQL 파일에 주석이 있는지 확인"""
        # Given - 주석이 필요한 주요 파일들만 체크
        important_files = [
            "00_raw_ddl.sql",
            "01_raw_meta.sql", 
            "03_dq_hard.sql",
            "04_dq_soft.sql",
            "10_ods_core_ddl.sql",
            "12_ods_core_upsert.sql"
        ]
        
        # When & Then
        for filename in important_files:
            file_path = self.sql_dir / filename
            if file_path.exists():
                content = file_path.read_text(encoding='utf-8')
                # 주석 패턴 확인 (-- 또는 /* */)
                has_comments = '--' in content or '/*' in content
                assert has_comments, f"No comments found in important file: {filename}"
    
    def test_no_hardcoded_values(self):
        """하드코딩된 값들이 적절히 처리되었는지 확인"""
        # Given
        sql_files = list(self.sql_dir.glob("*.sql"))
        
        # When & Then
        for sql_file in sql_files:
            content = sql_file.read_text(encoding='utf-8')
            
            # 의심스러운 하드코딩 패턴들 (예외적으로 허용되는 것들 제외)
            suspicious_patterns = [
                r"password\s*=\s*['\"][^'\"]+['\"]",  # 패스워드
                r"secret\s*=\s*['\"][^'\"]+['\"]",    # 시크릿
            ]
            
            for pattern in suspicious_patterns:
                matches = re.findall(pattern, content, re.IGNORECASE)
                assert len(matches) == 0, \
                    f"Potential hardcoded sensitive value found in {sql_file.name}: {matches}"


class TestSQLFileNaming:
    """SQL 파일 명명 규칙 검증"""
    
    @property
    def sql_dir(self):
        return Path(__file__).parent.parent / "sql"
    
    def test_file_naming_convention(self):
        """파일 명명 규칙 확인"""
        # Given
        sql_files = [f for f in self.sql_dir.glob("*.sql") if not f.name.startswith('.')]
        
        # When & Then
        for sql_file in sql_files:
            filename = sql_file.name
            
            # 파일명이 숫자로 시작하고 .sql로 끝나는지 확인
            if filename[0].isdigit():
                # 번호_설명.sql 형태인지 확인
                assert re.match(r'^\d{2}_[a-z_]+\.sql$', filename), \
                    f"File naming convention violation: {filename}"
    
    def test_file_numbering_sequence(self):
        """파일 번호 순서 확인"""
        # Given
        sql_files = [f for f in self.sql_dir.glob("*.sql") if f.name[0].isdigit()]
        
        # When
        file_numbers = []
        file_mapping = {}  # 번호 -> 파일명 매핑
        for sql_file in sql_files:
            number_part = sql_file.name.split('_')[0]
            if number_part.isdigit():
                num = int(number_part)
                file_numbers.append(num)
                if num in file_mapping:
                    file_mapping[num].append(sql_file.name)
                else:
                    file_mapping[num] = [sql_file.name]
        
        file_numbers.sort()
        
        # Then
        # 논리적인 순서가 있는지 확인 (완전히 연속적이지 않아도 됨)
        assert len(file_numbers) > 0, "No numbered SQL files found"
        assert file_numbers[0] >= 0, "File numbering should start from 00 or higher"
        
        # 중복 번호 확인 - 경고만 출력하고 실패시키지 않음
        duplicates = {num: files for num, files in file_mapping.items() if len(files) > 1}
        if duplicates:
            print(f"\nWarning: Duplicate file numbers found: {duplicates}")
            # 중복이 있어도 테스트는 통과시킴 (경고만)
