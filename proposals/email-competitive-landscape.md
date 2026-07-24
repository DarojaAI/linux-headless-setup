# Email Activity Analysis — Competitive Landscape & Build-vs-Buy Assessment

> **Date:** 2026-07-24
> **Status:** Research complete — ready for operator review
> **Purpose:** Before building, assess what already exists that could help or should be evaluated

---

## TL;DR

**Nothing does exactly what you want** (activity-category classification with concentric ring chart output, in-customer deployment, configurable taxonomy). But several existing tools cover parts of the problem. The strongest "don't build" case is: **why not use Microsoft Viva Insights + Power BI for Exchange customers, and Google Work Insights + a custom layer for Gmail customers?** The answer is: customization, in-customer deployment, and the LLM classification layer that none of them offer.

---

## Tier 1: Platform-Native Tools (already in the customer's stack)

These are free/included with existing licenses. If the customer already pays for M365 or Google Workspace, these are the path of least resistance.

### Microsoft Viva Insights
- **What it does:** Aggregates email + calendar + Teams + OneDrive metadata. Measures focus time, meeting load, after-hours work, collaboration patterns, network health.
- **Data access:** Email metadata (not content), calendar events, Teams messages (metadata), file activity. Privacy-first: minimum group size of 5 for any query.
- **Export:** Power BI connector + Microsoft Graph Data Connect (MGDC) for Azure data lake export. R and Python sample code for custom analysis.
- **What it DOESN'T do:** No LLM-based content classification. No activity category breakdown (meetings vs. info-chasing vs. reporting). Pre-built metrics only.
- **Pricing:** Included with M365 E3/E5. Advanced analytics require E5 or Viva Insights add-on (~$4/user/mo).
- **In-customer:** Yes — runs entirely within the M365 tenant. No data leaves Microsoft's cloud.
- **Verdict for us:** ✅ **Best data source for Exchange/M365 customers.** The MGDC export gives us raw metadata we could feed our LLM classifier on top. This could be a Phase 1 accelerator: use Viva Insights as the data pipe, add our classification layer on top.

### Google Work Insights
- **What it does:** Adoption metrics, meeting patterns, collaboration trends across Gmail, Calendar, Drive, Meet.
- **Data access:** Usage metadata only — emails sent/received counts, meeting hours, document sharing. No email content.
- **Export:** Limited — admin reports API, no raw data export to external systems.
- **What it DOESN'T do:** Same as Viva — no content classification, no activity categories, pre-built metrics only.
- **Pricing:** Included with Google Workspace Business/Enterprise.
- **In-customer:** Yes.
- **Verdict for us:** ⚠️ **Good for baseline metrics, but limited export.** Less useful as a data pipe than Viva Insights.

---

## Tier 2: Third-Party SaaS Analytics (already built, already working)

These are established products that do email/calendar analytics. They don't do LLM activity classification, but they're worth knowing about.

### Worklytics
- **What it does:** Privacy-first workplace analytics. Email + calendar + Slack + Teams metadata analysis. Organizational network analysis (ONA), collaboration patterns, AI adoption tracking.
- **Data sources:** Gmail, Outlook, Calendar, Slack, Teams, Zoom, Asana, Jira, GitHub. Both platforms covered.
- **Classification:** Metadata-level only (who emailed whom, how often, response times). No content classification.
- **Pricing:** Free tier (100 users, calendar only, 30 days). Business: $2,500/mo + $10/user/mo. Enterprise: custom.
- **In-customer:** No — SaaS only. Data flows through their cloud.
- **Privacy:** Strong — metadata-only, no message content, aggregate-only outputs.
- **Verdict for us:** ❌ **Don't build. Consider as a reference for what "done" looks like.** Too expensive for small orgs. The privacy-first metadata approach is the right design pattern to emulate, but their pricing puts it out of reach for most of our target market.

### EmailAnalytics (by Email Meter)
- **What it does:** Email volume tracking, response time, activity by hour/day/team. Gmail and Outlook support.
- **Classification:** Volume-based only. "You sent 47 emails today." No content classification.
- **Pricing:** Per-user, tiered. Free tier available for individual use.
- **In-customer:** No — SaaS.
- **Verdict for us:** ❌ **Too shallow.** Shows volume metrics, not activity categories. Good for individual productivity tracking, not organizational analysis.

### Time is Ltd.
- **What it does:** Workforce analytics — meeting analytics, email patterns, communication network analysis, time allocation.
- **Data sources:** Email, calendar, Teams, Slack. Metadata-level analysis.
- **Classification:** Basic — meeting time, email time, after-hours work. No LLM-based content classification.
- **Pricing:** Enterprise, custom. Not publicly listed.
- **In-customer:** SaaS only.
- **Verdict for us:** ⚠️ **Closest to what we want conceptually**, but no content classification and SaaS-only.

