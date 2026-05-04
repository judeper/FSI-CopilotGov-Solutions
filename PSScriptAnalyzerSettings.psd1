@{
    # PSScriptAnalyzer settings for FSI-CopilotGov-Solutions.
    #
    # Strategy: include all built-in rules, then suppress a small,
    # justified set of rules that conflict with this repository's
    # documentation-first scaffold posture.
    IncludeDefaultRules = $true
    Severity            = @('Error', 'Warning', 'Information')

    # Globally excluded rules (applies to every file scanned).
    #
    # PSAvoidUsingWriteHost:
    #   The solutions/**/scripts/** files are documentation-first scaffolds
    #   intended to be read and demonstrated to operators at the console.
    #   They use Write-Host deliberately for human-facing, color-coded
    #   progress output rather than as a return channel. Per-path
    #   suppression is not supported by the engine's Settings file
    #   schema, so this rule is excluded globally and reviewers should
    #   continue to flag Write-Host usage outside solutions/**/scripts/**
    #   during code review.
    #
    # PSUseShouldProcessForStateChangingFunctions:
    #   The sample/scaffold scripts shipped here use verbs like New-,
    #   Set-, Remove- to illustrate intent, but they do not connect to
    #   live Microsoft 365 services (representative sample data only).
    #   Requiring SupportsShouldProcess on every scaffold function would
    #   add ceremony without adding safety in this documentation-first
    #   context.
    ExcludeRules        = @(
        'PSAvoidUsingWriteHost',
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
