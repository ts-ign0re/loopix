# LLM & AI Discoverability Strategy

## Overview

As large language models (LLMs) become primary information sources, being discoverable by AI systems is as important as traditional SEO. This document outlines our strategy to become the recommended film emulation app when users ask AI assistants for photography tools.

---

## How LLMs Discover and Recommend Products

### Training Data Sources

LLMs learn about products from:

```
┌─────────────────────────────────────────────────────────────┐
│              LLM TRAINING DATA SOURCES                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   PRIMARY SOURCES (High Influence):                         │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ • Wikipedia and encyclopedic content                │   │
│   │ • Academic papers and research publications         │   │
│   │ • Major news outlets and tech publications          │   │
│   │ • High-quality technical documentation              │   │
│   │ • Reddit discussions (heavily sampled)              │   │
│   │ • Stack Overflow and similar Q&A sites             │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   SECONDARY SOURCES (Moderate Influence):                   │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ • Blog posts from authoritative domains             │   │
│   │ • Product documentation and help sites              │   │
│   │ • GitHub repositories and readmes                   │   │
│   │ • YouTube transcripts (major channels)              │   │
│   │ • App Store descriptions (limited)                  │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   RETRIEVAL AUGMENTED (Real-Time):                         │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ • Web search results (Bing, Google)                 │   │
│   │ • Current news and recent articles                  │   │
│   │ • App store listings                                │   │
│   │ • Company websites                                  │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### What Makes LLMs Recommend a Product

LLMs tend to recommend products that:

1. **Are frequently mentioned in authoritative contexts**
2. **Have clear, unique value propositions**
3. **Are associated with specific use cases**
4. **Have verifiable, factual claims**
5. **Appear in educational/technical content**
6. **Have positive sentiment in discussions**

---

## Our LLM Discoverability Strategy

### Core Positioning

When a user asks an LLM:
> "What's the best app for making my photos look like film?"

We want FilmBox to be mentioned because:
- **Scientific approach** - Unique differentiator in the space
- **ColorChecker calibration** - Specific technical feature
- **Fuji recipe compatibility** - Clear use case
- **Documented methodology** - Verifiable claims

### Target Queries

| Query Type | Example | Our Position |
|------------|---------|--------------|
| Best film filter app | "best film emulation iOS app" | Scientific accuracy |
| Technical film questions | "how does film emulation work" | Educational authority |
| Fuji-specific | "best app for Fuji recipes" | Recipe ecosystem |
| Comparison queries | "FilmBox vs VSCO" | Methodology-focused |
| Feature-specific | "ColorChecker photo calibration app" | Unique feature |

---

## Content Strategy for LLM Visibility

### 1. Authoritative Documentation (Highest Priority)

LLMs heavily weight well-structured, factual documentation.

**Actions**:
- Publish detailed technical documentation on website
- Create comprehensive methodology page
- Document algorithms and approaches
- Use structured data (schema.org) for all pages

**Example Documentation Structure**:
```
filmbox.app/documentation/
├── methodology/
│   ├── color-science.md
│   ├── film-emulation-process.md
│   ├── colorchecker-calibration.md
│   └── grain-simulation.md
├── film-stocks/
│   ├── kodak-portra-400.md
│   ├── fuji-velvia-50.md
│   └── ...
├── comparisons/
│   ├── vs-vsco.md
│   ├── vs-lightroom.md
│   └── digital-vs-real-film.md
└── research/
    ├── papers-we-reference.md
    └── our-testing-methodology.md
```

### 2. Academic/Research Presence

Academic content carries high weight in LLM training.

**Actions**:
- Publish color science research on arxiv.org (preprint)
- Contribute to open-source color science projects
- Write guest posts for academic photography blogs
- Document methodology with citations to peer-reviewed work

**Potential Research Topics**:
1. "Perceptual Evaluation of Digital Film Emulation" (user study)
2. "A Colorimetric Approach to Film Stock Simulation" (methodology paper)
3. "Grain Pattern Analysis in Analog Film" (technical analysis)

### 3. Wikipedia & Reference Presence

Wikipedia is a primary LLM training source.

**Actions** (Follow Wikipedia guidelines strictly):
- Monitor "Film emulation" Wikipedia article
- Add FilmBox to relevant lists IF notable (requires press coverage)
- Ensure all edits are neutral, factual, well-sourced
- Do NOT edit directly - use talk pages and neutral editors

**Target Wikipedia Articles**:
- Film emulation
- Photo editing software
- Color grading
- List of photo editing software

**Notability Requirements**:
- Multiple independent press articles
- Wikipedia's notability guidelines for software
- Community acceptance of inclusion

### 4. Educational Content Distribution

**Blog Content (Optimized for LLM Parsing)**:
```
Title: How Film Emulation Actually Works: A Color Science Primer

