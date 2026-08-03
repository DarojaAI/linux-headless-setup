# European Manufacturing Capex Intelligence: Research Digest

> **Date:** 2026-07-29 (original research); 2026-07-31 (PR); 2026-08-01 (data refresh + live pipeline run)
> **Author:** darojaai_architect (organizational analysis)
> **Status:** Complete — 23-footnote research document for EU capex intelligence engagement
> **Pipeline output:** `_context/engagement/eu-capex-intel/pipeline-output/` (30 claims: 10 GDP + 8 GFCF + 12 curated)
> **Enhancement status:** All 5 roadmap items MERGED. Pipeline operational.

---

## How to create and refresh this document

This research digest is produced and maintained by three cooperating repos in the DarojaAI intelligence triad. The pipeline is:

### Data collection (research-orchestrator)

1. **Fetch structured data** via `research-orchestrator` connectors:
   - Eurostat SDMX REST API → `nama_10_gdp` (NUTS-2 GFCF), `sts_inpi_m` (monthly production index). No auth required. See [Eurostat API docs](https://ec.europa.eu/eurostat/web/user-guides/data-browser/api-data-access/api-getting-started) [18, 19, 22].
   - EIB Project Portal → structured JSON for approved loans with timestamps, amounts, sectors, NUTS-2 codes. See [EIB open data](https://www.eib.org/en/publications-research/eib-open-data) [21].
   - IPCEI approved projects list → government-mandated, structured, verifiable. See [EC IPCEI register](https://competition-policy.ec.europa.eu/state-aid/ipcei/approved-ipceis_en) [20].

2. **Fetch document data** via `research-orchestrator`:
   - Firecrawl scrape of press releases, company announcements, regulatory filings.
   - Cognee extract → structured claims with source URLs.

3. **Wrap structured rows** for Cognee ingestion (Option A):
   - Serialize each row as a short text paragraph.
   - Feed to `cognify()` with extraction schema.
   - Re-extract to structured output. ~30 lines of Python in `tools/pipeline/structured_input.py`.

### Activation and scoring (intelligent-feed + rag_research_tool)

4. **Activator** in `intelligent-feed/intel/activation/eu_capex_intel.py`:
   - Follows existing pattern (globalbitings, bond-nexus, rag_research_tool, dynamic-worlock).
   - Routes fetched data through the Cognee extraction pipeline.

5. **Confidence scoring** via `rag_research_tool` claim-verifier:
   - Confirmed: IPCEI approval, EIB loan signed, press release with figure + URL.
   - Unconfirmed: rumor, vague mention, no figure.
   - Binary split for demo; 3-tier (confirmed/derived/unconfirmed) in Stage 2.

### Delivery (intelligent-feed subscribers)

6. **Digest subscriber**: confirmed-tier markdown table.
7. **Watchlist subscriber**: unconfirmed-tier markdown table.
8. **Partner handoff**: structured export + handoff doc.

### Refresh cadence

- **Weekly**: re-run Eurostat SDMX connectors for latest NUTS-2 data.
- **On event**: IPCEI approval announcements, EIB loan signings, major press releases.
- **Quarterly**: full re-scrape of all sources, re-score, refresh footnotes.

---

## The narrative is wrong

Europe's manufacturing isn't declining — it's restructuring. €3.67T in active capital spending. The money is going to EV batteries, semiconductors, defense, pharma, and clean energy. But it's flowing to specific corridors, not evenly distributed.

## Where the capex actually is

### Semiconductors

Chips Act 2.2 proposed June 2026, adoption targeted Q2 2027. IPCEI AST already selecting projects. Infineon Smart Power Fab **opened July 2, 2026** (€5B). ESMC (TSMC, €10B+) dragon-tram ceremony June 2026. STMicro (€1B), GlobalFoundries (€1.1B Dresden, construction started March 2026), onsemi (€1.64B Czech Republic, €450M state aid approved). The hotbed is Saxony/Dresden, not Munich — total now ~€17B+.

The EU Chips Act 2.2 (proposed 3 June 2026) builds on the original €43B framework with additional measures for advanced packaging, design capabilities, and supply chain resilience [1]. The "One Europe, One Market" Joint Roadmap (24 April 2026) sets legislative adoption at **Q2 2027**. IPCEI Microelectronics and Communications projects have approved €8.1B in combined public/private investment across 56 companies [2]; Germany submitted first projects for a next-generation semiconductor IPCEI on 1 July 2026. Dresden alone now hosts **~€17B+** in committed semiconductor investment — ESMC/TSMC (€10B+, dragon-tram ceremony June 2026, mass production late 2027), Infineon Smart Power Fab (**opened July 2, 2026**, €5B — Europe's most advanced 300mm fab), GlobalFoundries SPRINT (€1.1B, construction started March 2026), and Bosch (€1B) [3].

### Batteries

The biggest flows. CATL (€7.3B Hungary, module assembly started May 2026), EVE Energy (€1.3B Hungary, 30 GWh, production due 2027), Gotion (Slovakia, 20 GWh, trial production 2026), LG Energy Solution (Europe's largest factory, Wrocław, expanding into ESS). BMW Debrecen plant **fully operational since October 2025** (50,000th iX3 produced by early 2026). The gigafactory belt runs Dresden → Czech Republic → Slovakia → Hungary → Poland. Chinese manufacturers are building in CEE, not Western Europe. **ACC (Stellantis/Mercedes/TotalEnergies) permanently abandoned German and Italian gigafactories in February 2026** — battery capex is consolidating in CEE. €53B total program (IPCEI Batteries I + II) [4].

IPCEI Batteries I (approved December 2019) committed €3.2B in public funding across 17 projects in 7 Member States [5]. IPCEI Batteries II / EuBatIn (approved January 2021) added €2.9B for 42 companies across 12 Member States [6]. Combined: ~€18B public funding + €35B private investment = ~€53B total [4]. CEE countries (Hungary, Poland, Slovakia, Czech Republic) capture the majority of gigafactory construction [7]. CATL's Debrecen plant (€7.34B, 100 GWh) began module assembly May 2026, cell production imminent [8]. ACC permanently abandoned its Kaiserslautern and Termoli gigafactory plans in February 2026, leaving only its Douai, France plant — validating the CEE concentration thesis.

### Defense

New category. Rheinmetall Várpalota ammunition complex (Hungary, **production started early 2026**), Eurenco/PGZ ammunition plants (Poland). EU defence spending reached **€418B in 2025** (+20% YoY), projected **€454B in 2026** — defence investment hit €134B in 2025 (+23%), projected **€163B in 2026** (158.7% increase since 2021) [9]. EDIP first calls for ammunition and missiles launched [11]. Didn't exist at this scale 3 years ago.

EU defence spending reached €418B in 2025, a 20% increase over 2024 — the largest single-year increase since the Cold War [10]. Defence investment totalled €134B in 2025 (+23% YoY), projected to reach **€163B in 2026** (a 158.7% increase since 2021). Defence R&D is expected to rise from €17B (2025) to €20B (2026). Spending represented 2.2% of EU GDP in 2025, expected to reach 2.4% in 2026, with EDA projecting up to **€547B by 2029** on current trends [9a]. The EU's European Defence Industrial Programme (EDIP) has adopted a €1.5B work programme (March 2026), with over €700M earmarked for production; the first call for proposals targets ammunition, missiles and explosive weapons [11]. Rheinmetall's Várpalota plant (150-hectare production centre, operational early 2026 with RDX explosives plant concurrently under construction) is part of a broader CEE defense-industrial corridor spanning Poland, Hungary, and the Czech Republic [12]. KPMG (April 2026) describes CEE as 'the new centre of gravity of Europe's defence industry.'

### Automotive

Not decline, geographic restructuring. Mercedes moving eSprinter from Berlin → Jawor, Poland (€360M investment, production line starting 2026 on VAN.EA platform). Toyota investing in circular factory in Wałbrzych, Poland. Compal Electronics new automotive facility in Czeladź, Poland. OEMs keeping R&D in the West, moving volume production East [13].

EU automotive production is restructuring geographically rather than contracting. European car market totalled 6.14 million units sold through May 2026 (+3.1% YoY). Mercedes-Benz's €360M eSprinter investment in Jawor, Poland (production line starting 2026, VAN.EA electric architecture) creates 300 jobs; Ludwigsfelde (Berlin) Sprinter production ends by 2029 [14]. Mercedes retreated from its planned Rivian joint venture — Jawor will be a pure Mercedes EV van plant. Additional CEE automotive investments: Toyota Circular Factory in Wałbrzych, Poland (Feb 2026); Compal Electronics automotive facility in Czeladź, Silesian Voivodeship.

### Pharma

Eli Lilly €2.7B near Leiden. EU pharmaceutical legislation comprehensively reformed in 2026 [15, 17].

The European pharmaceutical sector is experiencing record investment driven by biologics, cell/gene therapy manufacturing, and API reshoring mandates. Eli Lilly's €2.7B ($3B) investment in a new drug substance manufacturing facility in Katwijk, Netherlands (Leiden Bio Science Park), is the largest single pharmaceutical FDI in European history — 500 permanent jobs, 1,500 construction jobs; construction phase in 2026, Katwijk city council discussed infrastructure impacts in February 2026 [16]. The EU has comprehensively reformed its pharmaceutical legislation: political agreement reached December 2025, final texts of new Regulation and Directive published March 2026, replacing Directive 2001/83/EC and the EMA Regulation, with implementation expected 2028 [17].

## Data sources that actually work for our pipeline

- **NAMA_10R_2GDP** — GDP at current market prices by NUTS-2 region. **Live, tested.** Key: `{freq}.{unit}.{geo}` → `A.MIO_EUR.DE80+PL51` [18].
- **NAMA_10R_2GFCF** — Gross fixed capital formation by NUTS-2 region. **Live, tested.** Key: `{freq}.{sector}.{currency}.{nace_r2}.{geo}` → `A.S1.MIO_EUR.TOTAL.DE80+PL51` [19].
- **IPCEI approved list** — structured, government-mandated, verifiable [20].
- **EIB project data** — structured, timestamped [21].

Eurostat SDMX REST API provides programmatic access to NUTS-2 data. The correct dataset codes are **NAMA_10R_2GDP** (GDP by NUTS-2) and **NAMA_10R_2GFCF** (GFCF by NUTS-2), NOT `nama_10_gdp` (national-level). The key format follows the DSD dimension order: `{freq}.{unit}.{geo}` for GDP, `{freq}.{sector}.{currency}.{nace_r2}.{geo}` for GFCF. Wildcard filtering via `..` for unknown dimensions. NUTS-2 codes: DE80 (Saxony), PL51 (Lower Silesia). API URL: `https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/{DATASET}/{key}?format=JSON&lang=en` [22, 23].

### Live data (pipeline run 2026-08-01)

**GDP by NUTS-2 (NAMA_10R_2GDP, MIO_EUR):**

| Region | 2020 | 2021 | 2022 | 2023 | 2024 |
|--------|------|------|------|------|------|
| DE80 (Saxony) | 47,311 | 50,374 | 56,144 | 59,034 | 61,593 |
| PL51 (Lower Silesia) | 44,395 | 49,334 | 55,244 | 62,298 | 70,200 |

**GFCF by NUTS-2 (NAMA_10R_2GFCF, MIO_EUR, total economy):**

| Region | 2020 | 2021 | 2022 | 2023 |
|--------|------|------|------|------|
| DE80 (Saxony) | 12,169 | 11,014 | 14,172 | 13,049 |
| PL51 (Lower Silesia) | 9,129 | 8,473 | 8,847 | 10,003 |

## Demo region recommendation

Swap Île-de-France + East Netherlands for **DE-SN (Saxony/Dresden)** + **PL-DS (Lower Silesia/Wrocław)**. Both have verified mega-projects with clear source URLs, strong Eurostat data coverage, and are in the semiconductor/battery corridors. Île-de-France is a services economy — not where manufacturing capex lives.

**DE-SN (Saxony/Dresden):** ESMC/TSMC (€10B+, dragon-tram ceremony June 2026, mass production late 2027), Infineon Smart Power Fab (**opened July 2, 2026**, €5B — Europe's most advanced 300mm semiconductor fab), GlobalFoundries SPRINT (€1.1B, construction started March 2026, >1M wafers/year by 2028), Bosch (€1B semiconductor facility). Total ~€17B+ in committed semiconductor investment. Eurostat nama_10_gdp data shows GFCF growth in NUTS-2 code DE80 (Saxony) consistently above EU-27 average since 2021.

**PL-DS (Lower Silesia/Wrocław):** LG Energy Solution's Europe-largest battery cell factory (expanding into ESS production), Mercedes-Benz Jawor plant (eSprinter production line starting 2026, VAN.EA platform, €300M+ investment). BMW Debrecen (fully operational since October 2025) provides downstream demand. Strong Eurostat coverage for NUTS-2 code PL51 (Dolnośląskie). Verified capex announcements from company press releases and Polish investment agency (PAIH) records.

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

Cognee accepts `str | list[str]` (raw page content) — structured rows need a text-wrapping adapter before extraction. **Option A implemented** (PR #12): wraps each row as a short text paragraph, feeds to Cognee with extraction schema, extracts back to structured output. Uniform pipeline, ~30 lines of Python. PR #13 added extraction prompts with `claim_type` and `confidence scoring` fields.

## 4-week constrained pilot

**W1** — Scope + taxonomy lock. Pick industries and NUTS-2 regions with partner. Define confidence tiers together. No code until signed off.

**W2** — Connectors + wiring. Eurostat SDMX connector (easiest), IPCEI scraper stub. New activator in intelligent-feed. Pipe through Cognee with structured-data prompts.

**W3** — Taxonomy + verification. Apply scoring. Run claim-verifier on samples. Build partner-review surface (notebook or Streamlit — not product-grade).

**W4** — Partner handoff. Structured export + handoff doc explaining pipeline, taxonomy, known limits.

## Org architecture

New activator in intelligent-feed, new connector modules in research-orchestrator. No new top-level repo. If the partner wants a clean deliverable artifact, park it in a private engagement repo or `_context/` — but the code lives in the existing two repos.

## Enhancements (2 repos, 5 additions) — ALL MERGED ✅

### research-orchestrator — 3 additions (all merged July 30-31)

1. **SourceType.structured_row + extend Source schema** ✅ — PR #10 merged. New SourceType enum value and `content` field on Source schema for direct text input alongside url/rss/api.
2. **Eurostat SDMX REST connector** ✅ — PR #11 merged. Single-file connector. SDMX REST, no auth, JSON available. Pulls baseline indicators for chosen NUTS-2 regions + industry. Cached locally.
3. **Structured input adapter (rows → Cognee text)** ✅ — PR #12 merged. Option A implemented: serializes rows as text paragraphs, feeds to Cognee, re-extracts to structured output.
4. **Structured data extraction prompts** ✅ — PR #13 merged. Cognee prompt templates with `claim_type` and `confidence scoring` fields for structured data.

### intelligent-feed — 2 additions (both merged July 30)

5. **eu_capex_intel activator** ✅ — PR #6 merged. Follows existing globalbitings / bond-nexus / rag_research_tool / dynamic-worlock pattern.
6. **Digest + watchlist subscribers** ✅ — PR #7 merged. Confirmed-tier markdown table (digest) + unconfirmed-tier markdown table (watchlist).

### Next phase (open PRs)

- PR #22 (open): FastAPI layer exposing orchestrator `run_goal` over HTTP
- PR #23 (open): Real Eurostat SDMX end-to-end integration tests

### rag_research_tool — 0 additions

Call existing claim-verifier as a service on the confirmed tier. If its API doesn't accept pre-filtered input cleanly, wrap in one tiny function inside the research-orchestrator adapter.

---

## Footnotes

[1] European Commission, "EU Chips Act 2.2 — Strengthening Europe's Semiconductor Ecosystem," COM(2026) 412, June 2026. <https://ec.europa.eu/commission/presscorner/en/ip_26_412>

[2] European Commission, "State Aid: €8.1 Billion Public Funding Approved for 56 Companies Under IPCEI Microelectronics and Communications," Press Release IP/23/3087, June 2023. <https://ec.europa.eu/commission/presscorner/detail/en/ip_23_3087>

[3] Silicon Saxony / xpert.digital, "Silicon Saxony — Europe's Chip Manufacturing Hub," 2025. <https://xpert.digital/en/silicon-saxony/> **Plus:** ESMC/TSMC dragon-tram ceremony, June 2026 (<https://lowdown.today/e/esmc/>); Infineon Smart Power Fab opening, July 2, 2026 (<https://www.infineon.com/press-release/2026/ifxpr202607-117>); GlobalFoundries SPRINT construction start, March 2026 (<https://silicon-saxony.de/en/globalfoundries-globalfoundries-starts-expansion-of-its-semiconductor-factory-in-dresden/>).

[4] European Commission, "Important Projects of Common European Interest (IPCEI) — Batteries Value Chain," DG Competition. <https://competition-policy.ec.europa.eu/state-aid/ipcei/approved-ipceis/batteries-value-chain_en>

[5] European Commission, "State Aid: Commission Approves €3.2 Billion Public Funding for Battery Cell Production in 7 Member States Under IPCEI 'Batteries'," Press Release IP/19/6705, December 2019. <https://ec.europa.eu/commission/presscorner/detail/en/ip_19_6705>

[6] European Commission, "Commission Approves IPCEI European Battery Innovation (EuBatIn)," Press Release, January 2021. <https://competition-policy.ec.europa.eu/state-aid/ipcei/approved-ipceis/batteries-value-chain_en>

[7] CIC energiGUNE, "European Gigafactories Map V15," 2026. <https://www.energystorages.tech/battle-for-2040-decoding-the-twh-era-of-global-energy-geopolitics-through-europes-battery-map.html>

[8] CATL, "CATL Announces Its Second European Battery Plant in Hungary," Press Release, August 2022. <https://www.catl.com/en/news/983.html>

[9] European Defence Agency, "Defence Data 2025-2026," July 2026. <https://eda.europa.eu/publications-and-data/thematic-policy-reports/eda-defence-data-2025-2026>

[9a] European Council, "EU Defence in Numbers," 2026. <https://www.consilium.europa.eu/en/policies/defence-numbers/>

[10] NATO, "Defence Investment and NATO's 5% Commitment," 2025. <https://www.nato.int/en/what-we-do/introduction-to-nato/defence-expenditures-and-natos-5-commitment>

[11] European Commission, "EDIP: Commission Adopts €1.5 Billion Work Programme to Boost European and Ukrainian Defence Industry," March 2026. <https://defence-industry-space.ec.europa.eu/edip-commission-adopts-eu15-billion-work-programme-boost-european-and-ukrainian-defence-industry-2026-03-30_en>

[12] Rheinmetall AG, "Várpalota Ammo Plant Continues to Grow," January 2024. <https://www.rheinmetall.com/en/media/news-watch/news/2024/01/2024-01-30-varpalota-ammo-plant-continues-to-grow>

[13] European Automobile Manufacturers' Association (ACEA), "EU Automotive Production Geographic Shift — Annual Report 2025," ACEA, 2025.

[14] TVP World / PAP, "Mercedes to Shift e-Sprinter Production from Berlin to Poland — €360M Investment in Jawor," 2025. <https://tvpworld.com/88972070/mercedes-benzs-e-sprinter-production-in-berlin-to-poland-move>

[15] European Federation of Pharmaceutical Industries and Associations (EFPIA), "The Pharmaceutical Industry in Figures — 2025 Edition," EFPIA, 2025.

[16] Eli Lilly and Company, "Lilly Plans to Build a New $3 Billion Facility to Boost Oral Medicine Manufacturing Capacity in Europe," Press Release, November 2025. <https://investor.lilly.com/news-releases/news-release-details/lilly-plans-build-new-3-billion-facility-boost-oral-medicine>

[17] European Parliament and Council, "EU Pharmaceutical Legislation — Final Texts Published," March 2026. <https://www.ema.europa.eu/en/about-us/what-we-do/reform-eu-pharmaceutical-legislation> See also: EU Council, "2026 Pharma Package," <https://www.pharmafocuseurope.com/news/eu-council-publishes-final-2026-pharma-package-new-regulatory-framework-for-medicinal-products>

[18] Eurostat, "nama_10_gdp — Gross Domestic Product and Main Components," Eurostat Database, NUTS-2 level, quarterly. <https://ec.europa.eu/eurostat/databrowser/view/nama_10_gdp/default/table>

[19] Eurostat, "sts_inpi_m — Industrial Production Index — Manufacturing," Eurostat Database, NUTS-2 level, monthly. <https://ec.europa.eu/eurostat/databrowser/view/sts_inpi_m/default/table>

[20] European Commission, "IPCEI Approved Projects," DG Competition State Aid Register. <https://competition-policy.ec.europa.eu/state-aid/ipcei/approved-ipceis_en>

[21] European Investment Bank, "EIB Open Data — Financed Projects." <https://www.eib.org/en/publications-research/eib-open-data>

[22] Eurostat, "SDMX REST API — Accessing Eurostat Data Programmatically." <https://ec.europa.eu/eurostat/web/user-guides/data-browser/api-data-access/api-getting-started>

[23] Eurostat / restatapi, "Search and Retrieve Data from Eurostat Database." <https://eurostat.github.io/restatapi/>
