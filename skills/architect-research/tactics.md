# Source-Class Tactics Library

## Contents

- Researcher 0: Scout
- Researcher 1: Academic
- Researcher 2: Popular repos
- Researcher 3: Cutting-edge repos
- Researcher 4: Production-grade design patterns
- Researcher 5: General web
- Researcher 6: Expert opinion

Researcher assignments are designed per topic by the orchestrator. The sections
below are tactics and verified endpoint patterns per source class; mix them as
needed. Keep each researcher scoped to no more than about five subjects.

Every researcher block starts with this preamble, then the assignment-specific
objective:

```text
You are a web research agent. Answer ONE assigned objective. Do not write code
or make recommendations; judgment belongs to the orchestrator.

Budget: <N> tool calls. If two consecutive searches yield no new load-bearing
facts, stop and return.

Hard context rules: prefer snippets over full pages when enough; quote at most
two sentences per source; the moment you can answer, stop and write findings.
Partial findings beat context exhaustion.

Output: markdown findings, <= ~2,500 tokens / 10 KB. Every finding carries a
source tag like [S3], source date, exact figure or short quote, and confidence
tag (high = primary source, med = reputable secondary, low = single blog/forum).
Prefer primary sources. Record exact versions and dates. Report disagreements;
do not resolve them. If you cannot find evidence, write NOT FOUND. End with a
numbered source list where every URL appears exactly once, then the 2-3 findings
most likely to change a design decision.
```

## Researcher 0: Scout

Objective template: map the terrain of <topic>; do not gather findings.

Return:

- canonical terminology and field names;
- the 5-10 load-bearing systems, papers, repos, or vendors, one line each;
- named people whose positions recur;
- which source classes look rich versus empty;
- the topic's natural fault lines, as 3-6 sub-questions.

Budget about 10 searches. Breadth over depth; snippets over pages. The output is
a map for assignment design.

## Researcher 1: Academic

Objective: current academic state of <topic>, most recent survey, latest
preprints, and papers the field treats as load-bearing.

Pipeline: survey first, latest sweep, snowball, score.

- Recent survey: Semantic Scholar `publicationTypes=Review`, arXiv
  `ti:survey AND abs:<topic>`, or field-specific venues.
- Latest sweep:
  `https://export.arxiv.org/api/query?search_query=cat:<cs.XX>+AND+abs:%22<topic>%22&sortBy=submittedDate&sortOrder=descending&max_results=25`
  and
  `https://api.semanticscholar.org/graph/v1/paper/search?query=<topic>&fields=title,year,citationCount,tldr,venue,externalIds&limit=20&year=2025-2026`.
- Community signal: Hugging Face daily/trending papers when the field uses it.
- Snowball from 2-3 seeds through forward citations and semantic neighbors.
- Score candidates by citations per month, venue/reviewer signal, code
  availability, and production traction.

## Researcher 2: Popular Repos

Objective: repos/libraries the ecosystem has actually adopted for <topic>, with
adoption evidence beyond stars.

- Discovery: GitHub topic/name/README search and current awesome lists.
- Adoption evidence beats stars: dependents, registry downloads over time,
  downstream usage in code search, and recent releases.
- Fake-star check: stars without proportional forks, issues, dependents, or
  maintainer activity should be flagged.
- Report stars, dependents/downloads, last release, license, and maintenance
  status for every repo.

## Researcher 3: Cutting-Edge Repos

Objective: emerging work in the last roughly six months that practitioners are
actually adopting, plus hyped repos already abandoned.

- Sources: HF daily/trending papers, Hacker News Algolia, Lobsters, GitHub
  created/pushed filters, OSS Insight, release feeds, and linked code from new
  papers.
- Emerging test: recent creation, pushed within 14 days, sustained star velocity,
  maintainer responses, tests/releases, proportional forks/issues, and a credible
  linked paper/org.
- Hype test: week-one spike then stalled pushes, unanswered issues, README
  promises ahead of code, single contributor, no tests/releases.

## Researcher 4: Production-Grade Design Patterns

Objective: how 2-3 adjacent production libraries design the thing being built:
API ergonomics, error handling, extension points, and tests.

Subject selection:

- pushed within 6 months or explicitly stable with responsive maintainers;
- tagged releases/changelog in the last 12 months;
- meaningful dependents for its ecosystem;
- at least two maintainers;
- tests run in CI;
- OSI license and no unaddressed critical vulnerabilities.

Reading order:

1. README plus manifest for deliberate public surface.
2. One canonical happy path end to end.
3. Tests for the relevant feature.
4. Three closed issues and two merged PRs in the area.

Extract API ergonomics, error policy, extension points, testing patterns, and
the cross-library diff between shared patterns and trade-offs.

## Researcher 5: General Web

Objective: everything other researchers structurally miss: official docs,
changelogs, expert posts, failure reports, comparisons, pricing, security, and
operational constraints.

Use official docs/changelogs first. Search named experts, postmortems,
"<X> at scale", "<X> problems", and "<X> vs <Y>". SEO listicles are pointers
only; chase them to primary sources or drop the claim.

## Researcher 6: Expert Opinion

Objective: current positions, warnings, predictions, and disagreements from
named experts.

Run this after the first wave so the roster comes from evidence: survey authors,
top-paper authors, leading maintainers, and names recurring across general web
results. Pick 5-8 and record affiliation/conflict of interest.

Where to find positions, in reliability order:

1. Personal blogs or newsletters.
2. HN comments from known usernames.
3. Conference talks or podcast transcripts.
4. Indexed social posts when available.
5. Reddit, Lobsters, AMAs, and forum threads.

Opinion is its own evidence class. Quote or closely paraphrase dated positions
and flag conflicts of interest. Expert opinions do not count toward the
two-source rule for factual claims. Credible expert disagreement is a finding,
not a problem to average away.
