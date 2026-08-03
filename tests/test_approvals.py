from omniterm.approvals import ApprovalDecision, CommandApprovalPolicy


def test_allows_read_only_git_commands() -> None:
    policy = CommandApprovalPolicy()

    assert policy.evaluate("git status").decision is ApprovalDecision.ALLOW
    assert policy.evaluate("git diff --stat").decision is ApprovalDecision.ALLOW


def test_requires_approval_for_git_writes() -> None:
    policy = CommandApprovalPolicy()

    assert policy.evaluate("git commit -am test").decision is ApprovalDecision.ASK
    assert policy.evaluate("git push origin main").decision is ApprovalDecision.ASK


def test_denies_privileged_and_destructive_commands() -> None:
    policy = CommandApprovalPolicy()

    assert policy.evaluate("sudo apt update").decision is ApprovalDecision.DENY
    assert policy.evaluate("rm -rf /").decision is ApprovalDecision.DENY


def test_unknown_commands_require_approval() -> None:
    policy = CommandApprovalPolicy()

    assert policy.evaluate("some-new-tool scan").decision is ApprovalDecision.ASK
