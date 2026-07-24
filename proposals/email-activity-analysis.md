# [RFC] Email Activity Analysis — Architecture Proposal

> **Author:** darojaai_architect
> **Date:** 2026-07-24
> **Status:** Decisions received — ready for implementation planning
> **Decisions recorded:** L1+L2 scope, Gmail+Exchange, LLM-first+rules, OpenRouter API, same repo, compliance day 1, Enron start, config-driven taxonomy, in-customer deployment

---

## 1. Objective

Build an agentic system that ingests corporate email (and calendar data), classifies activity by category, quantifies time allocation, and produces visualizations showing before/after activity breakdown — enabling data-driven decisions about process efficiency and automation opportunities.

The system must be deployable **in-customer environments** — organizations may not want to share email content externally.

---

## 2. The Target Output

A graphic (not necessarily a live dashboard initially) showing concentric ring charts of employee time allocation:

**BEFORE (current state):**
- Email Processing — 26%
- Meetings — 22%
- Chasing Information — 14%
- Spreadsheet Administration — 13%
- Reporting — 10%
- Rework & Version Conflicts — 7%
- Actual Decision Making — 8%

**AFTER (optimized state):**
- Decision-Making & Value Creation — 22%
- Managed Workflows — 18%
- Email — 15%
- Stakeholder Engagement — 15%
- Continuous Improvement — 12%
- Meetings — 18%

**Key insight:** "Time Reinvested: 2-3 hours daily per knowledge worker."

---

## 3. Data Layer Strategy

**Decision: L1+L2 (Email + Calendar) for MVP.** L3 (task management) deferred.

### Layer 1: Email Only
**What you get:**
- Volume and frequency of emails per category
- Thread length and response patterns (proxy for "information chasing")
- Meeting coordination emails (calendar invites, scheduling threads)
- Attachment analysis (spreadsheets, reports, documents)
- Sender/recipient networks (who talks to whom, how much)
- Temporal patterns (when are people doing what)

**What you can infer:**
- Email processing time (volume × estimated handling time)
- Meeting coordination overhead (scheduling emails as % of total)
- Information chasing (reply chains, forwarding, CC patterns)
- Spreadsheet administration (emails with .xlsx/.csv attachments)
- Reporting (emails with generated reports attached)

**What you can't infer directly:**
- Actual meeting duration (only the coordination emails)
- Time spent in spreadsheets (only that they were attached)
- Rework (only that multiple versions were sent)

**Verdict: 60-70% of the dashboard is derivable.** Good enough for directional decisions.

### Layer 2: Email + Calendar (included in MVP)
**Added signal:**
- Actual meeting duration and frequency
- Meeting-to-meeting gap analysis (context switching cost)
- Scheduled vs. unscheduled time
- Calendar density by role/team

**New categories unlocked:**
- True meeting time (not just coordination)
- Context switching overhead (back-to-back meetings)
- Unscheduled/flex time availability

**Complexity cost:**
- Calendar API integration (Gmail Calendar + Microsoft Graph Calendar)
- Different schema (events, attendees, recurrence)
- Privacy sensitivity increases

**Verdict: ~20% more accuracy for ~40% more engineering effort.** Included per operator decision.

### Layer 3: Email + Calendar + Task Management (deferred)
Deferred to Phase 3. Assess after L2 proves value. The correlation problem (matching emails to tasks) makes this the hardest layer.

### Recommendation
L1+L2 for MVP. Build the connector architecture to accommodate L3 later without redesign.

---

## 3a. In-Deployment Architecture (Critical Design Constraint)

**Organizations may not want to share their emails with DarojaAI.** The system must be deployable in-house.

### Deployment Model

