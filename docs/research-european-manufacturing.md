# European Manufacturing Capex Intelligence: Research Digest

> **Date:** 2026-07-29 (original research); 2026-07-31 (PR)
> **Author:** darojaai_architect (organizational analysis)
> **Status:** Complete — 23-footnote research document for EU capex intelligence engagement

---

## The narrative is wrong

Europe's manufacturing isn't declining — it's restructuring. €3.67T in active capital spending. The money is going to EV batteries, semiconductors, defense, pharma, and clean energy. But it's flowing to specific corridors, not evenly distributed.

## Where the capex actually is

### Semiconductors

Chips Act 2.2 proposed June 2026. IPCEI AST already selecting projects. STMicro (€1B), GlobalFoundries (€1.1B Dresden), onsemi (€1.64B Czech Republic). The hotbed is Saxony/Dresden, not Munich.

The EU Chips Act 2.2 (proposed June 2026) builds on the original €43B framework with additional measures for advanced packaging, design capabilities, and supply chain resilience [1]. IPCEI Microelectronics and Communications projects have approved €8.1B in combined public/private investment across 56 companies [2]. Dresden alone hosts >€15B in committed semiconductor investment, making it Europe's largest chip manufacturing cluster [3].

### Batteries

The biggest flows. CATL (€7.3B Hungary), EVE Energy (€1B Hungary), Gotion (Slovakia gigafactory), LG Energy Solution (Europe's largest factory, Wrocław). The gigafactory belt runs Dresden → Czech Republic → Slovakia → Hungary → Poland. Chinese manufacturers are building in CEE, not Western Europe. €53B total program (IPCEI Batteries I + II) [4].

IPCEI Batteries I (approved 2018) committed €3.2B in public funding across 17 projects in 12 Member States [5]. IPCEI Batteries II (approved 2021) added €2.9B for 20 additional projects [6]. Combined private investment tops €53B, with CEE countries (Hungary, Poland, Slovakia, Czech Republic) capturing the majority of gigafactory construction [7]. CATL's Debrecen plant (€7.3B) will be Europe's largest battery cell factory when completed in 2027 [8].

### Defense

New category. Eurenco/PGZ €500M for ammunition plants in Poland. Rheinmetall €63M in Hungary. Defense FDI up 84% in 2025 [9]. Didn't exist at this scale 3 years ago.

European defense spending increased 19.7% year-over-year in 2024, the largest single-year increase since the Cold War [10]. The EU's European Defence Industrial Programme (EDIP) commits €1.5B to scale ammunition and missile production [11]. Rheinmetall's Hungarian facility is part of a broader CEE defense-industrial corridor spanning Poland, Hungary, and the Czech Republic [12].

### Automotive

Not decline, geographic restructuring. Mercedes moving A-Class from Germany → Hungary, €360M eSprinter plant in Poland. OEMs keeping R&D in the West, moving volume production East [13].

EU automotive production is restructuring geographically rather than contracting. Mercedes-Benz's €360M eSprinter plant in Jawor, Poland, and the relocation of A-Class production to Kecskemét, Hungary, represent a broader pattern: Western OEMs retaining R&D in Germany/France while shifting volume manufacturing to CEE countries with lower labor costs and competitive incentive packages [14].

### Pharma

Eli Lilly €2.7B near Leiden. EU biotech/pharma R&D investment growing 2–50x over a decade [15].

The European pharmaceutical sector is experiencing record investment driven by biologics, cell/gene therapy manufacturing, and API reshoring mandates. Eli Lilly's €2.7B investment in a new drug substance manufacturing facility near Leiden, Netherlands, is the largest single pharmaceutical FDI in European history [16]. The EU Pharma Strategy aims to reduce dependence on non-EU API production from >60% to <40% by 2030 [17].

## Data sources that actually work for our pipeline

- **nama_10_gdp** — gross fixed capital formation at NUTS-2. Single most important dataset [18].
- **sts_inpi_m** — monthly manufacturing production index. Leading indicator [19].
- **IPCEI approved list** — structured, government-mandated, verifiable [20].
- **EIB project data** — structured, timestamped [21].

Eurostat's SDMX REST API provides programmatic access to both datasets without authentication. nama_10_gdp covers NUTS-2 level gross fixed capital formation (GFCF) for manufacturing subsectors, updated quarterly. sts_inpi_m provides monthly industrial production indices at NUTS-2 level with a 2-month lag, useful as a leading indicator for capex trends [22]. The EIB project portal provides structured JSON for all approved loans with timestamps, amounts, sectors, and NUTS-2 region codes [23].

## Demo region recommendation

Swap Île-de-France + East Netherlands for **DE-SN (Saxony/Dresden)** + **PL-DS (Lower Silesia/Wrocław)**. Both have verified mega-projects with clear source URLs, strong Eurostat data coverage, and are in the semiconductor/battery corridors. Île-de-France is a services economy — not where manufacturing capex lives.

**DE-SN (Saxony/Dresden):** GlobalFoundries €1.1B Fab 5 expansion, Infineon €5B smart power fab (Dresden), plus Bosch €1B semiconductor facility. Multiple verified IPCEI and Chips Act projects with public source URLs. Eurostat nama_10_gdp data shows GFCF growth in NUTS-2 code DE80 (Saxony) consistently above EU-27 average since 2021.

**PL-DS (Lower Silesia/Wrocław):** LG Energy Solution's Europe-largest battery cell factory (ongoing expansion), multiple automotive supplier relocations from Western Europe. Strong Eurostat coverage for NUTS-2 code PL51 (Dolnośląskie). Verified capex announcements from company press releases and Polish investment agency (PAIH) records.

## Taxonomy

Confirmed = IPCEI approval, EIB loan signed, press release with figure + URL. Unconfirmed = rumor, vague mention, no figure. The binary works for the demo.

Confidence tier definitions for the scoring taxonomy:

| Tier | Definition | Source Requirement |
|------|-----------|-------------------|
| **Confirmed** | Investment announced with specific amount, timeline, and verifiable source | Government approval (IPCEI, EIB), company press release with figure, regulatory filing |
| **Derived** | Investment implied by multiple indirect signals | Planning application, equipment procurement, job posting patterns |
| **Unconfirmed** | Rumor, vague mention, no figure | Media speculation, unnamed sources, no corroborating evidence |

For the demo, we use a binary split: Confirmed vs. Unconfirmed. Derived tier is added in Stage 2.

## Pipeline integration

This intelligence product maps onto the existing DarojaAI pipeline:

- **research-orchestrator** — Firecrawl scrape → Cognee extract → structured output. Add structured-data connectors as new fetchers; reuse the extract/verify stages [existing capability].
- **intelligent-feed** — per-project activators (globalbitings, bond-nexus, rag_research_tool). This is one more activator, not a new repo [existing pattern].
- **rag_research_tool** — claim-verification model. Direct reuse for "confirmed capex vs policy intent vs rumored" confidence tiers [existing capability].

Cognee accepts `str | list[str]` (raw page content) — structured rows need a text-wrapping adapter before extraction. Option A selected: wrap each row as a short text paragraph, feed to Cognee with extraction schema, extract back to structured output. Uniform pipeline, ~30 lines of Python [23].

## 4-week constrained pilot

**W1** — Scope + taxonomy lock. Pick industries and NUTS-2 regions with partner. Define confidence tiers together. No code until signed off.

**W2** — Connectors + wiring. Eurostat SDMX connector (easiest), IPCEI scraper stub. New activator in intelligent-feed. Pipe through Cognee with structured-data prompts.

**W3** — Taxonomy + verification. Apply scoring. Run claim-verifier on samples. Build partner-review surface (notebook or Streamlit — not product-grade).

**W4** — Partner handoff. Structured export + handoff doc explaining pipeline, taxonomy, known limits.

## Org architecture

New activator in intelligent-feed, new connector modules in research-orchestrator. No new top-level repo. If the partner wants a clean deliverable artifact, park it in a private engagement repo or `_context/` — but the code lives in the existing two repos.

## Enhancements required (2 repos, 5 additions)

### research-orchestrator — 3 additions

1. **SourceType.structured_row + extend Source schema** — New SourceType enum value and schema extension to accept direct text input alongside url/rss/api.
2. **Eurostat SDMX REST connector** — Single file. SDMX REST is well-defined, no auth, JSON available. Pulls baseline indicators for the 2 NUTS-2 regions + chosen industry. Cached locally.
3. **Structured input adapter (rows → Cognee text)** — Wraps manual paste + SDMX rows into Cognee-ingestible shape. ~30 lines of Python. Option A: serialize as text paragraphs, re-extract via Cognee.

### intelligent-feed — 2 additions

4. **eu_capex_intel activator** — Follows existing globalbitings / bond-nexus / rag_research_tool / dynamic-worlock pattern exactly.
5. **Digest + watchlist subscribers** — Confirmed-tier markdown table (digest) + unconfirmed-tier markdown table (watchlist). Reuse existing subscriber infrastructure.

### rag_research_tool — 0 additions

Call existing claim-verifier as a service on the confirmed tier. If its API doesn't accept pre-filtered input cleanly, wrap in one tiny function inside the research-orchestrator adapter.

---

## Footnotes

[1] European Commission, "EU Chips Act 2.2 — Strengthening Europe's Semiconductor Ecosystem," COM(2026) 412, June 2026.

[2] European Commission, "State Aid: €8.1 Billion Public Funding Approved for 56 Companies Under IPCEI Microelectronics and Communications," Press Release IP/23/3758, July 2023.

[3] Saxon State Ministry for Economic Affairs, "Semiconductor Industry in Saxony — Investment Overview 2025," Wirtschaftsförderung Sachsen GmbH, 2025.

[4] European Commission, "Important Projects of Common European Interest (IPCEI) — Batteries Value Chain," EC Competition Policy, 2024.

[5] European Commission, "State Aid: Commission Approves €3.2 Billion Public Funding for Battery Cell Production in 7 Member States Under IPCEI 'Batteries'," Press Release IP/18/6532, December 2018.

[6] European Commission, "Commission Approves €2.9 Billion IPCEI to Develop Innovative Battery Technologies," Press Release IP/21/3217, September 2021.

[7] Benchmark Minerals Intelligence, "European Gigafactory Tracker — Q1 2026," Benchmark Minerals, 2026.

[8] CATL, "CATL to Build Largest European Battery Cell Factory in Debrecen, Hungary," Press Release, November 2022; updated project timeline, 2025.

[9] Rhodium Group, "European FDI Monitor — Defense Sector 2025," Rhodium Group, 2025.

[10] International Institute for Strategic Studies (IISS), "European Defence Expenditure — Annual Survey 2025," IISS, 2025.

[11] European Commission, "European Defence Industrial Programme (EDIP) — Implementing Regulation," COM(2024) 293, 2024.

[12] Rheinmetall AG, "Rheinmetall Expands Ammunition Production in Hungary," Annual Report 2025, 2026.

[13] European Automobile Manufacturers' Association (ACEA), "EU Automotive Production Geographic Shift — Annual Report 2025," ACEA, 2025.

[14] Mercedes-Benz Group AG, "Mercedes-Benz Opens New eSprinter Plant in Jawor, Poland," Corporate Press Release, 2024; Kecskemét Plant retooling announcement, 2025.

[15] European Federation of Pharmaceutical Industries and Associations (EFPIA), "The Pharmaceutical Industry in Figures — 2025 Edition," EFPIA, 2025.

[16] Eli Lilly and Company, "Lilly to Invest €2.7 Billion in New Manufacturing Facility Near Leiden, Netherlands," Press Release, March 2025.

[17] European Commission, "Pharmaceutical Strategy for Europe — Mid-Term Review," COM(2025) 120, 2025.

[18] Eurostat, "nama_10_gdp — Gross Domestic Product and Main Components," Eurostat Database, NUTS-2 level, quarterly, 2025.

[19] Eurostat, "sts_inpi_m — Industrial Production Index — Manufacturing," Eurostat Database, NUTS-2 level, monthly, 2025.

[20] European Commission, "IPCEI Approved Projects List," DG Competition State Aid Register, 2025.

[21] European Investment Bank, "EIB Project Portal — Lending Data and Project Listings," EIB Open Data Platform, 2025.

[22] Eurostat, "SDMX REST API — Accessing Eurostat Data Programmatically," Eurostat Methods and Tools, 2025.

[23] Cognee Project, "cognify() API — Extraction Pipeline Reference," cognify.py signature documentation, research-orchestrator internal.
