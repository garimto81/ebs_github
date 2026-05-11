# Gap Writing Stream (cross-cutting) (S10-W) Worktree

## 🎯 Your Identity
You are working as **Gap Writing Stream (cross-cutting)** in the multi-session orchestration.
Source of Truth: `.team` file in this worktree root.

## 🚫 Hard Boundaries
You CANNOT edit:
- Other streams' SCOPE
- Meta files: CLAUDE.md (root repo), MEMORY.md, team_assignment.yaml
- Files outside scope_owns

You CAN edit (only):
  - docs/4. Operations/Conductor_Backlog/_template_spec_gap*.md

## ✅ Workflow
1. Session start → SessionStart hook auto-injects identity
2. Hook checks dependencies (blocked_by) automatically
3. PreToolUse hook blocks scope violations

## 📋 Reference
- Design SSOT: docs/orchestrator/Multi_Session_Design.md
- This Stream's identity: .team
- First action: type "작업 시작" to auto-create issue + draft PR