```
┌──────────────────────────────────────────────────┐
│           CUSTOMER ENVIRONMENT                    │
│                                                   │
│  ┌────────────┐  ┌────────────┐                   │
│  │  Gmail     │  │ Exchange/  │                   │
│  │  Workspace │  │ Microsoft  │                   │
│  │  API       │  │ 365 Graph  │                   │
│  └─────┬──────┘  └─────┬──────┘                   │
│        └────────┬───────┘                         │
│                 ▼                                  │
│     ┌──────────────────────┐                      │
│     │  email-analytics     │ ← Docker container   │
│     │  (connector +        │   in-customer        │
│     │   pipeline +         │   environment        │
│     │   metrics)           │                      │
│     └──────────┬───────────┘                      │
│                │                                  │
│                │  Only aggregated metrics leave   │
│                │  (or nothing leaves at all)      │
└────────────────┼──────────────────────────────────┘
                 │
                 ▼  (optional: anonymized metrics export)
┌──────────────────────────────────────────────────┐
│           DAROJAAI PLATFORM (optional)            │
│  Dashboard / API for multi-tenant view            │
└──────────────────────────────────────────────────┘
```

### Three deployment options

**Option A: Fully in-customer (recommended)**
- All processing runs in the customer's environment
- No email content ever leaves their network
- Graphic/metrics generated locally
- Best for: enterprises with strict data residency

**Option B: Hybrid**
- Processing runs in-customer
- Aggregated, anonymized metrics sent to DarojaAI platform
- Multi-tenant dashboard served from platform
- Best for: SaaS offering where customers accept aggregate-only data sharing

**Option C: Fully managed**
- Customer grants OAuth, everything runs on DarojaAI infra
- Most convenient, most privacy-sensitive
- Only viable with high customer trust

**Recommendation:** Build Option A as the primary path. Option B as a follow-on. This means the system ships as a **self-contained Docker image** with no dependency on DarojaAI infrastructure.

### Implications
- System ships as standalone container (not an MCP server requiring gateway)
- Classification uses OpenRouter API (operator decision) — container needs API key config
- Metrics export via API or file, not database connection
- Calendar integration is a module within the same container, not a separate service

---

## 4. Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    DATA SOURCE LAYER                      │
│                                                           │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────┐     │
│  │  Gmail   │  │Exchange  │  │  Calendar APIs     │     │
│  │  API     │  │  Graph   │  │  (GCal + MSGraph)  │     │
│  └────┬─────┘  └────┬─────┘  └────────┬───────────┘     │
│       └──────────────┼────────────────┘                  │
│                      ▼                                   │
│          ┌──────────────────────┐                        │
│          │  email-connector     │  Normalizes to         │
│          │  (module)            │  standard schema       │
│          └──────────┬───────────┘                        │
└─────────────────────┼────────────────────────────────────┘
                      │  Standard Email + Calendar Events
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  CLASSIFICATION LAYER                     │
│                                                           │
│  ┌──────────────────────────────────────────────┐        │
│  │  Track A: LLM Classifier (primary)          │        │
│  │  - Prompt-based, configurable categories     │        │
│  │  - OpenRouter API (gpt-4o-mini or similar)   │        │
│  │  - Returns: category + confidence + reasoning│        │
│  └──────────────┬───────────────────────────────┘        │
│                 │                                        │
│  ┌──────────────▼───────────────────────────────┐        │
│  │  Track B: Rules Engine (complementary)       │        │
│  │  - Calendar invites → meeting                │        │
│  │  - .xlsx/.csv attachments → spreadsheet admin│        │
│  │  - Long reply chains → info chasing          │        │
│  │  - Auto-senders → notifications              │        │
│  │  - Deterministic metrics signals             │        │
│  └──────────────┬───────────────────────────────┘        │
│                 │                                        │
│  ┌──────────────▼───────────────────────────────┐        │
│  │  Confidence Resolver                         │        │
│  │  - Rules match → use rules                   │        │
│  │  - LLM high-confidence → use LLM             │        │
│  │  - Low confidence → flag for review           │        │
│  └──────────────────────────────────────────────┘        │
└─────────────────────┬────────────────────────────────────┘
                      │  Classified emails + calendar events
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  METRICS LAYER                           │
│                                                           │
│  ┌──────────────────────────────────────────────┐        │
│  │  Metrics Aggregator                          │        │
│  │  - Volume per category                       │        │
│  │  - Estimated time per category               │        │
│  │  - Per-person / per-team breakdown           │        │
│  │  - Temporal trends                           │        │
│  │  - Meeting metrics (from calendar)           │        │
│  └──────────────┬───────────────────────────────┘        │
│                 │                                        │
│  ┌──────────────▼───────────────────────────────┐        │
│  │  Storage: DuckDB or SQLite (local)           │        │
│  │  (no external DB dependency for in-customer) │        │
│  └──────────────────────────────────────────────┘        │
└─────────────────────┬────────────────────────────────────┘
                      │  Aggregated metrics
                      ▼
