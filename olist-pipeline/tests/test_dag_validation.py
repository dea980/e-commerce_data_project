"""
DAG 구조 및 설정 검증 테스트
"""
import pytest
from unittest.mock import patch, Mock
import sys
from pathlib import Path
from datetime import datetime, timedelta

# DAG 모듈 경로 추가
sys.path.append(str(Path(__file__).parent.parent / "dag"))


class TestDAGStructure:
    """DAG 구조 검증 테스트"""
    
    @patch('dag.raw_to_ods.PostgresHook')
    @patch('dag.raw_to_ods.read_sql')
    def test_raw_to_ods_dag_structure(self, mock_read_sql, mock_postgres_hook):
        """raw_to_ods DAG 구조 검증"""
        # Given
        mock_read_sql.return_value = "SELECT 1;"
        mock_hook = Mock()
        mock_postgres_hook.return_value = mock_hook
        
        # When - DAG 임포트
        from raw_to_ods import dag
        
        # Then
        assert dag.dag_id == "raw_to_ods"
        assert dag.schedule_interval is None
        assert dag.catchup is False
        assert len(dag.tags) == 3
        assert "olist" in dag.tags
        assert "ods" in dag.tags
        assert "core" in dag.tags
    
    def test_raw_to_ods_task_dependencies(self):
        """raw_to_ods DAG 태스크 의존성 검증"""
        # When
        from raw_to_ods import dag
        
        # Then - 태스크 존재 확인
        task_ids = [task.task_id for task in dag.tasks]
        expected_tasks = [
            "sql__10_ods_core_ddl",
            "sql__11_ods_core_indexes", 
            "sql__12_ods_core_upsert",
            "sql__03_dq_hard",
            "sql__04_dq_soft",
            "trigger__ods_dim"
        ]
        
        for expected_task in expected_tasks:
            assert expected_task in task_ids
        
        # 의존성 확인
        ddl_task = dag.get_task("sql__10_ods_core_ddl")
        indexes_task = dag.get_task("sql__11_ods_core_indexes")
        upsert_task = dag.get_task("sql__12_ods_core_upsert")
        dq_hard_task = dag.get_task("sql__03_dq_hard")
        
        # DDL → Indexes → Upsert → DQ Hard 순서 확인
        assert indexes_task in ddl_task.downstream_list
        assert upsert_task in indexes_task.downstream_list
        assert dq_hard_task in upsert_task.downstream_list
    
    def test_ods_dim_dag_structure(self):
        """ods_dim DAG 구조 검증"""
        # When
        from ods_dim import dag
        
        # Then
        assert dag.dag_id == "ods_dim"
        assert dag.schedule_interval is None
        assert dag.catchup is False
        assert "dim" in dag.tags
        
        # 태스크 확인
        task_ids = [task.task_id for task in dag.tasks]
        expected_tasks = [
            "sql__20_ods_dim_ddl",
            "sql__21_ods_dim_indexes",
            "sql__22_ods_dim_upsert"
        ]
        
        for expected_task in expected_tasks:
            assert expected_task in task_ids


class TestDAGConfiguration:
    """DAG 설정 검증 테스트"""
    
    def test_dag_default_args(self):
        """DAG 기본 인수 검증"""
        # When
        from raw_to_ods import dag
        
        # Then
        default_args = dag.default_args
        assert default_args["owner"] == "data-eng"
        assert default_args["retries"] == 1
        assert default_args["retry_delay"] == timedelta(minutes=3)
    
    def test_dag_start_date(self):
        """DAG 시작일 검증"""
        # When
        from raw_to_ods import dag
        
        # Then
        assert dag.start_date == datetime(2025, 1, 1)
    
    def test_dag_callbacks_configured(self):
        """DAG 콜백 설정 검증"""
        # When
        from raw_to_ods import dag
        
        # Then
        assert dag.on_failure_callback is not None
        assert dag.on_success_callback is not None


class TestTaskConfiguration:
    """태스크 설정 검증 테스트"""
    
    @patch('dag.raw_to_ods.get_current_context')
    @patch('dag.raw_to_ods.PostgresHook')
    @patch('dag.raw_to_ods.read_sql')
    def test_batch_id_replacement(self, mock_read_sql, mock_postgres_hook, mock_context):
        """배치 ID 치환 로직 테스트"""
        # Given
        mock_read_sql.return_value = "INSERT INTO table VALUES ('{{BATCH_ID}}');"
        mock_hook = Mock()
        mock_postgres_hook.return_value = mock_hook
        
        mock_dag_run = Mock()
        mock_dag_run.conf = {"batch_id": "test-batch-456"}
        mock_context.return_value = {"dag_run": mock_dag_run}
        
        # When
        from raw_to_ods import dag
        dq_hard_task = dag.get_task("sql__03_dq_hard")
        
        # 태스크 실행 (실제로는 Airflow에서 실행됨)
        # 여기서는 함수 직접 호출로 테스트
        task_callable = dq_hard_task.python_callable
        result = task_callable("03_dq_hard")
        
        # Then
        expected_sql = "INSERT INTO table VALUES ('test-batch-456');"
        mock_hook.run.assert_called_once_with(expected_sql, autocommit=True)
        assert result == "test-batch-456"
    
    @patch('dag.raw_to_ods.PostgresHook')
    @patch('dag.raw_to_ods.read_sql')
    def test_regular_sql_execution(self, mock_read_sql, mock_postgres_hook):
        """일반 SQL 실행 테스트"""
        # Given
        mock_read_sql.return_value = "CREATE TABLE test (id INT);"
        mock_hook = Mock()
        mock_postgres_hook.return_value = mock_hook
        
        # When
        from raw_to_ods import dag
        ddl_task = dag.get_task("sql__10_ods_core_ddl")
        
        task_callable = ddl_task.python_callable
        result = task_callable("10_ods_core_ddl")
        
        # Then
        mock_hook.run.assert_called_once_with("CREATE TABLE test (id INT);", autocommit=True)
        assert result == "10_ods_core_ddl"


class TestDAGValidation:
    """DAG 유효성 검증 테스트"""
    
    def test_dag_has_no_cycles(self):
        """DAG에 순환 의존성이 없는지 확인"""
        # When
        from raw_to_ods import dag
        
        # Then - Airflow가 내부적으로 순환 의존성을 체크하지만, 명시적 검증
        try:
            # DAG의 모든 태스크에 대해 downstream을 추적
            visited = set()
            
            def check_cycles(task, path):
                if task.task_id in path:
                    raise ValueError(f"Cycle detected: {' -> '.join(path)} -> {task.task_id}")
                
                if task.task_id in visited:
                    return
                
                visited.add(task.task_id)
                new_path = path + [task.task_id]
                
                for downstream_task in task.downstream_list:
                    check_cycles(downstream_task, new_path)
            
            for task in dag.tasks:
                if not task.upstream_list:  # 루트 태스크부터 시작
                    check_cycles(task, [])
            
        except ValueError as e:
            pytest.fail(f"DAG has cycles: {e}")
    
    def test_dag_task_count(self):
        """DAG 태스크 수 검증"""
        # When
        from raw_to_ods import dag
        
        # Then
        assert len(dag.tasks) == 6  # 예상 태스크 수
    
    def test_trigger_dag_configuration(self):
        """트리거 DAG 설정 검증"""
        # When
        from raw_to_ods import dag
        trigger_task = dag.get_task("trigger__ods_dim")
        
        # Then
        assert trigger_task.trigger_dag_id == "ods_dim"
        assert trigger_task.wait_for_completion is False
        assert trigger_task.reset_dag_run is True
