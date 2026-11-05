# Current Launchpad V2 development

This is the canonical V2 development tree. New quote admission is Uniswap v4 only. Concrete legacy-venue contracts and their regression fixtures are isolated under `../legacy/v2/kuru/` and `../../test/legacy/v2-kuru/`.

`GraduationVenue.UNISWAP_V4` remains wire value 0. `LEGACY_RESERVED` keeps wire value 1 unavailable to new launches; removing or reassigning that serialized slot would misinterpret historical packets. The source enum member changed, while the ABI still encodes the same `uint8` values.

The hackathon testnet implementation remains frozen separately in `../../legacy-v2/`, pinned to recorded deployed source `f0363249f4b74e58dde37d1241742ca5a92bcfe3`. Current development is not an update to any deployed instance. Deployment manifests, judging frontend configuration, original ABIs and historical claims are preserved.

Canonical Community Economy currently supports actual Curve fees, independent claims, rights-preserving policy changes, controller succession and atomic Treasury binding with qualified 72-hour spending governance. The existing canonical v4 executor deliberately disables community hook fees for Curve-only Routers.

The new two-asset in-kind venue-revenue deployment family is being qualified under `../v2-research-experiment/m6/`. It is not silently enabled in old pools or promoted into this directory. Its fee-source specification, security results and adoption gates are tracked in `../../../research/launchpad/community-economy-v2/iterations/006-permissionless-venue-m6/`.

No release, broadcast or deployment is authorized by this source tree. Local genuine venue tests, behavioral fixtures and live fork qualification are separate evidence classes.