┌─────────────────────────────────────────────────────────┐
│                   OUTPUT LAYER                            │
│                                                           │
│  ┌────────────────────┐  ┌────────────────────────┐     │
│  │  Graphic Generator │  │  Optional: OpenClaw    │     │
│  │  (matplotlib/      │  │  Agent for conversa-   │     │
│  │   plotly)          │  │  tional queries        │     │
│  │  → SVG/PNG output  │  │  (future)              │     │
│  └────────────────────┘  └────────────────────────┘     │
└─────────────────────────────────────────────────────────┘
```

### Component Details

#### email-connector (module within email-analytics)
- **Purpose:** Normalize email from multiple sources into a standard schema
- **Deployment:** Self-contained within Docker image
- **Supported sources:** Gmail API, Microsoft Graph (Exchange/365), IMAP (generic fallback)
- **Calendar:** Same module handles Gmail Calendar API and Microsoft Graph Calendar
- **Schema:**
  ```json
  {
    "id": "string",
    "source": "gmail | exchange | imap",
    "timestamp": "ISO-8601",
    "from": "string",
    "to": ["string"],
    "cc": ["string"],
    "subject": "string",
    "body_text": "string",
    "body_html": "string | null",
    "attachments": [{"filename": "string", "mime_type": "string", "size_bytes": "int"}],
    "thread_id": "string",
    "thread_position": "int",
    "calendar_event_id": "string | null",
    "headers": {"message_id": "string", "in_reply_to": "string | null"}
  }
  ```

#### email-analytics-pipeline (module within email-analytics)
- **Classification approach (LLM-first, rules-complemented):**
  - **Track A — LLM Classification (primary):** Prompt-based using configurable categories, OpenRouter API, returns category + confidence + reasoning
  - **Track B — Rules Engine (complementary):** Deterministic patterns for obvious cases and metrics. Especially important for metrics (operator decision)
  - **Track C — Lightweight Classifier (future):** Train SVC on LLM labels when training data accumulates. Not needed for MVP.
  - **Confidence Resolver:** Rules > LLM high-confidence > flag for review

#### Metrics Aggregator
- Computes: volume per category, estimated time per category, per-person/team breakdowns, temporal trends, meeting metrics from calendar
- **Time estimation model (email-only layer):** Heuristic: email count × avg handling time per category. Meeting coordination = 2 min/email, information seeking = 4 min/email, notification = 0.5 min/email.
- **Storage:** DuckDB or SQLite (local, no external DB dependency for in-customer deployment)

#### Graphic Generator
- matplotlib or plotly for concentric ring charts
- Script output (PNG/SVG), not a live dashboard initially
- Configurable: filters by person, team, time range, category

---

## 5. Classification Taxonomy

### Config-driven (operator decision)

Taxonomy is defined in a YAML file, not hardcoded. The format follows the pattern already established in `rag_research_tool`'s `domains.yaml`.

```yaml
# taxonomy.yaml
categories:
  - slug: "email-processing"
    name: "Email Processing"
    description: "General correspondence, drafting, reading, responding"
    estimated_minutes_per_email: 3
    detection_rules:
      - type: "default"  # catch-all when no other category matches

  - slug: "meetings"
    name: "Meetings"
    description: "Calendar events, meeting coordination, scheduling"
    estimated_minutes_per_email: 2
    detection_rules:
      - type: "attachment"
        mime_types: ["text/calendar"]
      - type: "llm"
        prompt_hint: "meeting coordination, scheduling, calendar invites"

  - slug: "information-chasing"
    name: "Chasing Information"
    description: "Reply chains, forwarding, CC-heavy threads, status requests"
    estimated_minutes_per_email: 4
    detection_rules:
      - type: "thread_length"
        min_replies: 5
      - type: "llm"
        prompt_hint: "requesting information, waiting for responses, forwarding for input"

  - slug: "spreadsheet-admin"
    name: "Spreadsheet Administration"
    description: "Working with spreadsheets, data entry, formatting"
    estimated_minutes_per_email: 5
    detection_rules:
      - type: "attachment"
        extensions: [".xlsx", ".csv", ".xls"]
      - type: "llm"
        prompt_hint: "spreadsheet work, data manipulation, reporting data"

  - slug: "reporting"
    name: "Reporting"
    description: "Generating, reviewing, distributing reports"
    estimated_minutes_per_email: 4
    detection_rules:
      - type: "llm"
        prompt_hint: "reports, summaries, dashboards, metrics review"

  - slug: "rework"
    name: "Rework & Version Conflicts"
    description: "Multiple versions, corrections, repeated work"
    estimated_minutes_per_email: 6
    detection_rules:
      - type: "llm"
        prompt_hint: "corrections, revised version, updated, v2, rework"

  - slug: "decision-making"
    name: "Decision Making"
    description: "Requests for approval, decisions, sign-offs"
    estimated_minutes_per_email: 5
    detection_rules:
      - type: "llm"
        prompt_hint: "approval needed, decision required, sign off, go ahead"

  - slug: "notifications"
    name: "Notifications & Automated"
    description: "Automated alerts, system notifications, newsletters"
    estimated_minutes_per_email: 0.5
    detection_rules:
      - type: "sender_pattern"
        patterns: ["noreply@", "no-reply@", "notifications@"]
