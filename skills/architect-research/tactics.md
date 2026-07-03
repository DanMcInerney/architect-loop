# Source-class tactics library — researcher preamble, scout block, verified endpoints

Researcher assignments are DESIGNED per topic by the orchestrator (SKILL.md step 2); the
sections below are search tactics and verified endpoints per source class —
draw on whichever a designed researcher assignment needs, mix freely. Endpoints verified
unauthenticated June 2026. Every researcher block starts with this preamble,
then the researcher-specific objective:

```
You are a web research agent. Answer ONE assigned objective. Do not write code,
do not make recommendations — judgment belongs to the orchestrator reading your
output. Budget: <N> searches; if two consecutive searches yield no new
load-bearing facts, stop and return. HARD CONTEXT RULES: never open a full
page when the search snippet answers the question; quote at most 2 sentences
per source; the moment you can answer, STOP and write your findings — partial
findings beat context exhaustion (researchers that fill their window die
without writing anything). OUTPUT: markdown findings, ≤ ~2,500 tokens
(~10 KB) total — every finding carries a source tag (e.g. `[S3]`), source
date, the exact figure or a short direct quote, and a confidence tag
(high = primary source / med = reputable secondary / low = single blog or
forum post). Prefer primary sources. Record exact version numbers and dates.
When sources disagree, report the disagreement — do not resolve it. If you
cannot find evidence, write NOT FOUND — never fill gaps from prior knowledge
without flagging it. End with a numbered source list — every source URL
appears EXACTLY ONCE, numbered `[S1]`, `[S2]`, ... — then the 2-3 findings
most likely to change a design decision.
```

**Researcher scoping rule (learned 2026-06-12):** cap each researcher at ~5 subjects
(repos, vendors, people). Doc-heavy assignments burn the context window on fetched
pages — two of nine researchers in one session died of context exhaustion
before writing any findings. A researcher that dies returns NOTHING (`-o`
only materializes on a clean finish). If a researcher dies this way, bisect the assignment into
narrower researcher assignments and re-dispatch; don't re-run it as-is.

## Researcher 0 — Scout (brainstorm scale; dispatches before researcher assignment design)

Objective template: map the terrain of <topic> — do NOT gather findings.
Return: (1) canonical terminology and the names the field itself uses;
(2) the 5–10 load-bearing systems/papers/repos/vendors, one line each on why
they matter; (3) the named people whose positions recur; (4) which source
classes look rich vs empty for this topic (papers? repos? vendor blogs?
forums?); (5) the topic's natural fault lines — the 3–6 sub-questions an
expert would split it into. Budget ~10 searches; breadth over depth; snippet
over page. Output is a MAP for the orchestrator to design researcher assignments from —
structure matters more than completeness.

## Researcher 1 — Academic (latest papers)

Objective: the current academic state of <topic> — most recent survey, the
latest preprints, and which papers the field treats as load-bearing.

Pipeline: **survey first → latest sweep → snowball → score.**

- Recent survey: Semantic Scholar `publicationTypes=Review`, or arXiv
  `ti:survey AND abs:<topic>` (last ~18 months). The survey supplies canonical
  terminology and the seed bibliography.
- Latest sweep (newest first):
  `https://export.arxiv.org/api/query?search_query=cat:<cs.XX>+AND+abs:%22<topic>%22&sortBy=submittedDate&sortOrder=descending&max_results=25`
  (Atom XML; uppercase AND/OR; ≥3s between calls) and
  `https://api.semanticscholar.org/graph/v1/paper/search?query=<topic>&fields=title,year,citationCount,tldr,venue,externalIds&limit=20&year=2025-2026`
  (expect 429s — back off and retry; the `tldr` field is gold for triage).
  Community signal: `https://huggingface.co/api/daily_papers?limit=20` and
  `https://huggingface.co/papers/trending`. **Papers With Code is dead**
  (shut down July 2025; HF Papers is the successor) — never cite it.
- Snowball from the 2-3 most relevant seeds — a reliable "latest papers" method:
  forward citations
  `https://api.semanticscholar.org/graph/v1/paper/arXiv:<id>/citations?fields=title,year,isInfluential&limit=100`
  and semantic neighbors
  `https://api.semanticscholar.org/recommendations/v1/papers/forpaper/arXiv:<id>?limit=20`.
  Fallback when S2 throttles: OpenAlex —
  `https://api.openalex.org/works?search=<topic>&sort=publication_date:desc&per-page=25&mailto=research@example.com`.
- Score candidates: citations-per-month (not raw count — meaningless for 2026
  papers), venue/OpenReview decision (`https://api2.openreview.net/notes/search?term=<topic>&limit=25`
  has actual reviewer scores), code availability, HF traction. Red flags:
  preprint-only after 18+ months, self-citation-heavy.

## Researcher 2 — Popular repos (what the ecosystem actually uses)

Objective: the 5-10 repos/libraries the ecosystem has actually adopted for
<topic>, with adoption evidence beyond stars.

- Discovery: GitHub search —
  `topic:<topic> stars:>1000 archived:false sort:stars`,
  `"<topic>" in:name,description,readme stars:>2000`, plus awesome-lists as
  recall boosters (`awesome <topic> in:name stars:>1000`) — re-check `pushed:`
  on every list entry; lists go stale.
- **Adoption evidence beats stars**: dependents count via
  `https://api.deps.dev/v3/systems/<npm|pypi|...>/packages/<name>` or
  `https://packages.ecosyste.ms` (keyless, 5k req/hr); registry download
  *trends* (`https://pypistats.org/api/packages/<pkg>/recent`,
  `https://api.npmjs.org/downloads/point/last-month/<pkg>`).
