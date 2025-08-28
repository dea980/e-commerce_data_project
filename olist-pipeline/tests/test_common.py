"""
_common.py 모듈의 단위 테스트
"""
import pytest
from unittest.mock import Mock, patch
from pathlib import Path
import sys
import os

# DAG 모듈 경로 추가
sys.path.append(str(Path(__file__).parent.parent / "dag"))

from _common import run_sql_file, _run_sql, sql_task


class TestSQLFileReading:
    """SQL 파일 읽기 테스트"""
    
    def test_run_sql_file_success(self, temp_sql_dir):
        """SQL 파일 읽기 및 실행 성공 케이스"""
        # Given
        sql_content = "SELECT * FROM test_table;"
        sql_file = temp_sql_dir / "test.sql"
        sql_file.write_text(sql_content, encoding='utf-8')
        
        mock_conn_uri = "postgresql://test:test@localhost:5432/testdb"
        
        # When/Then
        with patch('_common.SQL_BASE_DIR', str(temp_sql_dir)):
            with patch('_common._run_sql') as mock_run_sql:
                run_sql_file(mock_conn_uri, "test.sql")
                mock_run_sql.assert_called_once_with(mock_conn_uri, sql_content, {})
    
    def test_run_sql_file_not_found(self, temp_sql_dir):
        """SQL 파일이 존재하지 않는 경우"""
        # Given
        mock_conn_uri = "postgresql://test:test@localhost:5432/testdb"
        
        # When/Then
        with patch('_common.SQL_BASE_DIR', str(temp_sql_dir)):
            with pytest.raises(FileNotFoundError):
                run_sql_file(mock_conn_uri, "nonexistent.sql")
    
    def test_sql_file_encoding_handling(self, temp_sql_dir):
        """한글이 포함된 SQL 파일 처리"""
        # Given
        sql_content = "-- 주문 테이블 조회\nSELECT * FROM orders;"
        sql_file = temp_sql_dir / "korean_test.sql"
        sql_file.write_text(sql_content, encoding='utf-8')
        
        mock_conn_uri = "postgresql://test:test@localhost:5432/testdb"
        
        # When
        with patch('_common.SQL_BASE_DIR', str(temp_sql_dir)):
            with patch('_common._run_sql') as mock_run_sql:
                run_sql_file(mock_conn_uri, "korean_test.sql")
                
                # Then
                called_sql = mock_run_sql.call_args[0][1]
                assert "주문 테이블" in called_sql


class TestSQLExecution:
    """SQL 실행 관련 테스트"""
    
    @patch('_common.psycopg2.connect')
    def test_run_sql_execution(self, mock_connect):
        """SQL 실행 테스트"""
        # Given
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_connect.return_value.__enter__.return_value = mock_conn
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        
        conn_uri = "postgresql://test:test@localhost:5432/testdb"
        sql_text = "SELECT 1;"
        params = {"param1": "value1"}
        
        # When
        _run_sql(conn_uri, sql_text, params)
        
        # Then
        mock_connect.assert_called_once_with(conn_uri)
        mock_conn.__setattr__.assert_called_with('autocommit', True)
        mock_cursor.execute.assert_called_once_with(sql_text, params)


class TestSQLTask:
    """SQL 태스크 생성 테스트"""
    
    @patch('_common.os.environ.get')
    def test_sql_task_creation(self, mock_env_get):
        """SQL 태스크 생성 테스트"""
        # Given
        mock_env_get.return_value = "postgresql://test:test@localhost:5432/testdb"
        mock_dag = Mock()
        
        # When
        task = sql_task(mock_dag, "test_task", "test.sql")
        
        # Then
        assert task.task_id == "test_task"
        assert task.python_callable is not None
        mock_env_get.assert_called_with("AIRFLOW_CONN_POSTGRES_DEFAULT")
    
    @patch('_common.os.environ.get')
    def test_sql_task_missing_connection(self, mock_env_get):
        """연결 정보가 없는 경우 예외 발생 테스트"""
        # Given
        mock_env_get.return_value = None
        mock_dag = Mock()
        
        # When/Then
        with pytest.raises(RuntimeError, match="AIRFLOW_CONN_POSTGRES_DEFAULT is not set"):
            sql_task(mock_dag, "test_task", "test.sql")