```

### Mapping to dashboard categories

The taxonomy YAML maps email categories to dashboard categories:

```yaml
dashboard_mapping:
  email-processing: "Email"
  meetings: "Meetings"
  information-chasing: "Chasing Information"
  spreadsheet-admin: "Spreadsheet Administration"
  reporting: "Reporting"
  rework: "Rework & Version Conflicts"
  decision-making: "Actual Decision Making"
  notifications: "Email"  # folded into email processing
```

### Taxonomy evolution

As the classifier runs on real data, new subcategories may emerge. The taxonomy YAML can be updated without code changes. This mirrors `rag_research_tool`'s approach where domain proposals (NEW_DOMAIN / ALIAS_OF) are generated by the LLM and reviewed by the operator.

---

## 6. Taxonomy Commonality: email-analytics ↔ rag_research_tool

### What rag_research_tool already has

After reading the taxonomy curator code (`src/rag/agents/taxonomy_curator/`, `src/rag/run_classify_domains.py`):

1. **Config-driven domain registry** (`domains.yaml` with slugs, aliases, definitions)
2. **LLM-based classification** — sends entity + domain descriptions to LLM, gets back domains + confidence + reasoning
3. **Rule-based fallback** (`DOMAIN_KEYWORDS` dict) — keyword matching when LLM unavailable
4. **Taxonomy curator agent** (LangGraph) — detects unknown domains, generates proposals (NEW_DOMAIN / ALIAS_OF / UNCATEGORIZED)
5. **Review workflow** (LangGraph) — LLM evaluates proposals, flags high-risk changes, notifies operator via Discord, 48h override window
6. **Shared LLM client** via `devnexus-common` (`common.llm.get_llm_client`) with OpenRouter routing

### What's genuinely reusable (pattern-level)

| Pattern | rag_research_tool | email-analytics | Reusable? |
|---|---|---|---|
| Config-driven taxonomy (YAML registry) | domains.yaml with slugs/aliases | Activity categories YAML | ✅ Same pattern |
| LLM classifier (entity → categories) | Wiki nodes → 8 AI domains | Emails → activity categories | ✅ Same architecture |
| Rules engine (keyword/pattern fallback) | DOMAIN_KEYWORDS dict | Attachment-type, thread-length | ✅ Same pattern |
| Confidence scoring + threshold | LLM returns confidence float | LLM returns confidence float | ✅ Identical |
| Human-in-the-loop review | LangGraph review graph + Discord | Operator reviews low-confidence | ⚠️ Simpler version needed |
| Domain proposal workflow | NEW_DOMAIN / ALIAS_OF / UNCATEGORIZED | Taxonomy evolution | ✅ Same workflow |
| Shared LLM client (OpenRouter) | `common.llm.get_llm_client` | Same | ✅ Direct reuse |

### What's NOT reusable (domain-level)

| Aspect | rag_research_tool | email-analytics |
|---|---|---|
| Domain definitions | AI governance (8 domains) | Activity categories (6-8 categories) |
| Entity type | Wiki nodes (markdown) | Emails (structured metadata) |
| Classification context | Content + frontmatter | Subject + body + attachments + metadata |
| Storage | Neo4j knowledge graph | DuckDB/SQLite metrics store |
| Taxonomy purpose | Topic organization | Time/activity measurement |

### Recommendation

**For MVP:** Build classification directly in `email-analytics` using `devnexus-common`'s LLM client. Don't block on extracting a shared library. The YAML taxonomy format and LLM classification prompt pattern can be borrowed by convention, not by import.

**After MVP:** When a third consumer appears, extract a `taxonomy-engine` shared library into `devnexus-common` or a standalone Shared Library repo. This is a candidate for the upcoming "Shared Libraries & Templates" RFC.

**Key insight:** The LLM classification pattern is already a de facto standard in the org. Making it a first-class shared concern is the right long-term move, but not the right MVP move.

---

## 7. Development & Test Strategy

### Phase 1: Dataset-Driven Development (Weeks 1-4)

Build and validate the classification pipeline against public datasets before touching real email.

#### Primary Datasets

| Dataset | Size | Why Useful | Limitations |
|---|---|---|---|
| **Enron Email Corpus** | ~500K msgs, 150 users | Gold standard for workplace email. Folder structure includes `meetings/`, `calendar/`. Real corporate email from senior management. | 1998-2002 era. Enron-specific culture. |
| **CMU Enron-Meetings Subset** | Subset of Enron | Pre-filtered meeting/calendar emails. Directly useful for meeting classifier. | Same era limitations. |
| **TREC 2007 Spam Corpus** | ~75K msgs | Chronologically ordered, 3 months of real email. Good for temporal pattern testing. | Spam-focused, but useful for "notification/automated" category. |
| **EMC-2 (Synthetic)** | Narrative-driven | No ethical baggage. Good for end-to-end pipeline testing. Can share results freely. | Synthetic = may miss real-world messiness. |

#### Additional Useful Datasets

| Dataset | Use Case |
|---|---|
| **Ling-Spam Corpus** | ~28K msgs from academic mailing list. More recent than Enron. Good for "professional correspondence" patterns. |
| **MeetingBank** | Meeting transcripts and summaries. Useful for Layer 2+ analysis of what happens IN meetings. |
| **W3C Email Corpus** | Professional/technical email from W3C working groups. Good for "technical discussion" category. |

#### Recommended Development Order

1. **Enron + Enron-Meetings subset.** Run LLM classifier on meeting folder → validate meeting detection. Run on random sample → validate category distribution.

2. **EMC-2 for end-to-end pipeline testing.** Synthetic, so shareable. Test edge cases without privacy concerns.

3. **TREC 2007 for temporal analysis.** Chronological ordering tests "activity over time" patterns.

4. **LLM-as-label-generator** (Win Gillis approach): Use strong LLM to label thousands of Enron emails → train lightweight SVC on those labels → measure against hand-labeled holdout. This validates that the classifier can eventually run cheaply at scale.

5. **Hand-labeled validation set (200-500 emails).** Pull from Enron, label by hand into taxonomy categories. This is ground truth. No public dataset replaces it.

### Phase 2: Pipeline Build (Weeks 3-8)

Build email-connector + classification pipeline + metrics aggregation.

### Phase 3: Graphic + Deployment (Weeks 6-10)

Graphic generation scripts, Docker packaging, in-customer deployment testing.

---

## 8. Compliance & Privacy Architecture

Built in from day 1 (operator decision). This shapes the system fundamentally.

### Principles
1. **Aggregate-only outputs.** No individual email content in graphics. Metrics always at team/role/group level.
2. **Configurable data retention.** Raw email is processed and discarded. Only derived metrics are stored.
3. **PII redaction in transit.** Email bodies are classified but not stored verbatim. Only category + metadata + timestamp persist.
4. **Opt-in model.** Employees (or their managers) must consent to analysis.
5. **Audit trail.** Every classification decision is logged for explainability.
6. **In-customer by default.** No email content leaves the customer's network unless they explicitly configure remote metrics export.

### Architecture implications
- email-connector processes and discards raw content
- Analytics pipeline outputs only category + confidence + metrics
- No email body text in the database
- Graphics show aggregate statistics only
- OpenClaw agent (future) queries aggregate data, never individual emails

---

## 9. Repo Placement & Governance

**Single repo: `email-analytics`** (operator decision).

| Component | Location | Notes |
|---|---|---|
| email-connector | `email-analytics/src/connector/` | Gmail, Exchange, Calendar modules |
| classification pipeline | `email-analytics/src/classification/` | LLM classifier, rules engine, confidence resolver |
| metrics aggregation | `email-analytics/src/metrics/` | Time estimates, per-person/team breakdowns |
| taxonomy config | `email-analytics/config/taxonomy.yaml` | Config-driven categories |
| graphic generation | `email-analytics/src/graphics/` | matplotlib/plotly scripts |
| Docker | `email-analytics/Dockerfile` | Self-contained in-customer deployment |
| tests | `email-analytics/tests/` | Dataset-driven validation |

---

## 10. Decisions Log

| # | Question | Decision | Notes |
|---|---|---|---|
| D1 | Scope: which data layers? | L1+L2 (email + calendar) | L3 deferred |
| D2 | Email sources? | Gmail + Exchange/Microsoft (primary) | IMAP as generic fallback |
| D3 | Classification? | LLM-first (OpenRouter API), rules-complemented | Rules especially for metrics |
| D4 | Local LLM vs API? | API (OpenRouter) | Local deferred to future optimization |
| D5 | Dashboard? | Same repo; graphic generation initially, not a dashboard | May add dashboard later |
| D6 | Compliance? | Build in from day 1 | Privacy architecture shapes the system |
| D7 | Dataset? | Enron to start, supplement quickly | EMC-2 + others |
| D8 | Taxonomy? | Config-driven (YAML) | Mirror rag_research_tool pattern |
| D9 | Deployment? | In-customer (Docker) | Option A primary; Option B (hybrid) later |
| D10 | Multi-tenant SaaS? | Deferred | After Option A proves out |

---

## 11. Effort Estimate

| Phase | Duration | Deliverable |
|---|---|---|
| Phase 1: Dataset dev + classifier validation | 3-4 weeks | Validated classifier on Enron, hand-labeled validation set |
| Phase 2: Pipeline build | 4-5 weeks | Working email-connector + analytics pipeline (Gmail + Exchange + Calendar) |
| Phase 3: Graphic + deployment | 2-3 weeks | Graphic generation, Docker packaging, in-customer deployment |
| **Total MVP** | **~9-12 weeks** | |
| Phase 2 enhancement (task management) | +4-6 weeks | L3 data layer |
| Phase 3 enhancement (SaaS/hybrid) | +3-4 weeks | Multi-tenant, remote metrics |

---

## 12. Risk Register

| Risk | Impact | Mitigation |
|---|---|---|
| Enron data too dated for modern email | Classifier may not generalize | Supplement with EMC-2 + hand-labeled real data |
| LLM classification accuracy insufficient | Wrong categories → wrong decisions | Hand-labeled validation; confidence thresholds; human-in-the-loop |
| Privacy backlash | Project killed | Aggregate-only, opt-in, in-customer deployment |
| Email connector edge cases | Incomplete data | Graceful degradation; partial data still useful |
| Time estimation heuristics too rough | Numbers don't match reality | Directional only; validate against time-tracking if available |
| OpenRouter API dependency in-customer | Network restrictions | Design for API key config; future: local LLM option |
| Taxonomy doesn't map cleanly between rag_research_tool and email-analytics | Reusable pattern but not identical | Accept: same architecture, different domain definitions. Extract shared lib only after third consumer. |

---

## 13. Next Steps

1. ~~Decisions received~~ ✅
2. Clone Enron dataset into `_context/` for initial analysis
3. Build hand-labeled validation set (200-500 emails from Enron)
4. Prototype LLM classifier on Enron-Meetings subset
5. Measure accuracy → iterate on taxonomy YAML
6. Build email-connector (Gmail API first, then Exchange)
7. Wire classification pipeline + metrics aggregation
8. Build graphic generator (concentric ring charts)
9. Package as Docker, test in-customer deployment
10. File RFC in `.github` for new repo creation (if separate repo warranted)
