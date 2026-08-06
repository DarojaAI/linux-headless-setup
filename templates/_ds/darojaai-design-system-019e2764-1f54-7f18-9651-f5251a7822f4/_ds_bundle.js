/* @ds-bundle: {"format":4,"namespace":"DarojaAIDesignSystem_019e27","components":[],"sourceHashes":{"ui_kits/website/About.jsx":"fc89b4975224","ui_kits/website/Chrome.jsx":"6cc6c8bd3741","ui_kits/website/Contact.jsx":"89bbebcc4c3c","ui_kits/website/Home.jsx":"df167f01c89a","ui_kits/website/Services.jsx":"e83b1a8c46d7","ui_kits/website/atoms.jsx":"d9adf024baa5"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.DarojaAIDesignSystem_019e27 = window.DarojaAIDesignSystem_019e27 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// ui_kits/website/About.jsx
try { (() => {
// About-page sections — Values, Timeline, Team.

function Values() {
  const items = [["01", "Decks don't ship.", "Every engagement ends with working software, not a PDF. If we can't deliver code, we won't take the engagement."], ["02", "You get the operator.", "The person who sold the engagement is the person who does the work. There is no one to hand you off to."], ["03", "Tell the client no.", "Most AI investments are not worth making. I will say so, even when it shortens the engagement."], ["04", "Code belongs to you.", "No platform licences, no embedded dependencies on my continued involvement. The product of the work is yours to extend or throw away."]];
  return /*#__PURE__*/React.createElement("section", null, /*#__PURE__*/React.createElement("div", {
    className: "wrap"
  }, /*#__PURE__*/React.createElement("div", {
    className: "grid-2",
    style: {
      alignItems: "end",
      marginBottom: 64
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 24
    }
  }, "\u2014 What we believe"), /*#__PURE__*/React.createElement("h2", {
    style: {
      marginTop: 0
    }
  }, "Four working", /*#__PURE__*/React.createElement("br", null), "principles.")), /*#__PURE__*/React.createElement("p", {
    className: "lede"
  }, "These are not values printed on a coffee mug. They are the four things we genuinely disagree with the rest of our industry about.")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(2, 1fr)",
      border: "1px solid var(--rule)",
      background: "var(--rule)"
    }
  }, items.map(([n, h, p]) => /*#__PURE__*/React.createElement("div", {
    key: n,
    style: {
      background: "var(--cream)",
      padding: 36,
      display: "flex",
      flexDirection: "column",
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "mono",
    style: {
      fontSize: 11,
      letterSpacing: ".16em",
      color: "var(--accent)",
      marginBottom: 4
    }
  }, n), /*#__PURE__*/React.createElement("h4", {
    style: {
      fontWeight: 300,
      fontSize: 24,
      lineHeight: 1.2
    }
  }, h), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 14,
      color: "var(--muted)",
      lineHeight: 1.7
    }
  }, p))))));
}
function Timeline() {
  const rows = [["2024", "The pattern becomes obvious.", "After years working inside larger organisations, the same pattern keeps repeating: small- and mid-sized firms with real AI needs and no one sensible to call."], ["2025", "DarojaAI is founded.", "I leave my role and put out a shingle as a one-person practice. Three small fixed-price engagements in the first six months prove the shape of the work."], ["2025", "The first deployments.", "Workflows shipped into production across clients in manufacturing, logistics, and insurance. Every codebase handed over, all of them living in the client's own repository."], ["2026", "Field notes, in public.", "I start publishing what I'm learning — quarterly long-form, written by me, about the work I just did. No marketing department, no ghost-writer."]];
  return /*#__PURE__*/React.createElement("section", null, /*#__PURE__*/React.createElement("div", {
    className: "wrap"
  }, /*#__PURE__*/React.createElement("div", {
    className: "grid-2",
    style: {
      alignItems: "end",
      marginBottom: 48
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 24
    }
  }, "\u2014 The short version of our story"), /*#__PURE__*/React.createElement("h2", {
    style: {
      marginTop: 0
    }
  }, "How we got here.")), /*#__PURE__*/React.createElement("p", {
    className: "lede"
  }, "We have been building this practice deliberately, in the open, since the founders first met on a project at the start of 2023.")), /*#__PURE__*/React.createElement("div", null, rows.map(([y, h, p], i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      display: "grid",
      gridTemplateColumns: "200px 1fr",
      gap: "clamp(24px, 4vw, 64px)",
      padding: "36px 0",
      borderTop: "1px solid var(--rule)",
      borderBottom: i === rows.length - 1 ? "1px solid var(--rule)" : "none",
      alignItems: "baseline"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 200,
      fontSize: "clamp(28px, 3vw, 40px)",
      lineHeight: 1,
      color: "var(--accent)",
      fontVariantNumeric: "tabular-nums"
    }
  }, y), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h4", {
    style: {
      fontWeight: 300,
      fontSize: "clamp(18px, 1.8vw, 22px)",
      marginBottom: 8,
      lineHeight: 1.3
    }
  }, h), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 14,
      color: "var(--muted)",
      lineHeight: 1.7,
      maxWidth: "60ch"
    }
  }, p)))))));
}
function Team() {
  return /*#__PURE__*/React.createElement("section", {
    id: "team"
  }, /*#__PURE__*/React.createElement("div", {
    className: "wrap"
  }, /*#__PURE__*/React.createElement("div", {
    className: "grid-2",
    style: {
      alignItems: "end",
      marginBottom: 64
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 24
    }
  }, "\u2014 Who you'd be working with"), /*#__PURE__*/React.createElement("h2", {
    style: {
      marginTop: 0
    }
  }, "One operator.", /*#__PURE__*/React.createElement("br", null), "No middle layer.")), /*#__PURE__*/React.createElement("p", {
    className: "lede"
  }, "DarojaAI is a one-person practice. You work with me directly \u2014 from the first email to the last commit. The portrait below is a placeholder for photography I'm commissioning.")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "1fr 1.6fr",
      gap: "clamp(24px, 3vw, 40px)"
    }
  }, /*#__PURE__*/React.createElement(MediaSlot, {
    tall: true,
    label: "[ portrait \xB7 founder ]"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      alignSelf: "center"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      letterSpacing: ".12em",
      textTransform: "uppercase",
      opacity: .55,
      marginBottom: 6
    }
  }, "Founder & Sole Operator"), /*#__PURE__*/React.createElement("h4", {
    style: {
      fontSize: 28,
      fontWeight: 300,
      lineHeight: 1.2,
      marginBottom: 18
    }
  }, "[ Your name here ]"), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 15,
      color: "var(--muted)",
      lineHeight: 1.7,
      marginBottom: 18,
      maxWidth: "54ch"
    }
  }, "A capable, common-sense practitioner with relentless customer focus and a long track record of shipping AI inside organisations that needed it to actually work. I do strategy, architecture, and the build \u2014 myself."), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 15,
      color: "var(--muted)",
      lineHeight: 1.7,
      maxWidth: "54ch"
    }
  }, "When I take on an engagement, you get me \u2014 start to finish. No subcontractors, no junior staffed below me, no PMO."), /*#__PURE__*/React.createElement("div", {
    className: "mono",
    style: {
      marginTop: 18,
      display: "flex",
      gap: 14,
      fontSize: 11,
      opacity: .55,
      letterSpacing: ".04em"
    }
  }, /*#__PURE__*/React.createElement("span", null, "LinkedIn"), " \xB7 ", /*#__PURE__*/React.createElement("span", null, "hello@daroja.ai"))))));
}
Object.assign(window, {
  Values,
  Timeline,
  Team
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/About.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/Chrome.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
// Site chrome — SiteNav + Footer. Mirrors site.js from the source.

function SiteNav({
  page = "home"
}) {
  const links = [{
    id: "services",
    label: "Services",
    href: "#services"
  }, {
    id: "about",
    label: "About",
    href: "#about"
  }, {
    id: "contact",
    label: "Contact",
    href: "#contact"
  }];
  return /*#__PURE__*/React.createElement("nav", {
    className: "site-nav"
  }, /*#__PURE__*/React.createElement("a", {
    href: "#home",
    className: "brand"
  }, /*#__PURE__*/React.createElement("img", {
    src: "assets/logo-mark-transparent.png",
    alt: "DarojaAI mark"
  }), /*#__PURE__*/React.createElement("span", {
    className: "wm"
  }, "DarojaAI")), /*#__PURE__*/React.createElement("div", {
    className: "links"
  }, links.map(l => /*#__PURE__*/React.createElement("a", _extends({
    key: l.id,
    href: l.href
  }, page === l.id ? {
    "aria-current": "page"
  } : {}), l.label))), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    href: "#contact"
  }, "Book a call"));
}
function Footer() {
  return /*#__PURE__*/React.createElement("footer", {
    className: "site-footer"
  }, /*#__PURE__*/React.createElement("div", {
    className: "color-strip"
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      background: "#E6B340"
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      background: "#3299BB"
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      background: "#708238"
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      background: "#B34A35"
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      background: "#636C70"
    }
  })), /*#__PURE__*/React.createElement("div", {
    className: "content"
  }, /*#__PURE__*/React.createElement("div", {
    className: "col"
  }, /*#__PURE__*/React.createElement("div", {
    className: "brand-foot"
  }, /*#__PURE__*/React.createElement("img", {
    src: "assets/logo-mark-transparent.png",
    alt: ""
  }), /*#__PURE__*/React.createElement("span", null, "DarojaAI")), /*#__PURE__*/React.createElement("p", {
    className: "tag",
    style: {
      display: "block",
      textTransform: "none",
      letterSpacing: 0,
      opacity: .6
    }
  }, "AI strategy & architecture for organisations the consulting establishment overlooks.")), /*#__PURE__*/React.createElement("div", {
    className: "col"
  }, /*#__PURE__*/React.createElement("h4", null, "Practice"), /*#__PURE__*/React.createElement("a", {
    href: "#services"
  }, "Services"), /*#__PURE__*/React.createElement("a", {
    href: "#process"
  }, "How we work"), /*#__PURE__*/React.createElement("a", {
    href: "#cases"
  }, "Case studies"), /*#__PURE__*/React.createElement("a", {
    href: "#insights"
  }, "Insights")), /*#__PURE__*/React.createElement("div", {
    className: "col"
  }, /*#__PURE__*/React.createElement("h4", null, "Company"), /*#__PURE__*/React.createElement("a", {
    href: "#about"
  }, "About"), /*#__PURE__*/React.createElement("a", {
    href: "#team"
  }, "Team"), /*#__PURE__*/React.createElement("a", {
    href: "#contact"
  }, "Contact")), /*#__PURE__*/React.createElement("div", {
    className: "col"
  }, /*#__PURE__*/React.createElement("h4", null, "Newsletter"), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 13,
      opacity: .6,
      marginBottom: 14
    }
  }, "Quarterly field notes on practical AI for legacy systems."), /*#__PURE__*/React.createElement("form", {
    onSubmit: e => {
      e.preventDefault();
      e.currentTarget.querySelector("button").textContent = "Thanks ✓";
    }
  }, /*#__PURE__*/React.createElement("input", {
    type: "email",
    placeholder: "you@company.com",
    required: true,
    style: {
      background: "transparent",
      border: "none",
      borderBottom: "1px solid var(--rule-2)",
      padding: "8px 0",
      font: "inherit",
      fontSize: 13,
      color: "var(--ink)",
      outline: "none",
      width: "100%",
      marginBottom: 8
    }
  }), /*#__PURE__*/React.createElement("button", {
    className: "btn",
    style: {
      padding: "8px 14px",
      fontSize: 11
    }
  }, "Subscribe \u2192")))), /*#__PURE__*/React.createElement("div", {
    className: "meta"
  }, /*#__PURE__*/React.createElement("span", null, "\xA9 2026 DarojaAI \xB7 All rights reserved"), /*#__PURE__*/React.createElement("span", null, "Privacy \xB7 Terms \xB7 Cookies")));
}
Object.assign(window, {
  SiteNav,
  Footer
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/Chrome.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/Contact.jsx
try { (() => {
// Contact-page sections — ContactForm, AltContact, NewsletterBanner.

function ContactForm() {
  const [chips, setChips] = React.useState(new Set(["Ship a pilot"]));
  const [slot, setSlot] = React.useState("WED 15 MAY 09:30");
  const [done, setDone] = React.useState(false);
  const toggleChip = c => setChips(prev => {
    const next = new Set(prev);
    next.has(c) ? next.delete(c) : next.add(c);
    return next;
  });
  if (done) return /*#__PURE__*/React.createElement("div", {
    style: {
      border: "1px solid var(--accent)",
      padding: 32,
      background: "color-mix(in oklab, var(--cream) 80%, var(--accent) 6%)"
    }
  }, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 18
    }
  }, "\u2014 Request received"), /*#__PURE__*/React.createElement("h3", {
    style: {
      fontSize: 24,
      fontWeight: 300,
      marginBottom: 12
    }
  }, "Thank you. A partner will reply within one working day."), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 14,
      color: "var(--muted)"
    }
  }, "We will hold your preferred slot until we confirm."));
  const slots = ["TUE 14 MAY 10:00", "TUE 14 MAY 14:30", "WED 15 MAY 09:30", "WED 15 MAY 16:00", "FRI 17 MAY 11:00", "FRI 17 MAY 15:30"];
  const chipOptions = ["Set strategy", "Choose a vendor / stack", "Ship a pilot", "Audit a deployment", "Train our team", "Other"];
  return /*#__PURE__*/React.createElement("form", {
    className: "rise rise-1",
    onSubmit: e => {
      e.preventDefault();
      setDone(true);
    },
    style: {
      background: "color-mix(in oklab, var(--cream) 70%, white)",
      border: "1px solid var(--rule)",
      padding: "clamp(28px, 3vw, 44px)",
      display: "flex",
      flexDirection: "column",
      gap: 22
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h3", {
    style: {
      fontSize: 22,
      fontWeight: 300,
      lineHeight: 1.2,
      marginBottom: 8
    }
  }, "Discovery call"), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 13,
      color: "var(--muted)",
      marginBottom: 14
    }
  }, "Five fields. About two minutes of your time.")), /*#__PURE__*/React.createElement("div", {
    className: "grid-2",
    style: {
      gap: 20
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "field"
  }, /*#__PURE__*/React.createElement("label", null, "Your name"), /*#__PURE__*/React.createElement("input", {
    type: "text",
    required: true,
    placeholder: "Jane Patel"
  })), /*#__PURE__*/React.createElement("div", {
    className: "field"
  }, /*#__PURE__*/React.createElement("label", null, "Work email"), /*#__PURE__*/React.createElement("input", {
    type: "email",
    required: true,
    placeholder: "jane@company.com"
  }))), /*#__PURE__*/React.createElement("div", {
    className: "grid-2",
    style: {
      gap: 20
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "field"
  }, /*#__PURE__*/React.createElement("label", null, "Company"), /*#__PURE__*/React.createElement("input", {
    type: "text",
    required: true,
    placeholder: "Patel Industries Ltd"
  })), /*#__PURE__*/React.createElement("div", {
    className: "field"
  }, /*#__PURE__*/React.createElement("label", null, "Your role"), /*#__PURE__*/React.createElement("input", {
    type: "text",
    placeholder: "CIO / Head of Engineering"
  }))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "field",
    style: {
      marginBottom: 6
    }
  }, /*#__PURE__*/React.createElement("label", null, "What are you trying to do?")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexWrap: "wrap",
      gap: 8,
      marginTop: 8
    }
  }, chipOptions.map(c => {
    const active = chips.has(c);
    return /*#__PURE__*/React.createElement("span", {
      key: c,
      onClick: () => toggleChip(c),
      style: {
        padding: "8px 14px",
        border: "1px solid var(--rule-2)",
        fontSize: 12,
        cursor: "pointer",
        userSelect: "none",
        background: active ? "var(--ink)" : "transparent",
        color: active ? "var(--cream)" : "var(--ink)",
        borderColor: active ? "var(--ink)" : "var(--rule-2)"
      }
    }, c);
  }))), /*#__PURE__*/React.createElement("div", {
    className: "field"
  }, /*#__PURE__*/React.createElement("label", null, "A sentence or two of context"), /*#__PURE__*/React.createElement("textarea", {
    placeholder: "What is the situation, and what does success look like in six months?"
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "field",
    style: {
      marginBottom: 6
    }
  }, /*#__PURE__*/React.createElement("label", null, "Preferred slot (UK time)")), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8,
      display: "grid",
      gridTemplateColumns: "repeat(2, 1fr)",
      gap: 8
    }
  }, slots.map(s => {
    const [day, ...t] = s.split(" ");
    const time = s.slice(-5);
    const active = slot === s;
    return /*#__PURE__*/React.createElement("button", {
      type: "button",
      key: s,
      onClick: () => setSlot(s),
      style: {
        padding: "12px 14px",
        border: "1px solid var(--rule-2)",
        fontSize: 13,
        cursor: "pointer",
        textAlign: "left",
        display: "flex",
        justifyContent: "space-between",
        alignItems: "baseline",
        background: active ? "var(--ink)" : "transparent",
        color: active ? "var(--cream)" : "var(--ink)",
        borderColor: active ? "var(--ink)" : "var(--rule-2)",
        fontFamily: "var(--f-sans)"
      }
    }, /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("span", {
      className: "mono",
      style: {
        fontSize: 10,
        letterSpacing: ".12em",
        opacity: .65
      }
    }, s.slice(0, 10)), /*#__PURE__*/React.createElement("br", null), time), /*#__PURE__*/React.createElement("span", null, "30 min"));
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      alignItems: "center",
      marginTop: 12,
      paddingTop: 24,
      borderTop: "1px solid var(--rule)"
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "mono",
    style: {
      fontSize: 11,
      opacity: .55,
      letterSpacing: ".04em"
    }
  }, "We reply within 1 working day."), /*#__PURE__*/React.createElement("button", {
    type: "submit",
    className: "btn primary"
  }, "Send request ", /*#__PURE__*/React.createElement("span", {
    className: "arrow"
  }, "\u2192"))));
}
function AltContact() {
  const items = [["Email", "hello@daroja.ai", "For new engagements. Replied to by me, within one working day.", "mailto:hello@daroja.ai"], ["Press & speaking", "press@daroja.ai", "For interview requests, podcasts, and event bookings.", "mailto:press@daroja.ai"], ["Studio · Bristol", "3 Park Street\nBristol BS1 5NL", "By appointment only. The doorbell is on the right.", null], ["Office hours", "Mon–Thu · 09:00–18:00\nFri · 09:00–13:00", "UK time. We do not work weekends, on principle.", null]];
  return /*#__PURE__*/React.createElement("section", {
    className: "flush",
    style: {
      padding: 0,
      borderBottom: "1px solid var(--rule)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "clamp(56px, 7vw, 96px) var(--pad-x)",
      maxWidth: "var(--container)",
      marginInline: "auto"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "grid-2",
    style: {
      alignItems: "end",
      marginBottom: 48
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 24
    }
  }, "\u2014 Other ways to reach us"), /*#__PURE__*/React.createElement("h2", {
    style: {
      marginTop: 0
    }
  }, "Or, if a form is", /*#__PURE__*/React.createElement("br", null), "not your style.")), /*#__PURE__*/React.createElement("p", {
    className: "lede"
  }, "We answer email, LinkedIn, and the post. Pick the channel that suits \u2014 we will respond in kind, in person.")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(4, 1fr)",
      border: "1px solid var(--rule)",
      background: "var(--rule)"
    }
  }, items.map(([k, v, p, href]) => /*#__PURE__*/React.createElement("div", {
    key: k,
    style: {
      background: "var(--cream)",
      padding: 32,
      display: "flex",
      flexDirection: "column",
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      letterSpacing: ".14em",
      textTransform: "uppercase",
      opacity: .55
    }
  }, k), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 17,
      fontWeight: 300,
      whiteSpace: "pre-line"
    }
  }, href ? /*#__PURE__*/React.createElement("a", {
    className: "link",
    href: href
  }, v) : v), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 13,
      color: "var(--muted)"
    }
  }, p))))));
}
function NewsletterBanner() {
  return /*#__PURE__*/React.createElement("section", {
    className: "flush",
    style: {
      background: "var(--ink)",
      color: "var(--cream)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--container)",
      marginInline: "auto",
      padding: "clamp(64px, 8vw, 96px) var(--pad-x)",
      display: "grid",
      gridTemplateColumns: "1.2fr 1fr",
      gap: "clamp(32px, 5vw, 80px)",
      alignItems: "center"
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 20,
      color: "var(--accent)"
    }
  }, "\u2014 Field notes"), /*#__PURE__*/React.createElement("h2", {
    style: {
      color: "var(--cream)",
      fontSize: "clamp(28px, 3.5vw, 48px)",
      marginTop: 0
    }
  }, "One long essay,", /*#__PURE__*/React.createElement("br", null), "once a quarter. ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--accent)"
    }
  }, "Nothing else.")), /*#__PURE__*/React.createElement("p", {
    style: {
      color: "rgba(245,240,232,.65)",
      marginTop: 16,
      fontSize: 15
    }
  }, "No product launches, no roundups, no event invitations. Just the one piece of writing, sent by me \u2014 the person who wrote it.")), /*#__PURE__*/React.createElement("form", {
    onSubmit: e => {
      e.preventDefault();
      e.currentTarget.querySelector("button").textContent = "Subscribed ✓";
    },
    style: {
      display: "flex",
      border: "1px solid rgba(245,240,232,.22)"
    }
  }, /*#__PURE__*/React.createElement("input", {
    type: "email",
    placeholder: "you@company.com",
    required: true,
    style: {
      flex: 1,
      background: "transparent",
      border: "none",
      outline: "none",
      color: "var(--cream)",
      padding: "16px 18px",
      font: "inherit",
      fontSize: 14,
      fontFamily: "var(--f-sans)"
    }
  }), /*#__PURE__*/React.createElement("button", {
    style: {
      background: "var(--accent)",
      color: "var(--ink)",
      border: "none",
      padding: "0 24px",
      font: "inherit",
      fontSize: 13,
      letterSpacing: ".04em",
      cursor: "pointer",
      fontFamily: "var(--f-sans)",
      fontWeight: 400
    }
  }, "Subscribe \u2192"))));
}
Object.assign(window, {
  ContactForm,
  AltContact,
  NewsletterBanner
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/Contact.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/Home.jsx
try { (() => {
// Home-page hero with rotating mark.
function Hero() {
  return /*#__PURE__*/React.createElement("section", {
    className: "flush",
    style: {
      borderBottom: "1px solid var(--rule)",
      padding: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "hero",
    style: {
      padding: "clamp(56px, 8vw, 96px) var(--pad-x) clamp(72px, 9vw, 112px)",
      maxWidth: "var(--container)",
      marginInline: "auto"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "1.45fr .8fr",
      gap: "clamp(32px, 5vw, 80px)",
      alignItems: "end"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "rise"
  }, /*#__PURE__*/React.createElement(Eyebrow, null, "AI Strategy & Architecture"), /*#__PURE__*/React.createElement("h1", {
    style: {
      marginTop: 32
    }
  }, "Frontier AI", /*#__PURE__*/React.createElement("br", null), "for the firms", /*#__PURE__*/React.createElement("br", null), "the consultants", /*#__PURE__*/React.createElement("br", null), /*#__PURE__*/React.createElement("span", {
    style: {
      fontStyle: "italic",
      fontWeight: 300,
      color: "var(--accent)"
    }
  }, "forgot.")), /*#__PURE__*/React.createElement("p", {
    className: "lede",
    style: {
      marginTop: 36
    }
  }, "An independent practice \u2014 one capable person with relentless customer focus \u2014 helping small- and mid-sized legacy businesses adopt AI without the seven-figure deck or the eighteen-month engagement. Strategy, architecture, and the work."), /*#__PURE__*/React.createElement("div", {
    className: "row",
    style: {
      marginTop: 40,
      gap: 14
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    href: "#contact"
  }, "Book a discovery call"), /*#__PURE__*/React.createElement(Button, {
    href: "#services"
  }, "See how we work")), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 48,
      display: "flex",
      flexWrap: "wrap",
      gap: "32px 48px",
      alignItems: "baseline",
      borderTop: "1px solid var(--rule)",
      paddingTop: 32
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      letterSpacing: ".12em",
      textTransform: "uppercase",
      opacity: .5,
      marginBottom: 8
    }
  }, "Practice"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15
    }
  }, "Founder-led \xB7 Independent")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      letterSpacing: ".12em",
      textTransform: "uppercase",
      opacity: .5,
      marginBottom: 8
    }
  }, "Engagements from"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "mono"
  }, "2 weeks"), " \xB7 fixed scope")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      letterSpacing: ".12em",
      textTransform: "uppercase",
      opacity: .5,
      marginBottom: 8
    }
  }, "Sectors"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15
    }
  }, "Manufacturing, logistics, finance, public sector")))), /*#__PURE__*/React.createElement("div", {
    className: "rise rise-2",
    style: {
      position: "relative",
      aspectRatio: 1,
      display: "flex",
      alignItems: "center",
      justifyContent: "center"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: "4%",
      border: "1px dashed var(--rule-2)",
      borderRadius: "50%",
      animation: "spin 90s linear infinite reverse"
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: "assets/logo-mark-transparent.png",
    alt: "",
    style: {
      width: "92%",
      aspectRatio: 1,
      objectFit: "contain",
      position: "relative",
      zIndex: 2
    }
  })))), /*#__PURE__*/React.createElement("style", null, `@keyframes spin { to { transform: rotate(360deg); } }`));
}
function Marquee() {
  const items = ["Manufacturing", "Logistics", "Insurance", "Retail", "Public Sector", "Energy", "Healthcare", "Construction", "Financial Services"];
  const strip = [...items, ...items];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: "1px solid var(--rule)",
      borderBottom: "1px solid var(--rule)",
      padding: "24px 0",
      overflow: "hidden",
      position: "relative"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 64,
      animation: "marqueeScroll 38s linear infinite",
      width: "max-content"
    }
  }, strip.map((t, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      fontWeight: 300,
      fontSize: 22,
      letterSpacing: "-.01em",
      opacity: .42,
      whiteSpace: "nowrap",
      display: "flex",
      alignItems: "center",
      gap: 14
    }
  }, t, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 4,
      height: 4,
      borderRadius: "50%",
      background: "var(--accent)",
      opacity: .5
    }
  })))), /*#__PURE__*/React.createElement("span", {
    style: {
      position: "absolute",
      top: 0,
      bottom: 0,
      left: 0,
      width: 80,
      pointerEvents: "none",
      background: "linear-gradient(90deg, var(--cream), transparent)"
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      position: "absolute",
      top: 0,
      bottom: 0,
      right: 0,
      width: 80,
      pointerEvents: "none",
      background: "linear-gradient(-90deg, var(--cream), transparent)"
    }
  }), /*#__PURE__*/React.createElement("style", null, `@keyframes marqueeScroll { from { transform: translateX(0); } to { transform: translateX(-50%); } }`));
}
function OfferingGrid() {
  const items = [{
    color: "gold",
    num: "01 / Strategy",
    h: "AI Strategy & Roadmapping",
    p: "A defensible 12-month plan for where AI moves the needle in your business — and where it doesn't."
  }, {
    color: "azure",
    num: "02 / Architecture",
    h: "Reference Architecture",
    p: "Stack selection, data flow, model placement, and the security perimeter — drawn for your engineers."
  }, {
    color: "green",
    num: "03 / Build",
    h: "Integration & Pilots",
    p: "We pair with your team to ship the first three workflows into production — not into a demo."
  }, {
    color: "red",
    num: "04 / Enable",
    h: "Team Enablement",
    p: "Workshops, playbooks, and a 90-day operating cadence so the practice survives our departure."
  }];
  const colorBar = {
    gold: "var(--gold)",
    azure: "var(--azure)",
    green: "var(--green)",
    red: "var(--red)"
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(2, 1fr)",
      gap: 0,
      border: "1px solid var(--rule)",
      background: "var(--rule)"
    }
  }, items.map(it => /*#__PURE__*/React.createElement("a", {
    key: it.num,
    href: "#services",
    style: {
      background: "var(--cream)",
      padding: 40,
      display: "flex",
      flexDirection: "column",
      gap: 18,
      position: "relative",
      textDecoration: "none",
      color: "inherit"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      position: "absolute",
      top: 0,
      left: 0,
      width: "100%",
      height: 3,
      background: colorBar[it.color]
    }
  }), /*#__PURE__*/React.createElement("span", {
    className: "mono",
    style: {
      fontSize: 12,
      letterSpacing: ".14em",
      opacity: .42
    }
  }, it.num), /*#__PURE__*/React.createElement("h3", {
    style: {
      fontWeight: 300,
      fontSize: 26,
      lineHeight: 1.15
    }
  }, it.h), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 14,
      color: "var(--muted)"
    }
  }, it.p), /*#__PURE__*/React.createElement("span", {
    style: {
      marginTop: "auto",
      paddingTop: 20,
      fontSize: 13,
      display: "flex",
      alignItems: "center",
      gap: 8
    }
  }, "Read more \u2192"))));
}
function Manifesto() {
  return /*#__PURE__*/React.createElement("section", {
    className: "flush",
    style: {
      background: "var(--ink)",
      color: "var(--cream)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--container)",
      marginInline: "auto",
      padding: "clamp(72px, 9vw, 120px) var(--pad-x)"
    }
  }, /*#__PURE__*/React.createElement(Eyebrow, {
    plain: true,
    style: {
      color: "var(--gold)",
      marginBottom: 32
    }
  }, "\u2014 Why we exist"), /*#__PURE__*/React.createElement("h2", {
    style: {
      color: "var(--cream)",
      maxWidth: "18ch"
    }
  }, "The largest firms get", /*#__PURE__*/React.createElement("br", null), "twelve consultants.", /*#__PURE__*/React.createElement("br", null), /*#__PURE__*/React.createElement("span", {
    style: {
      borderBottom: "2px solid var(--gold)",
      paddingBottom: 2
    }
  }, "Everyone else gets a deck.")), /*#__PURE__*/React.createElement("p", {
    className: "lede",
    style: {
      color: "rgba(245,240,232,.65)",
      marginTop: 32,
      maxWidth: "56ch"
    }
  }, "We started DarojaAI because the businesses that quietly run the economy \u2014 manufacturers, logistics operators, regional insurers, municipal utilities \u2014 couldn't get serious AI help without a tier-one budget. We deliver the same rigour at a fraction of the surface area."), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 64,
      display: "grid",
      gridTemplateColumns: "repeat(3, 1fr)",
      gap: 32
    }
  }, [["01", "You get the operator", "Every engagement is led — and delivered — by the same person who quoted it. No pyramid, no juniors, no hand-off."], ["02", "Fixed scope, fixed price", "We scope tightly, write it down, and price it before we start. You will not be billed for our learning curve."], ["03", "Code on the way out", "Every engagement ends with working code, owned by you, and a team who can extend it. No vendor lock-in."]].map(([n, h, p]) => /*#__PURE__*/React.createElement("div", {
    key: n,
    style: {
      borderTop: "1px solid rgba(245,240,232,.18)",
      paddingTop: 20
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "mono",
    style: {
      fontSize: 11,
      letterSpacing: ".16em",
      color: "var(--accent)",
      marginBottom: 16
    }
  }, n), /*#__PURE__*/React.createElement("h4", {
    style: {
      fontWeight: 300,
      fontSize: 20,
      marginBottom: 12
    }
  }, h), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 14,
      color: "rgba(245,240,232,.6)",
      lineHeight: 1.7
    }
  }, p))))));
}
function StatsRow() {
  const stats = [["14", "", "Production deployments"], ["$1.4", "M", "Annualised value, last engagement"], ["6", "", "Average weeks to first pilot"], ["100", "%", "Client-retained codebases"]];
  return /*#__PURE__*/React.createElement("section", {
    className: "tight"
  }, /*#__PURE__*/React.createElement("div", {
    className: "wrap"
  }, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 48
    }
  }, "By the numbers"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(4, 1fr)"
    }
  }, stats.map(([n, sup, l], i) => /*#__PURE__*/React.createElement("div", {
    className: "stat",
    key: l,
    style: {
      padding: "32px 0 32px 24px",
      borderLeft: i === 0 ? "none" : "1px solid var(--rule)",
      paddingLeft: i === 0 ? 0 : 24
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "n"
  }, n, sup && /*#__PURE__*/React.createElement("sup", null, sup)), /*#__PURE__*/React.createElement("div", {
    className: "l"
  }, l))))));
}
function CaseGrid() {
  const cases = [{
    sector: "Manufacturing · Midlands, UK",
    h: "Predictive maintenance across 280 CNC machines.",
    p: "A bespoke anomaly-detection layer over twelve years of legacy SCADA data. £420k/yr in avoided downtime.",
    meta: "10 weeks · Strategy → Pilot",
    slot: "[ photograph · plant floor ]"
  }, {
    sector: "Logistics · Benelux",
    h: "An LLM-routed dispatch assistant for 40 depot managers.",
    p: "From a paper SOP binder to a query-able operations agent in seven weeks. Hand-off, not hand-cuff.",
    meta: "7 weeks · Architecture → Build",
    slot: "[ photograph · warehouse ]"
  }, {
    sector: "Insurance · Regional carrier",
    h: "Cutting first-notice-of-loss handling time by 62%.",
    p: "A small, audited classifier and a careful workflow rewrite. The regulator approved on first review.",
    meta: "12 weeks · Full engagement",
    slot: "[ photograph · claims office ]"
  }];
  return /*#__PURE__*/React.createElement("section", null, /*#__PURE__*/React.createElement("div", {
    className: "wrap"
  }, /*#__PURE__*/React.createElement("div", {
    className: "row",
    style: {
      justifyContent: "space-between",
      marginBottom: 48,
      alignItems: "flex-end"
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 20
    }
  }, "Selected work"), /*#__PURE__*/React.createElement("h2", {
    style: {
      marginTop: 0
    }
  }, "Recent engagements.")), /*#__PURE__*/React.createElement("a", {
    href: "#cases",
    className: "link mono",
    style: {
      fontSize: 13
    }
  }, "All case studies \u2192")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(3, 1fr)",
      gap: 32
    }
  }, cases.map(c => /*#__PURE__*/React.createElement("a", {
    key: c.h,
    href: "#",
    style: {
      textDecoration: "none",
      color: "inherit",
      display: "block"
    }
  }, /*#__PURE__*/React.createElement(MediaSlot, {
    wide: true,
    label: c.slot,
    style: {
      marginBottom: 20
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      letterSpacing: ".12em",
      textTransform: "uppercase",
      opacity: .55,
      marginBottom: 10
    }
  }, c.sector), /*#__PURE__*/React.createElement("h4", {
    style: {
      fontWeight: 300,
      fontSize: 22,
      lineHeight: 1.25,
      marginBottom: 12,
      textWrap: "balance"
    }
  }, c.h), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 13,
      color: "var(--muted)",
      marginBottom: 12
    }
  }, c.p), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 16,
      fontSize: 11,
      opacity: .5,
      letterSpacing: ".04em"
    },
    className: "mono"
  }, c.meta))))));
}
function InsightList() {
  const items = [{
    date: "04 / 2026",
    h: "Why your first AI project should not be a chatbot.",
    read: "6 min read →"
  }, {
    date: "03 / 2026",
    h: "The reference architecture every legacy manufacturer needs in 2026.",
    read: "11 min read →"
  }, {
    date: "02 / 2026",
    h: "Build vs. buy: the calculation has changed twice already this year.",
    read: "8 min read →"
  }, {
    date: "01 / 2026",
    h: "What McKinsey gets right — and what they can't ship.",
    read: "9 min read →"
  }];
  return /*#__PURE__*/React.createElement("section", {
    id: "insights"
  }, /*#__PURE__*/React.createElement("div", {
    className: "wrap"
  }, /*#__PURE__*/React.createElement("div", {
    className: "row",
    style: {
      justifyContent: "space-between",
      marginBottom: 32,
      alignItems: "flex-end"
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 20
    }
  }, "Field notes"), /*#__PURE__*/React.createElement("h2", {
    style: {
      marginTop: 0
    }
  }, "Recent writing.")), /*#__PURE__*/React.createElement("a", {
    href: "#",
    className: "link mono",
    style: {
      fontSize: 13
    }
  }, "Archive \u2192")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexDirection: "column"
    }
  }, items.map((it, i) => /*#__PURE__*/React.createElement("a", {
    key: it.date,
    href: "#",
    style: {
      display: "grid",
      gridTemplateColumns: "90px 1fr auto",
      gap: 32,
      padding: "24px 0",
      borderTop: "1px solid var(--rule)",
      borderBottom: i === items.length - 1 ? "1px solid var(--rule)" : "none",
      textDecoration: "none",
      color: "inherit",
      alignItems: "baseline"
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "mono",
    style: {
      fontSize: 11,
      letterSpacing: ".08em",
      opacity: .55
    }
  }, it.date), /*#__PURE__*/React.createElement("h4", {
    style: {
      fontWeight: 300,
      fontSize: "clamp(18px, 1.6vw, 22px)",
      lineHeight: 1.25,
      textWrap: "balance"
    }
  }, it.h), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      opacity: .5,
      whiteSpace: "nowrap"
    }
  }, it.read))))));
}
function BigCTA() {
  return /*#__PURE__*/React.createElement("section", {
    className: "flush"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "clamp(72px, 10vw, 140px) var(--pad-x)",
      maxWidth: "var(--container)",
      marginInline: "auto"
    }
  }, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 40
    }
  }, "\u2014 Start here"), /*#__PURE__*/React.createElement("h2", {
    style: {
      fontSize: "clamp(48px, 8vw, 128px)",
      fontWeight: 200,
      letterSpacing: "-.025em",
      lineHeight: .95,
      marginBottom: 32,
      textWrap: "balance"
    }
  }, "Tell us what you", /*#__PURE__*/React.createElement("br", null), "need to ship.", /*#__PURE__*/React.createElement("br", null), /*#__PURE__*/React.createElement("span", {
    style: {
      fontStyle: "italic",
      color: "var(--accent)"
    }
  }, "We'll tell you how.")), /*#__PURE__*/React.createElement("p", {
    className: "lede",
    style: {
      marginBottom: 8
    }
  }, "A 30-minute discovery call. No deck, no pitch \u2014 just a working conversation about whether we are the right team for what you have to do."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 16,
      flexWrap: "wrap",
      marginTop: 24
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    href: "#contact"
  }, "Book a discovery call"), /*#__PURE__*/React.createElement(Button, {
    href: "mailto:hello@daroja.ai",
    withArrow: false
  }, "hello@daroja.ai"))));
}
Object.assign(window, {
  Hero,
  Marquee,
  OfferingGrid,
  Manifesto,
  StatsRow,
  CaseGrid,
  InsightList,
  BigCTA
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/Home.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/Services.jsx
try { (() => {
// Services page sections — ServiceRow, Process, PackageGrid, FAQ.

function ServiceRow({
  color,
  num,
  tag,
  title,
  paragraphs,
  deliverables,
  duration,
  investment,
  id
}) {
  return /*#__PURE__*/React.createElement("div", {
    id: id,
    className: "service " + color,
    style: {
      borderTop: "1px solid var(--rule)",
      paddingBlock: "clamp(48px, 6vw, 88px)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "200px 1fr 1fr",
      gap: "clamp(24px, 4vw, 64px)",
      alignItems: "start"
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "mono",
    style: {
      fontSize: 13,
      letterSpacing: ".14em",
      color: "var(--muted)",
      marginBottom: 12
    }
  }, num), /*#__PURE__*/React.createElement(Tag, {
    color: color
  }, tag)), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h2", {
    style: {
      fontSize: "clamp(28px, 3vw, 44px)",
      fontWeight: 200,
      marginBottom: 20
    }
  }, title), paragraphs.map((p, i) => /*#__PURE__*/React.createElement("p", {
    key: i,
    style: {
      fontSize: 16,
      lineHeight: 1.7,
      color: i === paragraphs.length - 1 ? "var(--ink)" : "var(--muted)",
      marginBottom: 14
    }
  }, p))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: "1px solid var(--rule)",
      paddingTop: 20
    }
  }, /*#__PURE__*/React.createElement("h4", {
    style: {
      fontSize: 11,
      letterSpacing: ".14em",
      textTransform: "uppercase",
      opacity: .55,
      fontWeight: 500,
      marginBottom: 16
    }
  }, "You leave with"), /*#__PURE__*/React.createElement("ul", {
    style: {
      listStyle: "none"
    }
  }, deliverables.map((d, i) => /*#__PURE__*/React.createElement("li", {
    key: i,
    style: {
      display: "grid",
      gridTemplateColumns: "22px 1fr",
      padding: "10px 0",
      borderBottom: i === deliverables.length - 1 ? "none" : "1px solid var(--rule)",
      fontSize: 14,
      alignItems: "baseline"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--accent)",
      fontSize: 11
    }
  }, "\u2713"), /*#__PURE__*/React.createElement("span", null, d))))), /*#__PURE__*/React.createElement("div", {
    style: {
      background: "var(--cream-2)",
      padding: 24,
      marginTop: 24,
      display: "grid",
      gridTemplateColumns: "1fr 1fr",
      gap: 16
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      letterSpacing: ".14em",
      textTransform: "uppercase",
      opacity: .55,
      marginBottom: 6
    }
  }, "Duration"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 300,
      fontSize: 17
    }
  }, duration)), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      letterSpacing: ".14em",
      textTransform: "uppercase",
      opacity: .55,
      marginBottom: 6
    }
  }, "Investment"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 300,
      fontSize: 17
    }
  }, investment))))));
}
function Process() {
  const phases = [["Week 0", "Discovery call", "30 minutes. We listen. If we are not the right team, we will say so and point you at someone who is."], ["Week 1–2", "Diagnostic sprint", "A two-week fixed-price diagnostic. Output: a written assessment and a shaped proposal. Walk away free."], ["Week 3–10", "Core engagement", "The work itself, against a written scope. Weekly demo, fortnightly steering, no surprises in the invoice."], ["Week 11+", "Hand-off & check-in", "Code, docs, and people. A 6-month check-in to make sure the practice survived our departure."]];
  return /*#__PURE__*/React.createElement("section", {
    className: "flush",
    style: {
      background: "var(--ink)",
      color: "var(--cream)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--container)",
      marginInline: "auto",
      padding: "clamp(80px, 10vw, 120px) var(--pad-x)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "1fr 1fr",
      gap: "clamp(24px, 4vw, 64px)",
      alignItems: "end"
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 24,
      color: "var(--accent)"
    }
  }, "\u2014 How we work"), /*#__PURE__*/React.createElement("h2", {
    style: {
      color: "var(--cream)",
      marginTop: 0
    }
  }, "Four weeks in,", /*#__PURE__*/React.createElement("br", null), "or your money back.")), /*#__PURE__*/React.createElement("p", {
    className: "lede",
    style: {
      color: "rgba(245,240,232,.65)"
    }
  }, "Every engagement follows the same shape. We start small, prove the shape of the work, and only then commit to anything longer.")), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 64,
      display: "grid",
      gridTemplateColumns: "repeat(4, 1fr)",
      borderTop: "1px solid rgba(245,240,232,.18)"
    }
  }, phases.map(([w, h, p], i) => /*#__PURE__*/React.createElement("div", {
    key: w,
    style: {
      padding: "28px 24px 28px 0",
      borderRight: i === phases.length - 1 ? "none" : "1px solid rgba(245,240,232,.12)",
      position: "relative"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      position: "absolute",
      top: -5,
      left: 0,
      width: 9,
      height: 9,
      background: "var(--accent)",
      borderRadius: "50%"
    }
  }), /*#__PURE__*/React.createElement("div", {
    className: "mono",
    style: {
      fontSize: 11,
      letterSpacing: ".14em",
      color: "var(--accent)",
      marginBottom: 14
    }
  }, w), /*#__PURE__*/React.createElement("h4", {
    style: {
      fontWeight: 300,
      fontSize: 22,
      marginBottom: 12
    }
  }, h), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 13,
      color: "rgba(245,240,232,.6)",
      lineHeight: 1.7
    }
  }, p))))));
}
function PackageGrid() {
  const pkgs = [{
    name: "— Diagnostic",
    title: "Two weeks, one clear plan.",
    price: "£12k",
    dur: "10 working days · fixed",
    bullets: ["Stakeholder interviews (6–10)", "Data & system audit", "Shortlist of 5 viable AI opportunities", "Written diagnostic memo (~20 pages)", "Read-out to leadership"],
    cta: "Begin here"
  }, {
    name: "— Practice Setup",
    title: "Twelve weeks to first ship.",
    price: "£85k",
    dur: "~12 weeks · fixed scope",
    feat: true,
    bullets: ["Strategy & roadmap", "Reference architecture", "Two production workflows shipped", "Codebase, tests, observability", "Team workshops & playbooks", "6-month advisory check-in"],
    cta: "Most chosen"
  }, {
    name: "— Embedded Partner",
    title: "Quarterly retainer for ongoing work.",
    price: "£24k/mo",
    dur: "90-day terms · renewable",
    bullets: ["One senior partner, 2 days/week", "Quarterly roadmap reviews", "Architecture & build support", "Capability mentoring for your team", "Pause or end at any quarter boundary"],
    cta: "Talk to us"
  }];
  return /*#__PURE__*/React.createElement("section", null, /*#__PURE__*/React.createElement("div", {
    className: "wrap"
  }, /*#__PURE__*/React.createElement("div", {
    className: "grid-2",
    style: {
      alignItems: "end",
      marginBottom: 64
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 24
    }
  }, "Engagement shapes"), /*#__PURE__*/React.createElement("h2", {
    style: {
      marginTop: 0
    }
  }, "Three ways", /*#__PURE__*/React.createElement("br", null), "to begin.")), /*#__PURE__*/React.createElement("p", {
    className: "lede"
  }, "Fixed scope, fixed price, written down before the first kick-off. Most clients begin with the middle option and add modules as they need them.")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(3, 1fr)",
      border: "1px solid var(--rule)"
    }
  }, pkgs.map((p, i) => /*#__PURE__*/React.createElement("div", {
    key: p.name,
    style: {
      padding: "36px 32px",
      borderRight: i === pkgs.length - 1 ? "none" : "1px solid var(--rule)",
      background: p.feat ? "var(--ink)" : "color-mix(in oklab, var(--cream) 75%, white)",
      color: p.feat ? "var(--cream)" : "inherit",
      display: "flex",
      flexDirection: "column",
      position: "relative"
    }
  }, p.feat && /*#__PURE__*/React.createElement("span", {
    className: "mono",
    style: {
      position: "absolute",
      top: 16,
      right: 16,
      fontSize: 10,
      letterSpacing: ".14em",
      color: "var(--accent)"
    }
  }, "MOST CHOSEN"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      letterSpacing: ".16em",
      textTransform: "uppercase",
      marginBottom: 28,
      opacity: .55,
      color: p.feat ? "rgba(245,240,232,.6)" : undefined
    }
  }, p.name), /*#__PURE__*/React.createElement("h3", {
    style: {
      fontWeight: 200,
      fontSize: "clamp(28px, 3vw, 36px)",
      lineHeight: 1.1,
      marginBottom: 20,
      color: "inherit"
    }
  }, p.title), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 200,
      fontSize: 32,
      lineHeight: 1,
      marginBottom: 8,
      fontVariantNumeric: "tabular-nums"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      opacity: .55,
      marginRight: 4,
      letterSpacing: ".1em",
      textTransform: "uppercase"
    }
  }, "from "), p.price), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      letterSpacing: ".1em",
      textTransform: "uppercase",
      opacity: .55,
      marginBottom: 28
    }
  }, p.dur), /*#__PURE__*/React.createElement("ul", {
    style: {
      listStyle: "none",
      flex: 1,
      marginBottom: 28
    }
  }, p.bullets.map((b, j) => /*#__PURE__*/React.createElement("li", {
    key: j,
    style: {
      padding: "12px 0",
      borderTop: j === 0 ? "none" : `1px solid ${p.feat ? "rgba(245,240,232,.12)" : "var(--rule)"}`,
      fontSize: 14,
      lineHeight: 1.5
    }
  }, b))), /*#__PURE__*/React.createElement("a", {
    href: "#contact",
    className: "btn" + (p.feat ? " accent" : ""),
    style: {
      width: "100%",
      justifyContent: "center"
    }
  }, p.cta, " \u2192"))))));
}
function FAQ() {
  const qs = [["How are you different from a Big Four AI practice?", "I am one operator who has shipped production AI inside large organisations — no pyramid, no junior staffed below me, no methodology binder. You get the person who does the work, who is the same person who quoted it."], ["What size of business is the right fit?", "We do our best work with organisations between £20m and £500m in turnover, with at least one product, operations, or claims process that still moves data on paper or in spreadsheets."], ["Do you take equity or revenue-share?", "No. We are a cash-billing practice. We are happy to take a small portion of fees deferred against measured outcomes, but we will not become a shareholder in your business."], ["What if my data is in dreadful shape?", "It usually is. We will say so, scope a minimum-viable data layer to unblock the first workflow, and resist the temptation to launch a 24-month data warehouse project before any AI ships."], ["Do you sign NDAs before discovery calls?", "Yes, gladly. Send us your standard form and we will counter-sign within a working day."]];
  return /*#__PURE__*/React.createElement("section", null, /*#__PURE__*/React.createElement("div", {
    className: "wrap"
  }, /*#__PURE__*/React.createElement("div", {
    className: "grid-2",
    style: {
      alignItems: "start",
      gap: 64
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Eyebrow, {
    style: {
      marginBottom: 24
    }
  }, "Common questions"), /*#__PURE__*/React.createElement("h2", {
    style: {
      marginTop: 0
    }
  }, "Things people", /*#__PURE__*/React.createElement("br", null), "ask us first."), /*#__PURE__*/React.createElement("p", {
    className: "lede",
    style: {
      marginTop: 24
    }
  }, "Don't see your question? Send it to", " ", /*#__PURE__*/React.createElement("a", {
    href: "mailto:hello@daroja.ai",
    className: "link mono",
    style: {
      fontSize: "inherit"
    }
  }, "hello@daroja.ai"), " ", "and we will reply in person, not from a form.")), /*#__PURE__*/React.createElement("div", null, qs.map(([q, a], i) => /*#__PURE__*/React.createElement("details", {
    key: i,
    open: i === 0,
    style: {
      borderTop: "1px solid var(--rule)",
      padding: "24px 0",
      borderBottom: i === qs.length - 1 ? "1px solid var(--rule)" : undefined
    }
  }, /*#__PURE__*/React.createElement("summary", {
    style: {
      cursor: "pointer",
      listStyle: "none",
      display: "flex",
      justifyContent: "space-between",
      alignItems: "baseline",
      gap: 24,
      fontSize: "clamp(17px, 1.6vw, 22px)",
      fontWeight: 300
    }
  }, q, /*#__PURE__*/React.createElement("span", {
    className: "mono",
    style: {
      fontSize: 22,
      opacity: .55
    }
  }, "+")), /*#__PURE__*/React.createElement("p", {
    style: {
      marginTop: 16,
      color: "var(--muted)",
      fontSize: 15,
      lineHeight: 1.7,
      maxWidth: "64ch"
    }
  }, a)))))));
}
Object.assign(window, {
  ServiceRow,
  Process,
  PackageGrid,
  FAQ
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/Services.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/atoms.jsx
try { (() => {
// Atoms — Button, Eyebrow, Tag, MediaSlot. Exposed as globals.
// Load AFTER React/ReactDOM/Babel.

function Eyebrow({
  children,
  plain,
  style,
  color
}) {
  const cls = plain ? "eyebrow plain" : "eyebrow";
  const s = color ? {
    ...style,
    color
  } : style;
  return /*#__PURE__*/React.createElement("span", {
    className: cls,
    style: s
  }, children);
}
function Button({
  children,
  variant = "default",
  href,
  onClick,
  style,
  withArrow = true
}) {
  const cls = "btn" + (variant === "primary" ? " primary" : variant === "accent" ? " accent" : "");
  const inner = /*#__PURE__*/React.createElement(React.Fragment, null, children, withArrow && /*#__PURE__*/React.createElement("span", {
    className: "arrow"
  }, "\u2192"));
  if (href) return /*#__PURE__*/React.createElement("a", {
    className: cls,
    href: href,
    style: style
  }, inner);
  return /*#__PURE__*/React.createElement("button", {
    className: cls,
    onClick: onClick,
    style: style
  }, inner);
}
function Tag({
  color = "gold",
  children
}) {
  return /*#__PURE__*/React.createElement("span", {
    className: "tag " + color
  }, children);
}
function MediaSlot({
  wide,
  tall,
  label,
  style
}) {
  const cls = "media-slot" + (wide ? " wide" : "") + (tall ? " tall" : "");
  return /*#__PURE__*/React.createElement("div", {
    className: cls,
    style: style
  }, /*#__PURE__*/React.createElement("span", null, label || "[ photo placeholder ]"));
}
Object.assign(window, {
  Eyebrow,
  Button,
  Tag,
  MediaSlot
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/atoms.jsx", error: String((e && e.message) || e) }); }

})();