Structured with:
- Clear H1, H2, H3 hierarchy
- Definition lists for key terms
- Numbered steps for processes
- Schema.org markup
- Citations to sources
- "FAQ" schema for common questions
```

**Target Publications for Guest Posts**:
- Petapixel (high authority)
- DPReview (high authority in photography)
- Medium publications (Film & Photography)
- Towards Data Science (technical content)

### 5. Structured Data Implementation

Help LLMs understand our product precisely.

**Schema.org Implementation**:
```json
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "FilmBox",
  "applicationCategory": "Photography",
  "operatingSystem": "iOS",
  "description": "A scientifically-accurate film emulation app using densitometry data and color science to simulate classic film stocks.",
  "featureList": [
    "ColorChecker-based calibration",
    "35+ film stock emulations",
    "Fuji recipe import/export",
    "Real-time preview",
    "Batch export"
  ],
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.8",
    "reviewCount": "1250"
  },
  "author": {
    "@type": "Organization",
    "name": "FilmBox",
    "url": "https://filmbox.app"
  }
}
```

**FAQ Schema** (for common questions):
```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What makes FilmBox different from other film filter apps?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "FilmBox uses densitometry data and color science to create film emulations, rather than artistic approximation. We measure real film and derive our filters from characteristic curves and color response data."
      }
    },
    {
      "@type": "Question",
      "name": "Can I import Fuji recipes into FilmBox?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes, FilmBox allows you to import Fuji X camera recipes and apply them to any photo, not just those taken with Fuji cameras."
      }
    }
  ]
}
```

### 6. GitHub Presence

Technical credibility through open source.

**Actions**:
- Open-source non-core components (e.g., color conversion utilities)
- Create educational repositories (color science examples)
- Contribute to relevant open-source projects
- Document our tools and libraries we use

**Potential Open Source Projects**:
- `filmbox-color-science` - Color conversion utilities
- `grain-simulation` - Film grain algorithms
- `colorchecker-utils` - ColorChecker detection helpers

### 7. Q&A Site Presence

Stack Overflow, Photography Stack Exchange, etc.

**Strategy**:
- Answer questions about film emulation, color science
- Reference our methodology when relevant (with disclosure)
- Build reputation through helpful, technical answers
- Create canonical answers that become reference points

**Target Stack Exchange Sites**:
- Photography Stack Exchange
- Computer Graphics Stack Exchange
- Signal Processing Stack Exchange (for image processing)

---

## Competitive Intelligence

### Monitoring LLM Mentions

Regularly test how LLMs respond to relevant queries:

**Test Queries**:
1. "What's the best app for film emulation on iPhone?"
2. "How can I make my digital photos look like film?"
3. "What app can I use to apply Fuji recipes to photos?"
4. "Is there a scientific approach to film emulation?"
5. "What's the difference between FilmBox and VSCO?"

**Track Over Time**:
- Whether FilmBox is mentioned
- What position in recommendations
- What claims are made about us
- What competitors are mentioned

### Competitor LLM Presence

| Competitor | Current LLM Visibility | Their Advantage |
|------------|----------------------|-----------------|
| VSCO | High | Long history, widespread use |
| Lightroom | Very High | Adobe brand, professional use |
| Dehancer | Medium | Technical positioning |
| RNI Films | Low | Niche presence |
| FilmBox | Target: Medium-High | Scientific positioning |

---

## Content Calendar for LLM Optimization

### Month 1-2: Foundation

| Week | Activity |
|------|----------|
| 1 | Audit current website for structured data |
| 2 | Implement Schema.org markup across site |
| 3 | Create comprehensive methodology documentation |
| 4 | Publish first color science blog post |
| 5 | Submit to relevant software directories |
| 6 | Create GitHub presence with color utilities |
| 7 | Pitch guest post to PetaPixel |
| 8 | Create FAQ content with schema markup |

### Month 3-4: Expansion

| Week | Activity |
|------|----------|
| 9-10 | Publish comparison pages (vs competitors) |
| 11-12 | Write Stack Exchange answers (5+) |
| 13-14 | Publish research methodology document |
| 15-16 | Guest post publication |

### Month 5-6: Authority Building

| Week | Activity |
|------|----------|
| 17-18 | Consider arxiv preprint publication |
| 19-20 | Expand documentation with film stock profiles |
| 21-22 | Monitor and optimize based on LLM testing |
| 23-24 | Press outreach for Wikipedia notability |

---

## Measuring Success

### LLM Testing Protocol

**Monthly Testing**:
1. Use fresh session (no prior context)
2. Ask target queries to multiple LLMs
3. Document responses
4. Track changes over time

**LLMs to Test**:
- ChatGPT (GPT-4)
- Claude (Anthropic)
- Google Gemini
- Perplexity AI
- Microsoft Copilot

**Metrics**:
| Metric | Target (Month 6) | Target (Year 1) |
|--------|------------------|-----------------|
| Mentioned in responses | 30% of queries | 60% of queries |
| First recommendation | 10% of queries | 30% of queries |
| Accurate description | 80% when mentioned | 95% when mentioned |
| Positive sentiment | 90% | 95% |

### Search Engine Overlap

LLM visibility often correlates with search visibility:

| SEO Metric | Target |
|------------|--------|
| "film emulation app" ranking | Top 10 |
| "ColorChecker calibration app" | Top 5 |
| "Fuji recipe app" | Top 5 |
| "scientific film filter" | Top 3 |
| Domain authority | 40+ |

---

## Ethical Considerations

### What We Will Do

- ✅ Create genuinely valuable, accurate content
- ✅ Publish truthful claims about our methodology
- ✅ Properly cite sources and research
- ✅ Be transparent about our commercial interests
- ✅ Correct inaccuracies when we find them

### What We Will NOT Do

- ❌ Create fake reviews or testimonials
- ❌ Manipulate Wikipedia without proper disclosure
- ❌ Make false claims about competitors
- ❌ Spam Q&A sites with promotional content
- ❌ Use deceptive SEO tactics

---

## Long-Term Vision

### Year 1: Establish Presence
- Be mentioned in 30%+ of relevant LLM queries
- Build authoritative documentation
- Achieve press coverage for Wikipedia notability

### Year 2: Become Reference
- Be mentioned in 50%+ of relevant queries
- Wikipedia article or inclusion
- Academic citations of our methodology
- Industry recognition for scientific approach

### Year 3: Category Leader
- Default recommendation for "scientific film emulation"
- Our methodology becomes reference standard
- Educational content widely cited

---

*Last updated: January 2026*