### Flowtrace
- **What it does:** Meeting analytics specifically — meeting cost, quality, patterns, recurring meeting analysis.
- **Data sources:** Calendar + video conferencing metadata.
- **Classification:** Meeting-focused only. No email content classification.
- **Pricing:** SaaS, tiered.
- **In-customer:** SaaS only.
- **Verdict for us:** ⚠️ **Good reference for the "meetings" slice of our problem.** Could complement our tool if we don't build calendar analytics ourselves.

### SaneBox
- **What it does:** AI email triage — auto-sorts incoming mail by importance. Folders: SaneLater (unimportant), SaneNews (newsletters), SaneBlackHole (unsubscribe).
- **Classification:** Binary-ish (important vs. not important). No activity categories.
- **Pricing:** $7-36/user/year.
- **In-customer:** No — SaaS.
- **Verdict for us:** ❌ **Wrong problem.** SaneBox is for individual inbox management, not organizational analytics. But interesting: it does server-level email classification without content access, which is a privacy-friendly pattern.

---

## Tier 3: Open-Source & DIY Building Blocks

These could accelerate our build or serve as starting points.

### Win Gillis — Email Categorization with Local LLMs (GitHub)
- **What it does:** Full pipeline — Gmail API → LLM classification → lightweight SVC classifier. Compares local LLMs (8B-70B params) for email categorization.
- **Key finding:** 8B-parameter models plateau in accuracy. SVC trained on LLM labels catches up. The LLM is the teacher; the SVC is the student.
- **Relevance:** ✅ **Directly applicable to our approach.** The pipeline structure (LLM labels → train classifier → run cheap classifier at scale) is exactly our Track A → Track C plan.
- **Code:** https://github.com/wingillis/email-categorization-with-llms
- **Verdict for us:** ✅ **Study this first.** Can we reuse his prompt templates and SVC training pipeline? Probably not directly (his categories are personal, not activity-based), but the architecture is validated.

### gws-productivity-analytics (GitHub)
- **What it does:** Google Workspace Admin SDK → productivity scores across communication, collaboration, focus time, tool utilization.
- **Data sources:** Admin reports API (usage metadata, not email content).
- **Classification:** Rule-based scoring with custom KPIs. No LLM.
- **Relevance:** ⚠️ **Good for the Google data pipe, but no content classification.** Could be adapted as a Gmail connector baseline.
- **Code:** https://github.com/Haassy/gws-productivity-analytics

### n8n + LLM Email Classification Workflows
- **What it does:** Low-code workflow automation. Multiple pre-built workflows for email classification using GPT-4o/Claude. Outlook and Gmail connectors.
- **Key workflows:**
  - Automatic email categorization with Outlook + GPT-4o (zero manual mapping, auto-discovers folders)
  - Autonomous email management with GPT-5-mini + human-in-the-loop
  - Email classification with Gemini/OpenAI using batching + structured JSON output
- **Relevance:** ⚠️ **Interesting for rapid prototyping, but wrong for production.** n8n is a workflow tool, not an analytics platform. You could classify emails with it, but you'd still need the metrics aggregation and visualization layer.
- **Verdict for us:** ⚠️ **Could use for Phase 1 prototyping.** If we need to classify 500 Enron emails quickly to validate our taxonomy, an n8n workflow gets us there in hours instead of days. But not for production.

### NLP-Email-Categorizer (GitHub)
- **What it does:** Naive Bayes text classification for email subjects. Jupyter notebook-based, preprocessing + hyperparameter tuning.
- **Relevance:** ❌ **Too narrow.** Subject-only classification, no body analysis, no attachment analysis, no thread analysis.
- **Code:** https://github.com/VoxDroid/NLP-Email-Categorizer

---

## Tier 4: What Doesn't Exist (our gap)

After reviewing ~30 tools and projects, here's what's genuinely missing:

| Gap | Why it matters | Who might fill it |
|---|---|---|
| **LLM-based email content classification for activity categories** | Every existing tool does metadata analysis (volume, timing, recipients) but none classify WHAT people are actually doing (scheduling, reporting, chasing info) | **Us.** This is our core differentiator. |
| **In-customer deployment for email analytics** | Every SaaS tool requires data to leave the customer's network. Our "Option A" (Docker in-customer) fills this gap. | **Us.** This is our architecture differentiator. |
| **Configurable taxonomy for email activity** | Existing tools have fixed metrics. No tool lets you define custom activity categories and retrain. | **Us.** Our YAML config approach. |
| **Before/after activity comparison with automation recommendation** | Existing tools show current state. None propose "if you automated X, you'd save Y hours." | **Partially us.** The dashboard we're targeting does this; no existing tool does. |
| **Multi-source (email + calendar + tasks) with content-level classification** | Worklytics/Time is Ltd. do multi-source metadata. Nobody does multi-source with content classification. | **Us** (Phase 2/3). |

