"""Tests for DailyDashboard - Integration tests"""

import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock
import sys
import json

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / "scripts"))

from daily_dashboard import DailyDashboard, SecretaryResult, DashboardState


class TestSecretaryResult:
    """SecretaryResult tests"""

    def test_from_json(self):
        """JSON에서 생성"""
        data = {
            "gmail": {"tasks": [{"subject": "Test"}]},
            "calendar": {"events": []},
            "github": {"attention_needed": []},
            "generated_at": "2026-02-05T10:00:00",
        }
        result = SecretaryResult.from_json(data)

        assert result.gmail == {"tasks": [{"subject": "Test"}]}
        assert result.calendar == {"events": []}
        assert result.generated_at == "2026-02-05T10:00:00"

    def test_empty_with_warning(self):
        """빈 결과 + 경고"""
        result = SecretaryResult.empty("Test warning")

        assert result.gmail == {}
        assert result.warnings == ["Test warning"]


class TestDailyDashboard:
    """DailyDashboard tests"""

    @pytest.fixture
    def dashboard(self, tmp_path):
        """임시 경로 기반 대시보드"""
        return DailyDashboard(base_path=tmp_path)

    @pytest.fixture
    def mock_secretary_result(self):
        """Mock Secretary 결과"""
        return SecretaryResult(
            gmail={
                "tasks": [
                    {"subject": "계약서 검토", "priority": "urgent", "from": "김대표"},
                    {"subject": "회의록 확인", "priority": "medium", "from": "이팀장"},
                ]
            },
            calendar={
                "events": [
                    {"title": "팀 스탠드업", "start": "10:00", "location": "Google Meet"},
                    {"title": "클라이언트 미팅", "start": "14:00", "location": "회의실 A"},
                ],
                "needs_prep": [
                    {"title": "클라이언트 미팅", "start": "14:00"},
                ],
            },
            github={
                "attention_needed": [
                    {"type": "PR", "number": 42, "repo": "secretary", "reason": "Review pending 3 days"},
                ]
            },
            generated_at="2026-02-05T09:00:00",
        )

    def test_run_default_with_projects(self, dashboard, tmp_path):
        """기본 대시보드 - 프로젝트만"""
        # Setup checklist
        checklists_dir = tmp_path / "docs" / "checklists"
        checklists_dir.mkdir(parents=True)
        (checklists_dir / "PRD-0001.md").write_text(
            "# [PRD-0001] 인증 시스템\n**Status**: In Progress\n- [x] Done\n- [ ] Pending",
            encoding="utf-8",
        )

        # Execute without personal (secretary not available)
        output = dashboard.run(include_personal=False)

        # Verify
        assert "Daily Dashboard" in output
        assert "PRD-0001" in output
        assert "50%" in output  # 1/2 완료

    def test_run_projects_only(self, dashboard, tmp_path):
        """프로젝트만 출력"""
        checklists_dir = tmp_path / "docs" / "checklists"
        checklists_dir.mkdir(parents=True)
        (checklists_dir / "PRD-0001.md").write_text(
            "# [PRD-0001] Test\n- [x] Done",
            encoding="utf-8",
        )

        output = dashboard.run(subcommand="projects")

        assert "Project Progress" in output
        assert "PRD-0001" in output
        assert "100%" in output

    def test_run_json_output(self, dashboard, tmp_path):
        """JSON 출력"""
        checklists_dir = tmp_path / "docs" / "checklists"
        checklists_dir.mkdir(parents=True)
        (checklists_dir / "PRD-0001.md").write_text(
            "# [PRD-0001] Test\n- [x] Done\n- [ ] Pending",
            encoding="utf-8",
        )

        output = dashboard.run(json_output=True, include_personal=False)
        data = json.loads(output)

        assert "generated_at" in data
        assert "projects" in data
        assert len(data["projects"]["projects"]) == 1
        assert data["projects"]["projects"][0]["prd_id"] == "PRD-0001"
        assert data["projects"]["projects"][0]["progress"] == 50.0

    @patch.object(DailyDashboard, "_call_secretary")
    def test_run_default_full(self, mock_secretary, dashboard, tmp_path, mock_secretary_result):
        """전체 대시보드 (Personal + Projects)"""
        mock_secretary.return_value = mock_secretary_result

        checklists_dir = tmp_path / "docs" / "checklists"
        checklists_dir.mkdir(parents=True)
        (checklists_dir / "PRD-0001.md").write_text(
            "# [PRD-0001] 인증 시스템\n- [x] Done\n- [x] Done\n- [x] Done\n- [ ] Pending",
            encoding="utf-8",
        )

        output = dashboard.run()

        # Personal section
        assert "[Personal]" in output
        assert "계약서 검토" in output
        assert "팀 스탠드업" in output
        assert "PR #42" in output

        # Projects section
        assert "[Projects]" in output
        assert "PRD-0001" in output
        assert "75%" in output

    @patch.object(DailyDashboard, "_call_secretary")
    def test_run_standup(self, mock_secretary, dashboard, tmp_path, mock_secretary_result):
        """아침 브리핑"""
        mock_secretary.return_value = mock_secretary_result

        checklists_dir = tmp_path / "docs" / "checklists"
        checklists_dir.mkdir(parents=True)
        (checklists_dir / "PRD-0001.md").write_text(
            "# [PRD-0001] Test\n- [x] Done\n- [ ] Pending",
            encoding="utf-8",
        )

        output = dashboard.run(subcommand="standup")

        assert "Good Morning!" in output
        assert "[Today's Focus]" in output
        assert "[Schedule]" in output
        assert "[Project Blockers]" in output
        assert "Have a productive day!" in output

    @patch.object(DailyDashboard, "_call_secretary")
    def test_run_retro(self, mock_secretary, dashboard, tmp_path, mock_secretary_result):
        """저녁 회고"""
        mock_secretary.return_value = mock_secretary_result

        checklists_dir = tmp_path / "docs" / "checklists"
        checklists_dir.mkdir(parents=True)
        (checklists_dir / "PRD-0001.md").write_text(
            "# [PRD-0001] Test\n- [x] Done\n- [ ] Pending",
            encoding="utf-8",
        )

        output = dashboard.run(subcommand="retro")

        assert "Day Review" in output
        assert "[Still Pending]" in output
        assert "[Project Progress]" in output
        assert "[Tomorrow's Priority]" in output

    def test_graceful_degradation_no_secretary(self, dashboard, tmp_path):
        """Secretary 없이도 프로젝트 출력"""
        # Secretary 스크립트 없는 상태
        checklists_dir = tmp_path / "docs" / "checklists"
        checklists_dir.mkdir(parents=True)
        (checklists_dir / "PRD-0001.md").write_text(
            "# [PRD-0001] Test\n- [x] Done",
            encoding="utf-8",
        )

        output = dashboard.run()

        # 경고 있어도 프로젝트는 표시
        assert "PRD-0001" in output
        assert "100%" in output

    def test_graceful_degradation_no_checklists(self, dashboard, tmp_path):
        """Checklist 없어도 에러 안남"""
        output = dashboard.run(include_personal=False)

        assert "Daily Dashboard" in output
        # 프로젝트 섹션이 비어있어도 에러 없음

    def test_exclude_personal(self, dashboard, tmp_path):
        """개인 업무 제외"""
        checklists_dir = tmp_path / "docs" / "checklists"
        checklists_dir.mkdir(parents=True)
        (checklists_dir / "PRD-0001.md").write_text(
            "# [PRD-0001] Test\n- [x] Done",
            encoding="utf-8",
        )

        output = dashboard.run(include_personal=False)

        assert "[Personal]" not in output
        assert "[Projects]" in output

    def test_exclude_projects(self, dashboard, tmp_path):
        """프로젝트 제외"""
        output = dashboard.run(include_projects=False, include_personal=False)

        assert "[Projects]" not in output


