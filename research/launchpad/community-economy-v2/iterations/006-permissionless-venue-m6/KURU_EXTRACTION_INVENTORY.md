# Owner-requested Kuru extraction — dependency inventory

2026-11-05 owner explicitly requested all active Kuru venue smart-contract implementation be moved into legacy/. This supersedes the initial admission-only scope. Not deployment or protected merge approval.

Active core Factory and Coordinator contain no direct Kuru imports. Implementations to quarantine: KuruEnvironmentV2, KuruGraduationExecutorV2, KuruLiquidityLockV2, libraries/KuruParameterPolicyV2, interfaces/IKuruV2. Preserve the existing venue wire value1 as a reserved legacy value; do not compact/renumber serialized enums.

Review dependencies across original unit/fork/custody fixtures and DeployV2MonadTestnet before moving. Keep historical frozen source references, release evidence/manifests and live deployment identities unchanged. New V4 environment must never construct or validate Kuru. Legacy custody and retry regressions must execute against the retained legacy implementation and admission policy. No active-source compatibility shim may secretly reintroduce Kuru as a new-launch dependency.

Execution gate: finish CI repair evidence first; independent security reviewer supplies migration/ABI packet; extraction then requires compilation, legacy custody/retry tests and active V4-only admission negatives. Source movement changes compiler metadata and potentially CREATE2 creation-code hashes: never claim a moved rebuilt artifact is byte-identical to an already deployed artifact. Use pinned historical sources for historical deployment reproduction.
