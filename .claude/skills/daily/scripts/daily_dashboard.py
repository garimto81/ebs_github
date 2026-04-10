"""Daily Dashboard - 개인 업무 + 프로젝트 진행률 통합 대시보드

/secretary와 Slack List Checklist를 결합한 통합 현황 대시보드
"""

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional
import argparse
import json
import subprocess
import sys

from checklist_parser import ChecklistParser, ChecklistResult


@dataclass
class SecretaryResult:
    """Secretary 스크립트 결과"""

    gmail: dict = field(default_factory=dict)
    calendar: dict = field(default_factory=dict)
    github: dict = field(default_factory=dict)
    generated_at: str = ""
    warnings: list[str] = field(default_factory=list)

    @classmethod
    def from_json(cls, data: dict) -> "SecretaryResult":
        """JSON 딕셔너리에서 생성"""
        return cls(
            gmail=data.get("gmail", {}),
            calendar=data.get("calendar", {}),
            github=data.get("github", {}),
            generated_at=data.get("generated_at", datetime.now().isoformat()),
            warnings=data.get("warnings", []),
        )

    @classmethod
    def empty(cls, warning: str = None) -> "SecretaryResult":
        """빈 결과 (에러 시 fallback)"""
        return cls(
            gmail={},
            calendar={},
            github={},
            generated_at=datetime.now().isoformat(),
            warnings=[warning] if warning else [],
        )


@dataclass
class DashboardState:
    """통합 대시보드 상태"""

    personal: SecretaryResult
    projects: ChecklistResult
    generated_at: str
    warnings: list[str] = field(default_factory=list)


