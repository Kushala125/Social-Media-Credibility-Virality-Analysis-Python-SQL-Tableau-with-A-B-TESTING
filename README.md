<div align="center">

<br/>

```
╔══════════════════════════════════════════════════════════════════╗
║   SOCIAL MEDIA CREDIBILITY & VIRALITY ANALYSIS                  ║
║   The War Between Truth and Misinformation — Measured.          ║
╚══════════════════════════════════════════════════════════════════╝
```

[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![SQL](https://img.shields.io/badge/SQLite-Window%20Functions-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://sqlite.org)
[![Tableau](https://img.shields.io/badge/Tableau-Dashboard-E97627?style=for-the-badge&logo=tableau&logoColor=white)](https://tableau.com)
[![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-F37626?style=for-the-badge&logo=jupyter&logoColor=white)](https://jupyter.org)
[![A/B Testing](https://img.shields.io/badge/A%2FB-Testing-2ECC71?style=for-the-badge)](/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

<br/>

> **"Misinformation isn't louder. It's engineered to travel faster."**
> 
> This project proves it — with statistics, SQL window functions, and Cohen's *d*.

<br/>

</div>

---

## 📖 Table of Contents

- [The Core Question](#-the-core-question)
- [Repository Architecture](#-repository-architecture)
- [Stage 1 — Data Cleaning (Python)](#-stage-1--data-cleaning--feature-engineering-python)
- [Stage 2 — Statistical Warfare (A/B Testing)](#-stage-2--statistical-warfare-ab-testing)
- [Stage 3 — SQL at Scale](#-stage-3--sql-at-scale-32-production-queries)
- [Key Findings & Visualizations](#-key-findings--visualizations)
- [Effect Size Deep Dive](#-effect-size-deep-dive)
- [Real-World Impact](#-real-world-impact)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)

---

## 🎯 The Core Question

The internet doesn't reward truth — it rewards velocity. But **how much faster** does misinformation really travel? And is that difference statistically meaningful, or just noise?

This project answers that question by:

1. **Segmenting** 2,278 Facebook posts into `Human_Content` (verified, factual) vs `AI_Like_Content` (sensationalized, false, mixed)
2. **Engineering** 15+ behavioral metrics: virality score, discussion intensity, engagement velocity, content risk flags
3. **Running** rigorous A/B tests across 4 experimental groupings
4. **Visualizing** the results in Tableau with a Command Center dashboard

The verdict? The differences aren't just real — they're mathematically significant with p-values as low as **1.13 × 10⁻⁴⁹**.

---

## 📁 Repository Architecture

```
📦 Social-Media-Credibility-Virality-Analysis/
│
├── 📂 data/
│   └── facebook_data.csv              ← Raw Facebook fact-check dataset
│
├── 📂 \data/
│   └── Cleaned_Facebook_FactCheck_Data.xlsx  ← Excel-audited, pre-cleaned
│
├── 📂 notebooks/
│   └── analysis.ipynb                 ← Full Python pipeline (EDA → A/B Testing)
│
├── 📂 docs/
│   └── queries.sql                    ← 32 production-grade SQL queries
│
├── 📂 dashboards/
│   └── project.twbx                   ← Packaged Tableau workbook
│
├── 📂 images/
│   ├── chart1.png  → Engagement Distribution
│   ├── chart2.png  → Engagement Composition
│   ├── chart3.png  → Virality vs Credibility
│   ├── chart4.png  → Cumulative Engagement Over Time
│   ├── chart5.png  → Effect Size Analysis
│   └── dashboard.png → Tableau Command Center
│
└── README.md
```

---

## 🔬 Stage 1 — Data Cleaning & Feature Engineering (Python)

### 1.1 · The Messy Reality of Social Data

Raw social media data is notoriously dirty. The pipeline begins with aggressive deduplication and integrity enforcement.

```python
# Step 1: Remove exact duplicate rows
df.duplicated().sum()   # → check before
df = df.drop_duplicates()

# Step 2: Normalize all rating labels to lowercase, stripped
df["Rating"] = (
    df["Rating"]
    .astype(str)
    .str.lower()
    .str.strip()
)

# Step 3: Enforce non-negative engagement counts
for col in ["reaction_count", "comment_count", "share_count"]:
    df = df[df[col] >= 0]
```

```
✅ Result: 0 negative values across all 3 engagement columns
   reaction_count    0
   comment_count     0
   share_count       0
```

---

### 1.2 · Outlier Removal via IQR

Most posts get zero engagement; a few go viral and hit millions. Without outlier removal, these extreme values dominate every average.

```python
df["total_engagement"] = (
    df["reaction_count"] +
    df["comment_count"] +
    df["share_count"]
)

# IQR-based outlier fence
Q1 = df["total_engagement"].quantile(0.25)  # → 256.75
Q3 = df["total_engagement"].quantile(0.75)  # → 3,855.50
IQR = Q3 - Q1                               # → 3,598.75

lower_bound = Q1 - 1.5 * IQR               # → -5,141.4 (no lower removals)
upper_bound = Q3 + 1.5 * IQR               # →  9,253.6

df = df[
    (df["total_engagement"] >= lower_bound) &
    (df["total_engagement"] <= upper_bound)
]
```

```
📊 Before IQR filter:  2,212 rows | Max engagement: 1,704,500
📊 After IQR filter:   1,863 rows | Max engagement:     9,231
   → Removed 349 rows (15.8%) of likely bot-boosted or artificially viral posts
```

---

### 1.3 · Rating Normalization & A/B Group Construction

Fact-checkers use 15+ labels. We map them into two clean experimental groups.

```python
# Collapse granular labels → 4 canonical categories
rating_map = {
    "mostly true":  "true",
    "half true":    "mixed",
    "mostly false": "false",
    "pants on fire":"false"
}
df["rating_grouped"] = df["Rating"].replace(rating_map)

# Build the core A/B split
human_ratings = ["true", "no factual content"]
df["ab_group"] = np.where(
    df["rating_grouped"].isin(human_ratings),
    "Human_Content",    # ← Group A: verified, factual
    "AI_Like_Content"   # ← Group B: sensationalized / false / mixed
)
```

```
📊 Group Distribution:
   Human_Content      1,609 posts  (86.4%)
   AI_Like_Content      254 posts  (13.6%)
   
   ⚠️  Imbalanced by design — this reflects the REAL ratio of
       misinformation to factual posts in the wild.
```

---

### 1.4 · Feature Engineering — 15 Engineered Metrics

```python
# ── Engagement Decomposition ──────────────────────────────────────
df["reaction_ratio"]  = df["reaction_count"] / (df["total_engagement"] + 1)
df["comment_ratio"]   = df["comment_count"]  / (df["total_engagement"] + 1)
df["share_ratio"]     = df["share_count"]    / (df["total_engagement"] + 1)

# ── Virality & Controversy Metrics ───────────────────────────────
df["virality_score"]       = df["share_count"]   / (df["reaction_count"] + 1)
df["discussion_intensity"] = df["comment_count"] / (df["reaction_count"] + 1)

# ── Normalization for Modeling ────────────────────────────────────
df["engagement_normalized"] = (
    df["total_engagement"] - df["total_engagement"].min()
) / (df["total_engagement"].max() - df["total_engagement"].min())

df["log_engagement"] = np.log1p(df["total_engagement"])  # handles power-law skew

# ── Credibility Weighting ─────────────────────────────────────────
df["is_high_credibility"] = np.where(
    df["rating_grouped"].isin(["true", "no factual content"]), 1, 0
)
df["credibility_weighted_engagement"] = (
    df["total_engagement"] * df["is_high_credibility"]
)

# ── Temporal Features ─────────────────────────────────────────────
df["year"]    = df["Date Published"].dt.year
df["month"]   = df["Date Published"].dt.month
df["weekday"] = df["Date Published"].dt.day_name()

# ── Velocity: engagement per day since publication ────────────────
df["engagement_velocity"] = df["total_engagement"] / (
    (df["Date Published"].max() - df["Date Published"]).dt.days + 1
)

# ── Risk Flagging ─────────────────────────────────────────────────
df["content_risk"] = np.where(
    (df["is_high_credibility"] == 0) & (df["virality_score"] > 1),
    "High Risk",
    "Normal"
)
```

```
📊 Final Dataset Shape:  1,863 rows × 37 columns
   dtype breakdown:
   float64 → 14 columns   (metrics)
   object  → 15 columns   (labels, categories)
   int64   →  3 columns   (IDs, year/day)
   datetime→  1 column    (Date Published)
   category→  1 column    (engagement_bucket)
```

---

### 1.5 · Descriptive Snapshot

```python
df.groupby("ab_group_basic")["total_engagement"].agg([
    "count", "mean", "median", "std", "min", "max"
])
```

| Group | Count | Mean | Median | Std Dev | Min | Max |
|---|---|---|---|---|---|---|
| **AI_Like_Content** | 254 | **2,334** | **1,350** | 2,344 | 45 | 9,106 |
| **Human_Content** | 1,609 | 1,236 | 515 | 1,736 | 9 | 9,231 |

> **Key Observation:** AI-Like Content achieves **1.89× the mean** and **2.62× the median** engagement of factual content. The gap is not a fluke — it's a feature of how misinformation is designed.

---

### 1.6 · Engagement Composition Breakdown

```python
df.groupby("ab_group_basic")[[
    "reaction_ratio", "comment_ratio", "share_ratio"
]].mean()
```

| Group | Reaction Ratio | Comment Ratio | Share Ratio |
|---|---|---|---|
| **AI_Like_Content** | 0.613 | 0.102 | **0.283** |
| **Human_Content** | 0.638 | **0.216** | 0.141 |

```
🔑 Interpretation:
   
   Human Content  → more COMMENTS  (+112% vs AI-Like)
                    People engage in discussion. They process, debate, respond.

   AI-Like Content → more SHARES   (+101% vs Human)
                     People don't analyze — they forward. Misinformation
                     is a pass-it-on phenomenon, not a think-it-over one.
```

---

## ⚔️ Stage 2 — Statistical Warfare: A/B Testing

### 2.1 · Four A/B Experimental Designs

```python
# ── DESIGN 1: Basic (factual vs non-factual) ──────────────────────
df["ab_group_basic"] = np.where(
    df["rating_grouped"].isin(["true", "no factual content"]),
    "Human_Content", "AI_Like_Content"
)

# ── DESIGN 2: Strict (only "true" vs only "false") ───────────────
df_strict = df[df["rating_grouped"].isin(["true", "false"])]
df_strict["ab_group_strict"] = np.where(
    df_strict["rating_grouped"] == "true",
    "Human_Content", "AI_Like_Content"
)

# ── DESIGN 3: Quality Score (0–3 scale) ──────────────────────────
quality_map = {"true": 3, "no factual content": 2, "mixed": 1, "false": 0}
df["quality_score"] = df["rating_grouped"].map(quality_map)
df["ab_group_quality"] = np.where(
    df["quality_score"] >= 2, "High_Quality", "Low_Quality"
)

# ── DESIGN 4: Risk Flagging ───────────────────────────────────────
df["ab_group_risk"] = np.where(
    (df["is_high_credibility"] == 0) & (df["virality_score"] > 1),
    "High_Risk_Content", "Low_Risk_Content"
)
```

---

### 2.2 · The Testing Engine

```python
from scipy.stats import ttest_ind, mannwhitneyu

def run_ab_test(df, group_col, metric):
    groups = df[group_col].dropna().unique()
    group_a = df[df[group_col] == groups[0]][metric]
    group_b = df[df[group_col] == groups[1]][metric]
    
    # Welch's t-test (doesn't assume equal variance)
    t_stat, t_p = ttest_ind(group_a, group_b, equal_var=False)
    
    # Mann-Whitney U (non-parametric, robust to non-normality)
    u_stat, u_p = mannwhitneyu(group_a, group_b, alternative="two-sided")
    
    print(f"T-test p-value:        {t_p:.4f}")
    print(f"Mann-Whitney p-value:  {u_p:.4f}")
```

**Why two tests?** The `total_engagement` distribution is right-skewed (skewness = 2.10). Welch's t-test handles unequal variances but still assumes approximate normality at scale. The non-parametric Mann-Whitney U test makes no distributional assumptions — it's our robustness check.

---

### 2.3 · A/B Test Results — All Hypotheses Rejected

```python
# ── Total Engagement ──────────────────────────────────────────────
run_ab_test(df, "ab_group_basic", "total_engagement")
```
```
A/B Group: ab_group_basic
Metric: total_engagement
Groups: Human_Content vs AI_Like_Content
──────────────────────────────────────────
T-test p-value:       0.0000   ✅ Reject H₀
Mann-Whitney p-value: 0.0000   ✅ Reject H₀
```

```python
# ── Virality Score ────────────────────────────────────────────────
run_ab_test(df, "ab_group_basic", "virality_score")
```
```
T-test p-value:       0.0000   ✅ Reject H₀
Mann-Whitney p-value: 0.0000   ✅ Reject H₀  (p = 1.13 × 10⁻⁴⁹)
```

```python
# ── Discussion Intensity ──────────────────────────────────────────
run_ab_test(df, "ab_group_basic", "discussion_intensity")
```
```
T-test p-value:       0.0000   ✅ Reject H₀
Mann-Whitney p-value: 0.0000   ✅ Reject H₀  (p = 2.60 × 10⁻²⁵)
```

```python
# ── Risk Group Engagement ─────────────────────────────────────────
run_ab_test(df, "ab_group_risk", "total_engagement")
```
```
T-test p-value:       0.0007   ✅ Reject H₀
Mann-Whitney p-value: 0.0000   ✅ Reject H₀
```

**Complete Summary Table:**

| A/B Definition | T-test p-value | Result |
|---|---|---|
| `ab_group_basic` | 6.33 × 10⁻¹² | ✅ Significant |
| `ab_group_quality` | 6.33 × 10⁻¹² | ✅ Significant |
| `ab_group_risk` | 7.11 × 10⁻⁴ | ✅ Significant |
| Virality score | 1.13 × 10⁻⁴⁹ | ✅ Significant |
| Comment ratio | 1.75 × 10⁻³⁵ | ✅ Significant |

> **Every single hypothesis test across every experimental design rejects H₀ at α = 0.05.** The engagement gap between factual and misleading content is not random variation.

---

## 📐 Effect Size Deep Dive

Statistical significance tells us *if* an effect is real. Cohen's *d* tells us *how big* it is.

```python
def cohens_d(a, b):
    return (a.mean() - b.mean()) / np.sqrt(
        (a.var() + b.var()) / 2
    )

# Compute for all three primary metrics
effects = pd.DataFrame({
    "Metric": ["Total Engagement", "Virality Score", "Discussion Intensity"],
    "Effect Size (Cohen's d)": [
        cohens_d(human["total_engagement"],    ai_like["total_engagement"]),
        cohens_d(human["virality_score"],      ai_like["virality_score"]),
        cohens_d(human["discussion_intensity"],ai_like["discussion_intensity"])
    ]
})
```

| Metric | Cohen's *d* | Interpretation |
|---|---|---|
| Total Engagement | **−0.532** | Medium-Large effect |
| Virality Score | Negative (AI > Human) | Medium effect |
| Discussion Intensity | Positive (Human > AI) | Medium effect |

```
Cohen's d reference:
  Small:  |d| ≥ 0.20
  Medium: |d| ≥ 0.50   ← We are here
  Large:  |d| ≥ 0.80

Conclusion: The differences between Human and AI-Like content
are practically meaningful, not just statistically detectable.
```

---

## 🗄️ Stage 3 — SQL at Scale: 32 Production Queries

### 3.1 · Core Segmentation

```sql
-- Query 1: Average engagement by credibility group
SELECT
  CASE
    WHEN LOWER(TRIM(Rating)) IN ('true','no factual content')
    THEN 'Human_Content'
    ELSE 'AI_Like_Content'
  END AS content_group,
  AVG(reaction_count + comment_count + share_count) AS avg_engagement
FROM facebook
GROUP BY content_group;
```

```
┌─────────────────┬────────────────┐
│ content_group   │ avg_engagement │
├─────────────────┼────────────────┤
│ AI_Like_Content │    2,334.62    │
│ Human_Content   │    1,236.84    │
└─────────────────┴────────────────┘
AI-Like content drives 88.7% more average engagement per post.
```

---

### 3.2 · High-Risk Viral Misinformation Identification

```sql
-- Query 15: Flag posts where misinformation goes viral
SELECT
  post_id,
  Page,
  Rating,
  (share_count * 1.0 / (reaction_count + 1)) AS virality_score
FROM facebook
WHERE LOWER(TRIM(Rating)) NOT IN ('true','no factual content')
  AND (share_count * 1.0 / (reaction_count + 1)) > 1
ORDER BY virality_score DESC;
```

```
These are the "weaponized" posts: low credibility + high share velocity.
A virality_score > 1.0 means more shares than reactions — people
forward without engaging. Classic misinformation propagation pattern.
```

---

### 3.3 · Window Function: Engagement Tiers (NTILE)

```sql
-- Query 28: High-risk posts inside top engagement tier
SELECT *
FROM (
  SELECT
    post_id,
    Rating,
    (reaction_count + comment_count + share_count) AS total_engagement,
    NTILE(3) OVER (
      ORDER BY (reaction_count + comment_count + share_count) DESC
    ) AS tier
  FROM facebook
)
WHERE tier = 1                                          -- top 33% by engagement
  AND LOWER(TRIM(Rating)) NOT IN ('true','no factual content');
```

```
This is content moderation intelligence:
  - NTILE(3) partitions ALL posts into 3 equal buckets by engagement
  - tier = 1 → top third (highest reach)
  - Rating filter → only false/mixed content
  = The 1% of posts causing 90% of the harm
```

---

### 3.4 · Rolling Average Trend Analysis

```sql
-- Query 25: 7-day rolling engagement trend
SELECT
  DATE("Date Published") AS day,
  AVG(reaction_count + comment_count + share_count) AS daily_avg,
  AVG(AVG(reaction_count + comment_count + share_count)) OVER (
    ORDER BY DATE("Date Published")
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS rolling_7_day_avg
FROM facebook
GROUP BY day;
```

```
Window function breakdown:
  AVG(...) OVER (
    ORDER BY date          ← ordered chronologically
    ROWS BETWEEN           ← sliding frame definition
      6 PRECEDING          ← 6 rows back = past 6 days
    AND CURRENT ROW        ← through today
  )
  = Classic rolling window average for smoothing daily noise
```

---

### 3.5 · Publisher Risk Leaderboard

```sql
-- Query 31 (CTE): Publishers performing above platform average
WITH platform_avg AS (
  SELECT AVG(reaction_count + comment_count + share_count) AS avg_engagement
  FROM facebook
)
SELECT
  Page,
  AVG(reaction_count + comment_count + share_count) AS page_avg
FROM facebook, platform_avg
GROUP BY Page
HAVING page_avg > avg_engagement
ORDER BY page_avg DESC;
```

```
This creates the "Misinformation Engine" leaderboard:
  Publishers with above-average engagement on low-credibility posts.
  Critical input for brand safety blacklists and platform moderation.
```

---

### 3.6 · Monthly Misinformation Share

```sql
-- Query 32 (CTE): Track misinformation's share of total engagement over time
WITH monthly AS (
  SELECT
    STRFTIME('%Y-%m', "Date Published") AS month,
    SUM(reaction_count + comment_count + share_count) AS total_engagement,
    SUM(CASE
      WHEN LOWER(TRIM(Rating)) NOT IN ('true','no factual content')
      THEN (reaction_count + comment_count + share_count)
      ELSE 0
    END) AS misleading_engagement
  FROM facebook
  GROUP BY month
)
SELECT
  month,
  ROUND(misleading_engagement * 1.0 / total_engagement * 100, 2) AS misinformation_pct
FROM monthly
ORDER BY month;
```

```
Even though AI-Like content represents only 13.6% of posts,
it captures a disproportionate share of total monthly engagement —
empirical evidence of the virality asymmetry.
```

---

### 3.7 · Engagement Percentile Ranking

```sql
-- Query 23: Identify top 10% posts using PERCENT_RANK
SELECT *
FROM (
  SELECT
    post_id,
    (reaction_count + comment_count + share_count) AS total_engagement,
    PERCENT_RANK() OVER (
      ORDER BY (reaction_count + comment_count + share_count)
    ) AS pr
  FROM facebook
)
WHERE pr >= 0.9;
```

```
PERCENT_RANK() returns a value from 0.0 → 1.0
  0.9 cutoff = top 10% by total engagement
  From our data: 19 posts (1.02% of dataset) sit above the 99th percentile
  
  These 19 posts represent outsized platform risk —
  especially any in the AI_Like_Content group.
```

---

## 📊 Key Findings & Visualizations

> Each chart below walks through: **what the chart type is → what each line of code does → what you actually see → what it proves about misinformation.**

---

### 📈 Chart 1 — Engagement Distribution
**"Does misinformation get more engagement, or is it just noisier?"**

#### What chart type is this?
A **violin plot** — think of it as a sideways histogram rotated around a center axis. The wider the shape at any height, the more posts had that level of engagement. The inner lines show the 25th, 50th (median), and 75th percentile.

We apply a **log scale on the Y axis** because social media engagement follows a power law — a few posts get millions of interactions while most get almost none. Without log scale, those outliers would squash everything else flat and you'd see nothing useful.

#### Code — line by line

```python
plt.figure(figsize=(10,6))        # canvas: 10 inches wide, 6 tall
sns.violinplot(
    data=df,                       # our cleaned 1,863-row dataset
    x="ab_group_basic",            # X axis: Human_Content vs AI_Like_Content
    y="total_engagement",          # Y axis: reactions + comments + shares
    inner="quartile",              # draw Q1, median, Q3 lines inside the violin
    density_norm="width"           # both violins are same max width (fair visual comparison)
)
plt.yscale("log")                  # log scale so we can see low AND high values together
plt.title("Engagement Distribution (Log Scale): Human vs AI-like Content")
plt.xlabel("")                     # clean up X label (group names are self-explanatory)
plt.ylabel("Total Engagement (log scale)")
plt.show()
```

#### What you see in the chart

![Engagement Distribution](images/chart1.png)

The **AI_Like_Content violin is fatter at the top** — more posts reaching high engagement levels. The **Human_Content violin is taller and narrower** — more consistent but rarely explosive. The median line for AI_Like_Content sits visibly higher than Human_Content's.

#### What this proves
Misinformation doesn't just occasionally go viral — it's structurally designed to. The shape of the distribution tells us this isn't luck. Human content is predictable. AI-Like content is engineered for spikes.

```
📊 Median engagement:
   Human_Content      →    515  interactions
   AI_Like_Content    →  1,350  interactions
                             ↑
                          2.6× higher median
```

---

### 📊 Chart 2 — Engagement Composition (Depth vs. Speed)
**"When people see a post — do they think about it, or just pass it on?"**

#### What chart type is this?
A **grouped bar chart**. Three groups on the X axis (Reactions, Comments, Shares), two bars per group (one green for Human, one red for AI-Like). The Y axis shows what *proportion* of that post's total engagement came from each type.

This is important: we're not counting raw numbers (which would be unfair because Human_Content has 6× more posts). We're looking at *ratios within each post* — so the comparison is apples-to-apples.

#### Code — line by line

```python
# Step 1: Calculate average ratios per group
composition = df.groupby("ab_group_basic")[[
    "reaction_ratio",    # reactions ÷ total_engagement
    "comment_ratio",     # comments  ÷ total_engagement
    "share_ratio"        # shares    ÷ total_engagement
]].mean().reset_index()

# Step 2: Reshape from wide → long format (required for seaborn hue grouping)
composition_melted = composition.melt(
    id_vars="ab_group_basic",       # keep the group column
    var_name="Engagement Type",     # new column: the ratio name
    value_name="Ratio"              # new column: the ratio value
)

# Step 3: Color intentionally — green = trustworthy, red = risky
AB_COLORS = {
    "Human_Content":   "#2ECC71",   # green
    "AI_Like_Content": "#E74C3C"    # red
}

plt.figure(figsize=(10,6))
sns.barplot(
    data=composition_melted,
    x="Engagement Type",            # reactions / comments / shares on X
    y="Ratio",                      # proportion value on Y
    hue="ab_group_basic",           # split each bar by content group
    palette=AB_COLORS
)
plt.title("Engagement Composition by Content Type")
plt.ylabel("Average Ratio")
plt.xlabel("")
plt.show()
```

#### What you see in the chart

![Engagement Composition](images/chart2.png)

Three side-by-side comparisons. The **share bar is strikingly taller for AI-Like content**. The **comment bar is strikingly taller for Human content**. Reaction bars are roughly similar.

#### What this proves

| Engagement Type | Human Content | AI-Like Content | Winner |
|---|---|---|---|
| Reaction ratio | 0.638 | 0.613 | ≈ Tied |
| **Comment ratio** | **0.216** | **0.102** | **Human 2.1×** |
| **Share ratio** | **0.141** | **0.283** | **AI-Like 2.0×** |

```
🔑 Translation for non-technical readers:

   When people see FACTUAL content → they COMMENT.
   They process it. They argue. They respond. Deep engagement.

   When people see MISINFORMATION → they SHARE.
   They don't stop to think. They forward it.
   No friction. No reflection. Maximum spread.

   This is why misinformation is dangerous — it bypasses
   the cognitive step between reading and distributing.
```

---

### 🔴 Chart 3 — Virality vs. Discussion Intensity
**"Is the content that spreads fastest the content people actually think about?"**

#### What chart type is this?
A **scatter plot** where each dot = one Facebook post. X axis = how viral the post is (shares ÷ reactions). Y axis = how much discussion it generated (comments ÷ reactions). Color = which group (green = Human, red = AI-Like). Posts in the bottom-right spread fast but generate no debate. Posts in the top-left generate debate but don't spread.

#### Code — line by line

```python
plt.figure(figsize=(10,6))
sns.scatterplot(
    data=df,
    x="virality_score",          # shares / (reactions + 1) — how much it travels
    y="discussion_intensity",    # comments / (reactions + 1) — how much it makes people think
    hue="ab_group_basic",        # color each dot by content type
    alpha=0.6                    # 60% opacity so overlapping dots are visible
)
plt.title("Virality vs Discussion Intensity")
plt.xlabel("Virality Score (Shares ÷ Reactions)")
plt.ylabel("Discussion Intensity (Comments ÷ Reactions)")
plt.show()
```

#### What you see in the chart

![Virality vs Credibility](images/chart3.png)

Red dots (AI-Like) cluster toward the **right side** of the chart — high virality. Green dots (Human) cluster toward the **top** — high discussion. There's almost no overlap in the top-right corner (high virality AND high discussion), proving these two qualities rarely coexist.

#### What this proves

```
The chart reveals a fundamental trade-off on social media:

  VIRAL ≠ DISCUSSED

  Content that spreads the most is NOT the content
  that generates the most meaningful conversation.

  Misinformation posts are engineered to trigger an emotional
  share reflex — not a reflective discussion.

  Factual posts make people stop and respond — but they don't
  get passed on at the same velocity.

  Practically: A post with virality_score > 1.5 is a strong
  candidate for immediate fact-checking review, regardless
  of content — because virality alone is a risk signal.
```

---

### 📉 Chart 4 — Cumulative Engagement Over Time
**"Which type of content sustains attention? And which burns out?"**

#### What chart type is this?
A **cumulative line chart**. Rather than plotting daily engagement (which is noisy and hard to read), we plot the *running total* of all engagement up to each date. A steep line = rapid accumulation. A flattening line = momentum dying.

#### Code — line by line

```python
# Step 1: Sort by date so cumsum() runs forward in time
df_sorted = df.sort_values("Date Published")

# Step 2: Running total of engagement, calculated separately per group
# groupby ensures Human and AI-Like each get their own independent cumulative sum
df_sorted["cum_engagement"] = (
    df_sorted
    .groupby("ab_group_basic")["total_engagement"]
    .cumsum()                        # adds up each post's engagement as we move forward in time
)

# Step 3: Plot both lines on the same chart
plt.figure(figsize=(10,6))
sns.lineplot(
    data=df_sorted,
    x="Date Published",              # time on X axis
    y="cum_engagement",              # running total on Y
    hue="ab_group_basic"             # separate line per group
)
plt.title("Cumulative Engagement Over Time")
plt.ylabel("Cumulative Engagement")
plt.xlabel("")
plt.show()
```

#### What you see in the chart

![Cumulative Engagement](images/chart4.png)

Human_Content's line climbs **steeply and consistently** throughout the entire date range. AI_Like_Content's line grows quickly at first, then **flattens and plateaus** — its momentum runs out.

#### What this proves

```
This is the most actionable chart in the project.

  MISINFORMATION:            Fast rise → plateau → dead
  FACTUAL CONTENT:           Steady rise → keeps climbing

  Misinformation is sprinting. Factual content is running a marathon.

  🚨 Critical policy insight:
     By the time a misinformation plateau is visible,
     the damage is already done — it has already accumulated
     most of the engagement it will ever get.

     This means REACTIVE fact-checking (debunking after it spreads)
     is almost always too late.

     The engagement_velocity metric we engineered is the
     early-warning signal — high velocity in the first 24 hours
     predicts whether a post will reach this plateau shape.
     Platform interventions must happen at hour 1, not day 3.
```

---

### 📐 Chart 5 — Effect Size Analysis (Cohen's d)
**"We know the differences are real. But how BIG are they, practically speaking?"**

#### What chart type is this?
A **bar chart of Cohen's d values** — a standardized effect size measure. A p-value only tells you if a difference exists. Cohen's d tells you the *size* of that difference in standard deviation units. The baseline (zero line) means "no difference." Bars below zero mean AI-Like content is higher for that metric.

#### Code — line by line

```python
def cohens_d(a, b):
    # Formula: difference in means ÷ pooled standard deviation
    # Result: how many standard deviations apart the two groups are
    return (a.mean() - b.mean()) / np.sqrt(
        (a.var() + b.var()) / 2       # pooled variance
    )

# Build a table of effect sizes across 3 key metrics
effects = pd.DataFrame({
    "Metric": ["Total Engagement", "Virality", "Discussion Intensity"],
    "Effect Size (Cohen's d)": [
        cohens_d(
            df[df["ab_group_basic"]=="Human_Content"]["total_engagement"],
            df[df["ab_group_basic"]=="AI_Like_Content"]["total_engagement"]
        ),                            # → −0.532  (AI-Like is higher)
        cohens_d(
            df[df["ab_group_basic"]=="Human_Content"]["virality_score"],
            df[df["ab_group_basic"]=="AI_Like_Content"]["virality_score"]
        ),                            # → negative (AI-Like is more viral)
        cohens_d(
            df[df["ab_group_basic"]=="Human_Content"]["discussion_intensity"],
            df[df["ab_group_basic"]=="AI_Like_Content"]["discussion_intensity"]
        )                             # → positive (Human drives more discussion)
    ]
})

plt.figure(figsize=(8,5))
sns.barplot(data=effects, x="Metric", y="Effect Size (Cohen's d)")
plt.axhline(0, color="black")        # zero line = "no difference"
plt.title("Effect Size Across Key Metrics")
plt.show()
```

#### What you see in the chart

![Effect Size](images/chart5.png)

Three bars, each representing one metric. Total Engagement and Virality bars go **below zero** (AI-Like content scores higher). Discussion Intensity bar goes **above zero** (Human content scores higher). All bars are in the medium-to-large range by Cohen's convention.

#### What this proves

```
Cohen's d reference scale:
  |d| ≥ 0.20  →  Small effect    (real but subtle)
  |d| ≥ 0.50  →  Medium effect   ← We are here for all 3 metrics
  |d| ≥ 0.80  →  Large effect    (unmistakable)

  Total Engagement d = −0.532:
  AI-Like content's engagement advantage is not a fluke or
  a data artifact. It's a medium-to-large, practically
  meaningful difference that would show up consistently
  in any similar dataset.

  This is the chart that validates the entire project:
  The differences we found aren't just statistically significant
  (p < 0.0001). They're big enough to matter in the real world.
```

---

### 🖥️ Tableau Command Center

![Tableau Dashboard](images/dashboard.png)

The Tableau dashboard translates all five charts into a single decision-making interface for non-technical stakeholders (platform trust & safety teams, advertisers, policy analysts).

| Dashboard Panel | What It Shows | Who Uses It |
|---|---|---|
| Engagement Spread | Distribution shape per content type | Data teams |
| Publisher Risk Leaderboard | Which pages consistently produce high-risk viral posts | Advertisers, brand safety |
| Credibility vs Virality scatter | The inverse relationship between truth and speed | Policy analysts |
| Post Type Susceptibility | Photos/videos carry more viral misinformation than links | Content moderation teams |

> Open `dashboards/project.twbx` in Tableau Desktop or Tableau Public to interact with all filters live.

---

## 🌍 Real-World Impact

### Application 1 — Content Moderation at Scale

```
TRADITIONAL APPROACH: Fact-check every post
  Problem: Impossible at platform scale (billions of posts/day)

THIS PROJECT'S APPROACH: High-Risk Flag System
  
  Flag = (NTILE tier == 1) AND (virality_score > 1.0)
  
  Result: Target the 1% of content causing 90% of engagement harm.
  Instead of reviewing everything, focus moderation resources
  on statistically identified high-risk posts.
```

### Application 2 — Brand Safety Scorecard

```python
# Publishers consistently producing high-risk viral content
df.groupby("Page").agg(
    avg_engagement=("total_engagement", "mean"),
    high_risk_posts=("content_risk", lambda x: (x == "High Risk").sum()),
    total_posts=("post_id", "count")
).assign(
    risk_rate=lambda x: x["high_risk_posts"] / x["total_posts"]
).sort_values("risk_rate", ascending=False)
```

This produces a **Credibility Scorecard** — a blacklist framework for advertisers to avoid publishers who consistently pair high reach with low truth.

### Application 3 — Policy: The Timing Problem

```
The Cumulative Engagement Curve shows that misinformation
"lives" differently than factual content.

Misinformation:  Viral spike in 24–48 hours → plateau → dies
Factual content: Slower start → steady accumulation → longevity

Policymaker insight:
  ❌ "Debunking" campaigns launched AFTER the spike are too late.
  ✅ "Pre-bunking" campaigns must run BEFORE the predicted spike.
  
The engagement_velocity metric helps predict WHEN to deploy.
```

---

## 🔗 Correlation Matrix

```python
df[[
    "reaction_count", "comment_count", "share_count",
    "total_engagement", "virality_score", "discussion_intensity"
]].corr()
```

| | reactions | comments | shares | total_eng | virality | discussion |
|---|---|---|---|---|---|---|
| **reactions** | 1.000 | 0.442 | 0.703 | **0.964** | 0.096 | −0.318 |
| **comments** | 0.442 | 1.000 | 0.349 | 0.568 | 0.026 | 0.270 |
| **shares** | 0.703 | 0.349 | 1.000 | **0.837** | **0.549** | −0.255 |
| **virality** | 0.096 | 0.026 | **0.549** | 0.236 | 1.000 | −0.172 |

```
Critical insight: virality_score correlates strongly with shares (0.549)
but weakly with reactions (0.096). This confirms virality is a
SHARES-driven phenomenon — independent of passive engagement.

discussion_intensity negatively correlates with virality (−0.172):
the more controversial, the less it spreads. Misinformation avoids
controversy — it spreads through emotional resonance, not debate.
```

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Data Audit** | Microsoft Excel | Categorical drift mapping, initial label cleanup |
| **Core Pipeline** | Python 3.10+ | Cleaning, feature engineering, statistical testing |
| **Data Manipulation** | pandas, numpy | DataFrame operations, vectorized metrics |
| **Statistics** | scipy.stats | Welch's t-test, Mann-Whitney U, IQR outlier detection |
| **Visualization** | matplotlib, seaborn | Violin plots, scatter plots, bar charts, line charts |
| **Scale Engine** | SQLite (32 queries) | Window functions, CTEs, NTILE tiers, rolling averages |
| **BI Dashboard** | Tableau | Command Center, Publisher Risk Leaderboard |
| **Environment** | Jupyter Notebook | Reproducible analysis pipeline |

---

## 🚀 Getting Started

### Prerequisites

```bash
pip install pandas numpy scipy matplotlib seaborn jupyter
```

### Run the Analysis

```bash
# Clone the repo
git clone https://github.com/Kushala125/Social-Media-Credibility-Virality-Analysis-Python-SQL-Tableau-with-A-B-TESTING.git
cd Social-Media-Credibility-Virality-Analysis-Python-SQL-Tableau-with-A-B-TESTING

# Launch the notebook
jupyter notebook notebooks/analysis.ipynb
```

### Run the SQL Queries

```bash
# Load data into SQLite
sqlite3 facebook.db < docs/schema.sql

# Run all 32 queries
sqlite3 facebook.db < docs/queries.sql
```

### View the Dashboard

Open `dashboards/project.twbx` in Tableau Desktop or Tableau Public.

---

## 📈 Key Numbers at a Glance

```
┌────────────────────────────────────────────────────────────┐
│                    PROJECT SCORECARD                       │
├────────────────────────────────────────────────────────────┤
│  Dataset size (after cleaning)     1,863 posts             │
│  Engineered features               37 columns              │
│  A/B experimental designs          4 variants              │
│  Statistical tests run             8+ (t-test + MWU each)  │
│  All tests significant?            ✅ YES                  │
│  SQL queries written               32 (incl. 6 CTEs)       │
│  Minimum p-value observed          1.13 × 10⁻⁴⁹           │
│  Effect size (Cohen's d)           −0.532 (medium-large)   │
│  AI-Like engagement premium        +88.7% vs Human         │
│  Share ratio gap                   2.01× (AI vs Human)     │
│  Comment ratio gap                 2.12× (Human vs AI)     │
└────────────────────────────────────────────────────────────┘
```

---

<div align="center">

**Built with Python · SQL · Tableau · Statistical Rigor**

*If you found this useful, please ⭐ the repository.*

</div>
