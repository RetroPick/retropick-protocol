# Market Research

This directory holds external market, product, and competitor research. Its
current child lane is [launchpads/](launchpads/), which studies modern
launchpad capability and UX patterns.

Market research informs product questions. It does not define RetroPick
economics, override ADRs, or establish implementation readiness.

## Claim discipline

Every observation should be labeled as:

1. **Source-derived fact**: directly evidenced by an official source capture.
2. **Inference**: reasoned from source facts but not directly stated by that
   source.
3. **RetroPick recommendation**: a proposal for RetroPick, not a fact about a
   competitor.

Historical competitor pages can drift. Record the source URL, access time,
version or commit where available, and raw capture location.

## Comparison discipline

Do not compare:

- competitor live functionality;
- competitor stated target functionality;
- RetroPick implemented functionality;
- RetroPick target architecture;

as though they were the same category. Name the category explicitly in every
matrix or report.

## Child lane

| Lane | Contents | Boundary |
| --- | --- | --- |
| [launchpads/](launchpads/) | Pons and o1.exchange capability research and references | Fact/inference/recommendation only; no authority over RetroPick economics |