---

## The "Don't Build" Argument

The strongest case for NOT building is:

> "For M365 customers: just use Viva Insights. It's already included, already private, already has the data. Export to Power BI and make your charts there."

**This is valid for a specific use case:** if the customer already has E5 licenses and just wants to visualize meeting load vs. email volume vs. focus time. Viva Insights + Power BI gets them 60% of the way there.

**It falls short when:**
1. They need **content-level classification** (what TYPE of email activity, not just how many)
2. They're on **Google Workspace** (Viva doesn't help)
3. They need **custom categories** tied to their specific business processes
4. They need **before/after optimization recommendations**, not just current-state metrics
5. They need **in-customer deployment** without M365 E5 (which not all orgs have)
6. They want a **single tool** that works across both platforms

---

## The "Build Anyway" Argument

Our tool fills a genuine gap:

1. **Content classification is the differentiator.** "40% of emails are meeting coordination" is more actionable than "you sent 347 emails this month." Nobody does this.

2. **In-customer deployment is a hard requirement** per your decision. No existing tool offers this.

3. **The LLM classification approach is new.** Win Gillis proved it works for personal email. Applying it to corporate activity analysis at scale, with configurable taxonomy, is novel.

4. **Cost advantage.** Worklytics at $2,500/mo + $10/user/mo is prohibitive for most orgs. A self-hosted Docker image with OpenRouter API costs pennies per classification.

5. **Taxonomy configurability.** Every org's activity categories are different. Fixed-metric tools can't adapt.

---

## Recommended Approach: Build on Existing Foundations

Don't build from scratch. Build on top of what exists:

### Phase 1: Use existing data pipes
- **Exchange/M365:** Use Microsoft Graph API (same as Viva Insights uses internally) for email + calendar metadata. No need to build an Exchange connector from scratch — the Microsoft Graph SDK exists.
- **Gmail:** Use Gmail API + Google Calendar API. The Google Workspace Admin Reports API gives you usage metadata for free.
- **IMAP:** Fallback connector for other systems.

### Phase 2: Add our differentiator (LLM classification)
- This is where we build. No existing tool does this.
- Start with Enron dataset, validate taxonomy, then apply to real data.

### Phase 3: Add our second differentiator (in-customer Docker)
- Package everything as a self-contained container.
- No existing email analytics tool does this.

### Phase 4: Graphic generation
- matplotlib/plotly for concentric ring charts.
- Could also integrate with Power BI (for Viva Insights customers) or Looker Studio (for Google customers) as an alternative output.

---

## Cost Comparison

| Approach | Upfront cost | Ongoing cost | Content classification | In-customer |
|---|---|---|---|---|
| Viva Insights + Power BI | $0 (already included) | $0 extra | ❌ No | ✅ Yes |
| Worklytics | $0 (setup) | $2,500/mo + $10/user | ❌ No | ❌ No |
| EmailAnalytics | $0 | Per-user SaaS | ❌ No | ❌ No |
| Time is Ltd. | $0 | Custom enterprise | ❌ No | ❌ No |
| **Our tool** | **~9-12 weeks dev** | **OpenRouter API cost** | **✅ Yes** | **✅ Yes** |

---

## Bottom Line

**For customers who already have M365 E5:** Viva Insights is the baseline. Our tool adds the LLM classification layer on top. Consider offering both: "use Viva Insights for baseline metrics, add our classifier for activity breakdown."

**For customers on Google Workspace:** Work Insights is limited. Our tool is the better option.

**For customers who need in-customer deployment:** Nobody else offers this. We're alone in this space.

**For customers who need custom activity categories:** Nobody else offers this. We're alone in this space.

**The LLM classification layer is the moat.** Everything else (data pipes, metrics, visualization) has existing solutions. The part that doesn't exist — "classify WHAT people are doing in their emails, not just how many emails they send" — is what we're building.

---

## Next Steps

1. Study Win Gillis' pipeline (https://github.com/wingillis/email-categorization-with-llms) — validate architecture
2. Download Enron dataset, run initial LLM classification on 100 emails
3. Prototype: n8n workflow to classify Enron emails by our taxonomy → validate approach
4. Build the MVP: email-connector + LLM classifier + metrics aggregation + graphic generator