class TestProgressBar:
    """Progress bar formatting tests"""

    @pytest.fixture
    def dashboard(self, tmp_path):
        return DailyDashboard(base_path=tmp_path)

    def test_progress_bar_0_percent(self, dashboard, tmp_path):
        """0% 진행률"""
        checklists_dir = tmp_path / "docs" / "checklists"
        checklists_dir.mkdir(parents=True)
        (checklists_dir / "PRD-0001.md").write_text(
            "# [PRD-0001] Test\n- [ ] Pending",
            encoding="utf-8",
        )

        output = dashboard.run(subcommand="projects")
        assert "  0%" in output

    def test_progress_bar_100_percent(self, dashboard, tmp_path):
        """100% 진행률"""
        checklists_dir = tmp_path / "docs" / "checklists"
        checklists_dir.mkdir(parents=True)
        (checklists_dir / "PRD-0001.md").write_text(
            "# [PRD-0001] Test\n- [x] Done",
            encoding="utf-8",
        )

        output = dashboard.run(subcommand="projects")
        assert "100%" in output

    def test_multiple_projects(self, dashboard, tmp_path):
        """여러 프로젝트"""
        checklists_dir = tmp_path / "docs" / "checklists"
        checklists_dir.mkdir(parents=True)
        (checklists_dir / "PRD-0001.md").write_text(
            "# [PRD-0001] First\n- [x] Done\n- [x] Done",
            encoding="utf-8",
        )
        (checklists_dir / "PRD-0002.md").write_text(
            "# [PRD-0002] Second\n- [ ] Pending\n- [ ] Pending",
            encoding="utf-8",
        )

        output = dashboard.run(subcommand="projects")

        assert "PRD-0001" in output
        assert "PRD-0002" in output
        assert "100%" in output  # PRD-0001
        assert "  0%" in output  # PRD-0002
        assert "50% average" in output  # 전체 평균