class DailyDashboard:
    """통합 대시보드 메인 클래스"""

    SECRETARY_SCRIPT = Path(__file__).parent.parent.parent / "secretary" / "scripts" / "daily_report.py"

    def __init__(self, base_path: Path = None):
        self.base_path = base_path or Path("C:/claude")
        self.parser = ChecklistParser(self.base_path)

    def run(
        self,
        subcommand: str = None,
        json_output: bool = False,
        include_personal: bool = True,
        include_projects: bool = True,
    ) -> str:
        """
        대시보드 실행

        Args:
            subcommand: None (기본), "standup", "retro", "projects"
            json_output: JSON 형식 출력
            include_personal: 개인 업무 포함
            include_projects: 프로젝트 포함

        Returns:
            포맷된 출력 문자열
        """
        state = self._get_state(include_personal, include_projects)

        if json_output:
            return self._format_json(state)

        if subcommand == "standup":
            return self._format_standup(state)
        elif subcommand == "retro":
            return self._format_retro(state)
        elif subcommand == "projects":
            return self._format_projects(state)
        else:
            return self._format_default(state)

    def _get_state(
        self,
        include_personal: bool = True,
        include_projects: bool = True,
    ) -> DashboardState:
        """전체 상태 수집"""
        personal = SecretaryResult.empty()
        projects = ChecklistResult(projects=[], scan_paths=[], scanned_at="")
        warnings = []

        # 1. Secretary 호출 (실패해도 계속)
        if include_personal:
            try:
                personal = self._call_secretary()
                if personal.warnings:
                    warnings.extend(personal.warnings)
            except Exception as e:
                warnings.append(f"Personal data unavailable: {e}")
                personal = SecretaryResult.empty(str(e))

        # 2. Checklist 스캔 (실패해도 계속)
        if include_projects:
            try:
                projects = self.parser.scan()
            except Exception as e:
                warnings.append(f"Checklist scan failed: {e}")

        return DashboardState(
            personal=personal,
            projects=projects,
            warnings=warnings,
            generated_at=datetime.now().isoformat(),
        )

    def _call_secretary(self, sources: list[str] = None) -> SecretaryResult:
        """Secretary 스크립트 호출"""
        if not self.SECRETARY_SCRIPT.exists():
            return SecretaryResult.empty("Secretary script not found")

        cmd = [sys.executable, str(self.SECRETARY_SCRIPT), "--json"]
        if sources:
            for src in sources:
                cmd.append(f"--{src}")

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30,
                cwd=self.base_path,
            )
            if result.returncode == 0 and result.stdout:
                data = json.loads(result.stdout)
                return SecretaryResult.from_json(data)
            else:
                return SecretaryResult.empty(result.stderr or "Secretary failed")
        except subprocess.TimeoutExpired:
            return SecretaryResult.empty("Secretary timeout")
        except json.JSONDecodeError:
            return SecretaryResult.empty("Invalid JSON from secretary")
        except Exception as e:
            return SecretaryResult.empty(str(e))

    def _format_default(self, state: DashboardState) -> str:
        """기본 대시보드 포맷"""
        now = datetime.now()
        weekday = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][now.weekday()]
        date_str = now.strftime(f"%Y-%m-%d {weekday}")

        lines = [
            "=" * 80,
            f"{'Daily Dashboard (' + date_str + ')':^80}",
            "=" * 80,
            "",
        ]

        # 경고 메시지
        for warning in state.warnings:
            lines.append(f"[!] Warning: {warning}")
        if state.warnings:
            lines.append("")

        # Personal 섹션
        if state.personal.gmail or state.personal.calendar or state.personal.github:
            lines.append("[Personal] " + "-" * 56)
            lines.extend(self._format_personal_section(state.personal))
            lines.append("")

        # Projects 섹션
        if state.projects.projects:
            lines.append("[Projects] " + "-" * 56)
            lines.extend(self._format_projects_section(state.projects))
            lines.append("")

        lines.append("=" * 80)
        return "\n".join(lines)

    def _format_personal_section(self, personal: SecretaryResult) -> list[str]:
        """개인 업무 섹션 포맷"""
        lines = []

        # Gmail
        gmail = personal.gmail
        if gmail:
            tasks = gmail.get("tasks", [])
            unanswered = gmail.get("unanswered", [])
            total = len(tasks) + len(unanswered)
            lines.append(f"  Email ({total} action items)")
            for task in tasks[:3]:  # 상위 3개만
                priority = task.get("priority", "MEDIUM")
                subject = task.get("subject", "No subject")[:40]
                sender = task.get("from", "Unknown")
                lines.append(f"    * [{priority.upper()}] {subject} (from: {sender})")
            if len(tasks) > 3:
                lines.append(f"    ... and {len(tasks) - 3} more")
            lines.append("")

        # Calendar
        calendar = personal.calendar
        if calendar:
            events = calendar.get("events", [])
            needs_prep = calendar.get("needs_prep", [])
            lines.append(f"  Calendar ({len(events)} events)")
            for event in events[:3]:
                time = event.get("start", "")[:5] if event.get("start") else ""
                title = event.get("title", "Untitled")[:40]
                location = event.get("location", "")
                if location:
                    lines.append(f"    * {time} {title} ({location})")
                else:
                    lines.append(f"    * {time} {title}")
            lines.append("")

        # GitHub
        github = personal.github
        if github:
            attention = github.get("attention_needed", [])
            lines.append(f"  GitHub ({len(attention)} attention needed)")
            for item in attention[:3]:
                item_type = item.get("type", "item")
                number = item.get("number", "?")
                repo = item.get("repo", "unknown")
                reason = item.get("reason", "needs attention")
                lines.append(f"    * {item_type} #{number} ({repo}): {reason}")

        return lines

    def _format_projects_section(self, projects: ChecklistResult) -> list[str]:
        """프로젝트 섹션 포맷"""
        lines = []
        total_items = 0
        completed_items = 0

        for project in projects.projects:
            # Progress bar: 14자 (70% = 10, 80% = 11, etc.)
            filled = int(project.progress / 100 * 14)
            bar = "=" * filled + (">" if filled < 14 else "") + " " * (14 - filled - 1)

            status = f"[{bar}]"
            pct = f"{project.progress:3.0f}%"

            # 제목에서 PRD ID 제거
            title = project.title
            if title.startswith(f"[{project.prd_id}]"):
                title = title[len(project.prd_id) + 3:].strip()

            lines.append(f"  {project.prd_id}  {status} {pct}  {title[:30]}")

            total_items += project.total_items
            completed_items += project.completed_items

        # 요약
        if projects.projects:
            lines.append("")
            lines.append(f"  Overall: {projects.total_progress:.0f}% ({completed_items}/{total_items} items)")

        return lines

    def _format_standup(self, state: DashboardState) -> str:
        """아침 브리핑 포맷"""
        now = datetime.now()
        weekday = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][now.weekday()]
        date_str = now.strftime(f"%Y-%m-%d {weekday}")

        lines = [
            "=" * 80,
            f"{'Good Morning! (' + date_str + ')':^80}",
            "=" * 80,
            "",
        ]

        # Today's Focus (긴급 이메일 + 준비 필요한 일정)
        lines.append("[Today's Focus] " + "-" * 51)
        focus_items = []

        # 긴급 이메일
        gmail = state.personal.gmail
        if gmail:
            for task in gmail.get("tasks", []):
                if task.get("priority", "").lower() in ["urgent", "high"]:
                    subject = task.get("subject", "")[:50]
                    focus_items.append(f"  {len(focus_items) + 1}. [URGENT] {subject}")

        # 준비 필요한 일정
        calendar = state.personal.calendar
        if calendar:
            for event in calendar.get("needs_prep", []):
                title = event.get("title", "")[:50]
                time = event.get("start", "")[:5]
                focus_items.append(f"  {len(focus_items) + 1}. {time} {title} 준비")

        if focus_items:
            lines.extend(focus_items[:5])
        else:
            lines.append("  No urgent items - focus on project work!")
        lines.append("")

        # Schedule
        lines.append("[Schedule] " + "-" * 56)
        if calendar:
            for event in calendar.get("events", [])[:5]:
                time = event.get("start", "")[:5]
                title = event.get("title", "")[:40]
                location = event.get("location", "")
                if location:
                    lines.append(f"  {time}  {title} ({location})")
                else:
                    lines.append(f"  {time}  {title}")
        else:
            lines.append("  No events scheduled")
        lines.append("")

        # Project Blockers (미완료 항목이 있는 프로젝트)
        lines.append("[Project Blockers] " + "-" * 48)
        for project in state.projects.projects[:3]:
            if project.pending_items:
                lines.append(f"  {project.prd_id}: {len(project.pending_items)} items remaining")
                for item in project.pending_items[:2]:
                    lines.append(f"    - [ ] {item.text[:40]}")
        lines.append("")

        lines.append("=" * 80)
        lines.append("Have a productive day!")

        return "\n".join(lines)

    def _format_retro(self, state: DashboardState) -> str:
        """저녁 회고 포맷"""
        now = datetime.now()
        weekday = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][now.weekday()]
        date_str = now.strftime(f"%Y-%m-%d {weekday}")

        lines = [
            "=" * 80,
            f"{'Day Review (' + date_str + ')':^80}",
            "=" * 80,
            "",
        ]

        # Still Pending
        lines.append("[Still Pending] " + "-" * 51)
        pending_count = 0

        gmail = state.personal.gmail
        if gmail:
            for task in gmail.get("tasks", []):
                if task.get("priority", "").lower() in ["urgent", "high"]:
                    subject = task.get("subject", "")[:50]
                    lines.append(f"  * [URGENT] {subject}")
                    pending_count += 1
                    if pending_count >= 5:
                        break

        github = state.personal.github
        if github and pending_count < 5:
            for item in github.get("attention_needed", []):
                lines.append(f"  * {item.get('type', 'Item')} #{item.get('number')} still needs attention")
                pending_count += 1
                if pending_count >= 5:
                    break

        if pending_count == 0:
            lines.append("  All caught up!")
        lines.append("")

        # Project Progress
        lines.append("[Project Progress] " + "-" * 48)
        for project in state.projects.projects:
            lines.append(f"  {project.prd_id}: {project.progress:.0f}% ({project.completed_items}/{project.total_items})")
        lines.append("")

        # Tomorrow's Priority
        lines.append("[Tomorrow's Priority] " + "-" * 45)
        priority_count = 0
        for project in state.projects.projects:
            for item in project.pending_items[:2]:
                priority_count += 1
                lines.append(f"  {priority_count}. {item.text[:50]}")
                if priority_count >= 3:
                    break
            if priority_count >= 3:
                break
        if priority_count == 0:
            lines.append("  Review tomorrow's calendar and plan ahead")
        lines.append("")

        lines.append("=" * 80)

        return "\n".join(lines)

    def _format_projects(self, state: DashboardState) -> str:
        """프로젝트 진행률만 포맷"""
        now = datetime.now()
        date_str = now.strftime("%Y-%m-%d")

        lines = [
            "=" * 80,
            f"{'Project Progress (' + date_str + ')':^80}",
            "=" * 80,
            "",
        ]

        total_items = 0
        completed_items = 0
        pending_count = 0

        for project in state.projects.projects:
            # Progress bar
            filled = int(project.progress / 100 * 14)
            bar = "=" * filled + (">" if filled < 14 else "") + " " * (14 - filled - 1)

            title = project.title
            if title.startswith(f"[{project.prd_id}]"):
                title = title[len(project.prd_id) + 3:].strip()

            lines.append(f"  {project.prd_id}  [{bar}] {project.progress:3.0f}%  {title[:30]}")

            # 미완료 항목 표시
            for item in project.pending_items[:3]:
                lines.append(f"    - [ ] {item.text[:40]}")
                pending_count += 1

            lines.append("")

            total_items += project.total_items
            completed_items += project.completed_items

        # 요약
        lines.append("-" * 80)
        lines.append(
            f"  Total: {len(state.projects.projects)} projects | "
            f"{state.projects.total_progress:.0f}% average | "
            f"{total_items - completed_items} pending items"
        )
        lines.append("=" * 80)

        return "\n".join(lines)

    def _format_json(self, state: DashboardState) -> str:
        """JSON 형식 출력"""
        data = {
            "generated_at": state.generated_at,
            "warnings": state.warnings,
            "personal": {
                "gmail": state.personal.gmail,
                "calendar": state.personal.calendar,
                "github": state.personal.github,
            },
            "projects": {
                "projects": [
                    {
                        "prd_id": p.prd_id,
                        "title": p.title,
                        "status": p.status,
                        "total_items": p.total_items,
                        "completed_items": p.completed_items,
                        "progress": p.progress,
                        "pending_items": [
                            {"text": i.text, "pr_number": i.pr_number, "phase": i.phase}
                            for i in p.pending_items
                        ],
                    }
                    for p in state.projects.projects
                ],
                "total_progress": state.projects.total_progress,
            },
        }
        return json.dumps(data, indent=2, ensure_ascii=False)


def main():
    """CLI 엔트리포인트"""
    parser = argparse.ArgumentParser(
        description="Daily Dashboard - 개인 업무 + 프로젝트 통합 현황"
    )
    parser.add_argument(
        "subcommand",
        nargs="?",
        choices=["standup", "retro", "projects"],
        help="서브커맨드 (없으면 전체 대시보드)",
    )
    parser.add_argument("--json", action="store_true", help="JSON 형식 출력")
    parser.add_argument("--no-personal", action="store_true", help="개인 업무 제외")
    parser.add_argument("--no-projects", action="store_true", help="프로젝트 제외")

    args = parser.parse_args()

    dashboard = DailyDashboard()
    output = dashboard.run(
        subcommand=args.subcommand,
        json_output=args.json,
        include_personal=not args.no_personal,
        include_projects=not args.no_projects,
    )
    # Windows cp949 인코딩 문제 해결
    import sys
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    print(output)


if __name__ == "__main__":
    main()
