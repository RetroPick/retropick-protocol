# Benchmark Program

Launchpad Core is benchmarked first. PRISM production benchmarks begin only after module admission reaches the relevant stage.

Domains:
- contract gas/state growth;
- RPC latency/reliability;
- Kuru execution/integration;
- indexer freshness/rebuild/reorg;
- API latency/degradation;
- frontend performance/transaction UX;
- resilience;
- cost/capacity.

Do not invent SLOs before measurement.

~~~text
MEASURE
-> DISTRIBUTION
-> BOTTLENECK
-> PRODUCT REQUIREMENT
-> CANDIDATE SLO
-> VALIDATE
~~~