- **Fake-star check**: ~4.5M fake stars documented in the wild. Stars without
  proportional forks/issues/dependents = flag it. Report stars AND dependents
  AND last release for every repo.

## Researcher 3 — Cutting-edge repos (emerging, not hype)

Objective: what's emerging in <topic> in the last ~6 months that practitioners
are actually adopting — and which hyped repos are already abandoned.

- Where bleeding-edge surfaces first: HF daily/trending papers (code-linked);
  Hacker News via Algolia —
  `https://hn.algolia.com/api/v1/search_by_date?query=<topic>&tags=story&numericFilters=points>50`
  (also `query=github.com` + topic for Show HNs); `https://lobste.rs/t/<tag>.json`;
  GitHub `topic:<topic> created:>{90d ago} stars:>100 pushed:>{14d ago} sort:stars`;
  OSS Insight (`https://ossinsight.io/collections/trending`) for transparent
  velocity ranking.
- **Emerging-vs-hype test** (report which side each repo lands on):
  EMERGING = created recently AND pushed <14d AND star velocity sustained ≥2
  weeks AND issues getting maintainer responses AND linked from a paper or a
  track-record org AND forks/issues growing in proportion to stars.
  HYPE = week-one star spike then stalled pushes, unanswered issues, README
  promises >> code, single contributor, no tests/releases. Any single signal
  is gameable; the conjunction is not.

## Researcher 4 — Production-grade design patterns

Objective: how 2-3 production libraries adjacent to <topic> design
the thing we're about to build — API ergonomics, error handling, extension
points, testing patterns — and where they differ.

- Select subjects with the production-grade test: pushed <6mo (or explicitly
  stable + responsive issues), tagged releases + changelog in last 12mo,
  dependents >100 (ecosystem-adjusted), ≥2 active maintainers, CI runs tests
  on PRs, OSI license, no unaddressed criticals on `https://osv.dev`.
  Ignore raw stars and commit counts.
- Reading order — never start at file #1: README + manifest (entry points,
  exports = the deliberate public surface) → trace ONE canonical happy-path
  call end to end → tests for the relevant feature (executable documentation
  of edge-case policy) → 3 closed issues + 2 merged PRs in the area (the
  "why not" you can't get from code).
- Extract four categories per library: **API ergonomics** (cost of the 90%
  case in lines, defaults, config layering), **error handling** (exception
  hierarchy root, retried vs raised, boundary translation), **extension
  points** (grep for hook/adapter/middleware/plugin/register/Protocol),
  **testing patterns** (fixture strategy, how I/O is faked, regression-test-
  per-bug convention).
- Then the **cross-library diff**: patterns all of them share are load-bearing;
  where they differ is a trade-off to document.
- Tools: GitHub code search (`symbol:<Name>`, `/regex/`, `repo:`, `path:`),
  `https://grep.app` (usage in the wild), `https://sourcegraph.com/search`.
  For "what do people actually call", search downstream dependents' code, not
  the library.

## Researcher 5 — General web

Objective: everything the other researchers structurally miss on <topic> — expert
blog posts, postmortems and failure reports, comparisons, official vendor
docs/changelogs, pricing/operational constraints.

- Standard multi-angle sweep: official docs/changelogs; named-expert posts;
  "<X> postmortem" / "<X> at scale" / "<X> problems" for failure reports;
  "<X> vs <Y>" for comparisons. Date-restrict queries on fast-moving topics.
- Source hierarchy applies hardest here: SEO listicles and AI-generated
  aggregators are pointers, never citations — chase them to the primary
  source or drop the claim.

## Researcher 6 — Expert opinion (second wave — dispatch after researchers 1-5 return)

Objective: what the named experts in <topic> are saying right now — positions,
warnings, predictions, and especially disagreements — from their blogs, talks,
and social posts.

- **Build the roster first** (why this researcher runs second): survey and top-paper
  authors (researcher 1), maintainers of the leading repos (researchers 2-3), and names
  that recur across researcher 5 results. Pick 5-8; record each expert's affiliation
  — you'll need it for conflict-of-interest tagging.
- Where to find their voice, in reliability order:
  1. **Personal blogs / newsletters** — the primary source for considered
     positions; search `"<name>" <topic>` and `site:<their-domain> <topic>`.
  2. **HN comments** — keyless and reliable:
     `https://hn.algolia.com/api/v1/search?tags=comment,author_<username>&query=<topic>`
     (many experts comment under well-known usernames).
  3. **Conference talks / podcasts** — search `"<name>" talk <topic> 2026`;
     prefer transcripts or the speaker's own writeup over third-party recaps.
  4. **X** — login-walled for agents. Use search-engine indexing
     (`site:x.com "<name>" <topic>`) and direct profile URLs
     (`x.com/<handle>`); don't rely on third-party viewers (flaky) and note
     that Bluesky's public search API has been closed (403) since March 2025
     — profile pages only.
  5. **Reddit / lobste.rs** threads and AMAs (via indexed search:
     `site:reddit.com "<name>" <topic>`).
- **Opinion is its own evidence class.** An expert opinion is judgment —
  datable, revisable, and sometimes conflicted. For every position report:
  the exact quote or close paraphrase, where and when stated, and any conflict
  of interest (vendor employee talking their book, author promoting their own
  tool). An opinion NEVER counts toward the ≥2-source rule for factual claims
  — facts get verified by the other researchers; this researcher reports who believes
  what and why.
- **The highest-value output is disagreement**: where credible experts
  contradict each other is exactly where the genuinely open questions are.
  Map who stands where and what evidence each side cites.
