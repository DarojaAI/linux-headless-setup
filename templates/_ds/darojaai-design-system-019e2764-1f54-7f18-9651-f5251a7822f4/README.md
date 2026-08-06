# DarojaAI Design System

> An independent AI-strategy practice. The brand voice: plain English, written by one person who does the work. The visual system: a five-color quadrant mark, square edges, hairline rules, paper grain, Sora type.

This project compiles the visual identity standards, content rules, and reusable
UI components for **DarojaAI** — an AI strategy &amp; architecture consultancy
serving small- and mid-sized firms the major consulting firms overlook.

## Source materials

This design system was assembled from one input:

- **GitHub** — `DarojaAI/design-artifacts` &nbsp;([github.com/DarojaAI/design-artifacts](https://github.com/DarojaAI/design-artifacts))
  - `DarojAI Brand Guide.html` — the authoritative brand book (mark anatomy, palette specs, clearspace, typography study)
  - `index.html`, `about.html`, `services.html`, `contact.html` — the marketing site
  - `styles.css`, `site.js` — site implementation
  - `assets/` — logo files at multiple crops, favicons, spec sheets, type-analysis reference

Anyone using this system should read those files for the full original context —
they contain the source-of-truth logo specs and the long-form rationale behind
the type, color, and copywriting choices.

---

## Company context

DarojaAI is a **one-person AI consulting practice** based in Bristol, UK. The
positioning is unusually sharp:

> *Frontier AI for the firms the consultants forgot.*

The practice exists in deliberate opposition to Big Four / McKinsey-style
engagements. Targeted at organisations with **£20m–£500m turnover** in
manufacturing, logistics, regional insurance, public sector, and similar
"long-middle" sectors — too small for a tier-one consulting bill, too critical
to ignore. The founder positions themselves as a single operator who delivers
**strategy, architecture, and the build personally** under fixed scope and
fixed price.

The word *Daroja* is Swahili for *bridge* — a meaning carried directly into
the mark, which is named **The White-Circled Ring Bridge** and centres on a
literal bridge/axes structure across a deeper central void.

**One product surface:** the marketing website (home / services / about / contact).
This is the only public-facing UI; there is no app, no portal, no docs site.

---

## Content fundamentals

### Voice

- **Operator-direct.** The site is written in the founder's first-person voice — *"I am one operator…"*, *"I will say so even when it shortens the engagement."* Not corporate-plural.
- **"We" used sparingly**, mostly for the practice as a brand entity (footer, manifesto headings). When describing the actual work, switch to **"I"**.
- **"You" used directly** to the reader-as-client. *"You get the operator."*, *"You will not be billed for our learning curve."*

### Tone

- **Plain English, low-jargon.** Specific verbs over abstract nouns. *"Ship", "draw", "scope", "say so", "hand over"* — not *"deliver", "leverage", "enable", "operationalise"*.
- **Mild understatement.** *"A defensible plan."*, *"Sensible."*, *"In dreadful shape." (about client data)*. Avoids superlatives.
- **Sharp, occasionally pointed.** The brand is openly contrarian about consulting. *"The largest firms get twelve consultants. Everyone else gets a deck."*  *"What McKinsey gets right — and what they can't ship."*
- **Conversational long-form.** Sentences run long; em-dashes break them. *"We started DarojaAI because the businesses that quietly run the economy — manufacturers, logistics operators, regional insurers, municipal utilities — couldn't get serious AI help without a tier-one budget."*

### Mechanics

- **Sentence case** for headings, eyebrows, and CTAs. UPPERCASE is reserved for
  the **eyebrow** (10–11px, .18em tracking) and small **labels** (.14em).
- **British English** spelling (*organisation, optimise, defence*). UK money
  format: **£28k, £85k, £1.4m**.
- **No exclamation marks.** Period.
- **No emoji.** Period.
- **Ampersands (`&`)** in service-area headings (*"Strategy & Roadmapping"*),
  prose uses *"and."*
- **Single quotes for emphasis** of meaning, double quotes for spoken-style
  hedging. *"Daroja is Swahili for 'bridge.'"* &nbsp;·&nbsp; *`"trends in generative AI"`* (mono, in a derisive quote).
- **Numbers are tabular and short.** *14, 6, $1.4M, 100%, 280 CNC machines,
  62%, 10 weeks.*

### Examples — copy that *is* on-brand

- *"You don't need another 'trends in generative AI' deck. You need a defensible, sequenced plan."*
- *"Strategy without architecture is a wish."*
- *"Hand-off, not hand-cuff."*
- *"Code on the way out."*
- *"Decks don't ship."*
- *"Trust compounds; revenue from the wrong project doesn't."*

### Examples — copy that is *not* on-brand

- ❌ *"Unlock the power of AI."*  → ✅ *"Ship the first three workflows into production."*
- ❌ *"Synergistic transformation."*  → ✅ *"A plan your engineers will respect."*
- ❌ *"World-class AI experts!"*  → ✅ *"One operator. No middle layer."*
- ❌ *"Get in touch today 🚀"*  → ✅ *"A 30-minute conversation. No deck, no pitch."*

---

## Visual foundations

### Colors

Five named brand colors, each **mapped 1:1** to a structural element of the
mark. The mapping is fixed; never substitute or reassign.

| Color           | Hex     | Mark element                | Role on the site                              |
| --------------- | ------- | --------------------------- | --------------------------------------------- |
| Savanna Gold    | `#E6B340` | Top-right quadrant arc      | **Primary accent** — italic emphasis, underlines, focus rings |
| Earth Red       | `#B34A35` | Bottom-right quadrant       | "Enable" service area · don't / error tone   |
| Coastal Azure   | `#3299BB` | Top-left quadrant           | "Architecture" service area                  |
| Acacia Green    | `#708238` | Bottom-left quadrant        | "Build" service area · do / success tone     |
| Elephant Gray   | `#636C70` | Bridge / axes               | Neutral metadata · color-strip mid-tone      |

**Neutrals**

| Token     | Hex       | Role                                                  |
| --------- | --------- | ----------------------------------------------------- |
| Cream     | `#F5F0E8` | Primary surface — the entire site lives on this        |
| Cream 2   | `#EDE6D8` | Secondary surface · tag chips · scope cards            |
| Ink       | `#1C1A16` | Body text · inverted sections (manifesto, banner)      |

**Color rules**

- The accent is **theme-switchable** via `html[data-accent="azure|green|red|gold"]`. Default is gold. Other accents are used when the service area context demands them (e.g. the architecture service detail page leans azure).
- White (`#FFFFFF`) is reserved for the **logo mark's central void** and for the standalone "Mark on white" lockup. The site itself never uses white as a body color.
- Type on cream uses opacity steps off `--ink`: `100% / 55% / 38% / 18% / 10%` — never grey hex values.

### Typography

- **Sora** — the selected typeface. Confirmed in the brand book against five geometric-sans alternatives. Used at weight **200 (Thin)** for displays and headings, **300 (Light)** for body, **400** for buttons and small labels, **500** for eyebrows.
- **JetBrains Mono** — used sparingly, in two places only: **dates** in insight lists (*04 / 2026*), and **durations / metadata** in scope cards and crumbs (*10 weeks*). Never for body, never for headings.
- **Tracking** — display copy is set tight at `-.02em` to `-.015em`. Eyebrows are wide at `.18em`. Labels at `.14em`. Mono captions at `.04em`.
- **Leading** — display 0.94–0.96; body 1.6–1.7. Headings always set with `text-wrap: balance`.
- **One italic accent per headline.** End your H1 on a single italic-gold word/phrase: *"…the consultants forgot."*, *"…built for the long middle."*, *"thirty minutes with me."* — never more.

### Spacing &amp; layout

- **8-px grid**, 4-px sub-units. Sectionalpadding is `clamp(72px, 9vw, 120px)` vertical, `clamp(24px, 5vw, 80px)` horizontal. Container max-width is `1280px`.
- **Vertical rhythm is generous.** Sections breathe; cards have 28–40px internal padding.
- **Grid units are mostly **2 / 3 / 4 columns** with `gap` driving spacing. The grid lines themselves often show through as 1px rules separating cards.

### Borders, radii, surfaces

- **Square edges everywhere.** `border-radius: 0` is the default. The **only** round forms in the system are the **logo mark**, the **6px accent dot** on `.eyebrow`, the **8–14px swatch dot** on `.tag`, and the **9px phase dot** on the process timeline.
- **Hairline rules — never drop shadows.** Surface differentiation comes from 1px borders at `rgba(28,26,22,.10)` (`--rule`) and `.18` (`--rule-2`), plus a small lift toward white for "raised" cards (`color-mix(in oklab, var(--cream) 75%, white)`). The system has **zero `box-shadow` tokens** in active use.
- **Cards = padded boxes with hairline borders and an optional top-rule colored bar** (3px solid color matching the service area). No background fills beyond cream variants and ink.
- **Inputs are bottom-bordered**, not boxed. Underline turns gold on focus.

### Texture &amp; backgrounds

- **Paper grain.** A fixed-position inline-SVG fractal-noise overlay at **4% opacity, `multiply` blend mode** sits over every page. Soft, letterpress-y, never decorative.
- **No gradient backgrounds** anywhere, except for two **utility gradients**:
  1. The marquee's edge masks (cream → transparent, 80px on each side)
  2. The "Manifesto" / "Process" / "Newsletter banner" inverted sections, which are **flat ink** — no gradient.
- **No imagery is rendered by the system.** Photography slots are bracket-captioned placeholders (`[ photograph · plant floor ]`) drawn as 135° diagonal-stripe `media-slot`s waiting for real photos to drop in.
- **No illustration.** The mark is the only graphic.

### Hover, press, motion

- **Hover** on buttons: 1px lift (`transform: translateY(-1px)`) + border darkens to ink. On `.primary`, the fill swaps from ink to gold. On link/insight rows: subtle inset padding shift (`padding-left: 12px`) — the row "scoots" right.
- **Active / press**: no shrink. The system relies on hover affordances.
- **Arrow chevrons** on buttons (`→`) slide 3px right on hover. The arrow is part of the brand — every primary action uses it.
- **Easing** is `cubic-bezier(.2, .7, .2, 1)` (named `--ease-out`), the canonical "rise" curve. Durations: `.15s` (small state changes), `.2s` (most transitions), `.7s` (entrance animations).
- **Entrance**: a single `@keyframes rise` — `translateY(12px)` + `opacity 0` → settled. Applied to hero text and the form panel via `.rise / .rise-1 / .rise-2` staggered delays.
- **The mark in the hero "spins"** — a dashed ring inside it rotates at `90s linear infinite reverse`. The mark itself does not move.
- **No bounces, no scale-ups, no parallax, no scroll-jacking.**

### Iconography

See [`ICONOGRAPHY`](#iconography) below — the system uses **none**.

---

## Iconography

DarojaAI is **near-iconless by design.** The brand voice is plain-English and
the visual system is text-led. The few visual markers used:

- **Arrows (`→` / `←`)**, as Unicode characters in normal type. On every button, every "read more", every breadcrumb, every newsletter submit. The arrow is part of the brand vocabulary.
- **Plus / minus glyphs (`+` / `−`)** as Unicode, in monospace, on FAQ accordions.
- **Check (`✓` / `✗`)** as Unicode, in normal type, for do/don't lists and service-area deliverables.
- **The accent dot** — a 6–9px filled circle in the active color, before eyebrows, before phase markers, in tag chips.
- **The brand mark itself** — used at small sizes (32px nav favicon) and full sizes (hero rotor, footer signature).

**There are no icon fonts, no SVG icon sprites, no PNG icons** anywhere in the
source. There is **no Lucide / Heroicons / Phosphor dependency**. If a design
made with this system needs a UI icon (settings cog, magnifying glass, etc.),
**reach for a Unicode glyph first**; if one is not available, substitute the
closest **Lucide** outline icon (1.5px stroke, square corners) and flag the
substitution — it should match the brand's restrained, square-edged tone.

**No emoji.** Not in product copy, not in marketing copy. The only "emoji-like"
glyphs in the source are the bracket-captioned media-slot placeholders, which
are typographic, not pictographic.

**Logos in `/assets`**

| File | Use |
| --- | --- |
| `logo-mark-transparent.png` | Default — header brand, footer brand, hero rotor |
| `logo-mark.png` | Filled background (use on white sheets only) |
| `logo-mark-circle.png` | Circular crop — social avatars |
| `logo-mark-square.png` | Square crop — app icons |
| `logo-mark-captioned.png` | With wordmark below — spec sheets only |
| `logo-v4.png`, `logo-v5.png` | Archive versions — do not use in new artwork |
| `favicon-32.png`, `favicon-180.png` | Browser favicon &amp; Apple touch icon |
| `typography-analysis.jpg` | Reference image from the type study, not a brand asset |

---

## Index — what's in this folder

```
DarojaAI Design System/
├─ README.md                  ← you are here
├─ SKILL.md                   ← Agent Skills wrapper for Claude Code
├─ colors_and_type.css        ← the authoritative token + element-style layer
│
├─ assets/                    ← logo crops, favicons, type-study reference
│   ├─ logo-mark-transparent.png   (canonical mark)
│   ├─ logo-mark.png               (filled BG version)
│   ├─ logo-mark-{circle,square,captioned}.png
│   ├─ logo-v4.png, logo-v5.png    (archive)
│   ├─ favicon-32.png, favicon-180.png
│   └─ typography-analysis.jpg     (type-study reference, not a brand asset)
│
├─ preview/                   ← Design System tab cards
│   ├─ _card.css
│   ├─ colors-*.html          ← primary / neutrals / mapping / semantic
│   ├─ type-*.html            ← display / scale / eyebrows / emphasis
│   ├─ spacing-*.html         ← scale / radii / elevation / grain
│   ├─ components-*.html      ← buttons / tags / fields / cards / stats / nav / insights
│   └─ brand-*.html           ← mark / lockup / clearspace / voice / color-strip
│
└─ ui_kits/
    └─ website/               ← the only product surface — marketing site
        ├─ README.md          ← what's in the kit, style notes
        ├─ index.html         ← click-thru: home / services / about / contact
        ├─ styles.css         ← mirror of source repo styles.css
        ├─ assets/            ← scoped copy of logo + favicon
        ├─ atoms.jsx          ← Button, Eyebrow, Tag, MediaSlot
        ├─ Chrome.jsx         ← SiteNav, Footer
        ├─ Home.jsx           ← Hero, Marquee, OfferingGrid, Manifesto, StatsRow, CaseGrid, InsightList, BigCTA
        ├─ Services.jsx       ← ServiceRow, Process, PackageGrid, FAQ
        ├─ About.jsx          ← Values, Timeline, Team
        └─ Contact.jsx        ← ContactForm, AltContact, NewsletterBanner
```

---

## Caveats &amp; substitutions

- **Fonts are loaded from Google Fonts CDN**, not bundled as `.ttf` files. Sora and JetBrains Mono are not shipped in the source repo. This is fine for browser rendering; for offline use, PPTX export, or corporate networks that block Google Fonts, the `.ttf` files should be added to `fonts/` and `@font-face`-declared in `colors_and_type.css`.
- **Photography is placeholder.** Every photo slot in the site is a diagonal-stripe `.media-slot` with a bracketed caption. The brand commissions real photography but none is in the source.
- **No icon library is referenced.** The site uses Unicode glyphs only. If a future product surface needs UI icons, Lucide (1.5px outline, square corners) is the closest match to the brand's restraint.
- **One product surface only.** There is no app, portal, or docs site. If a second surface is added later, build a parallel `ui_kits/<name>/` folder, not a parallel design system.
