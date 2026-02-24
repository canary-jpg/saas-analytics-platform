# SaaS Analytics Platform
## Data Warehouse & Analytics Documentation

### Table of Contents
1. Overview
2. Data Architecture
3. Data Models
4. Key Metrics & KPIs
5. Analytics Use Cases
6. Key Insights from Analysis
7. Looker Implementation
8. Maintenance & Best Practices
9. Appendix A: Model Lineage
10. Appendix B: Glossary

## 1. Overview
### Project Summary
This analytics platform provides comprehensive insights into user behavior, revenue metrics, retention patterns, and product engagement for a SaaS business. Built using dbt (data build tool) on DuckDB with Looker for visualization.

### Technology Stack
* Database: DuckDB
* Transformation: dbt (Data Build Tool)
* Visualization: Looker (LookML)
* Version Control: Git

### Key Capabilities
* User lifecycle tracking and segmentation
* Revenue growth accounting (MRR movements)
* Retention cohort analysis
* A/B testing with statistical significance
* Feature adoption tracking
* Customer lifetime value analysis
* Engagement scoring

## 2. Data Architecture
### Layer Structure
The data warehouse follows a three-layer architecture designed for scalability and maintainability:

#### Staging Layer
Cleaned, renamed source data with data quality tests
* stg_users - User signup information with standardized field names
* stg_events - Product event stream with lowercased dimensions
* stg_subscriptions - Subscription records with derived boolean flags
**Purpose**: Isolate raw data transformations, enforce naming conventions, run data quality tests
**Materialization**: Views (no storage cost, always fresh)

#### Marts Layer
Business logic and metrics organization by domain
##### Core Marts:
* `dim_users` - User dimension with lifecycle stage, current subscription, and lifetime metrics
* `fct_events` - Event fact table enriched with user and subscription context
* `fct_user_activity_by_date` - Daily activity spine for retention analysis
##### Revenue Marts:
* `fct_mrr_by_month` - Monthly MRR snapshot by user/subscription
* `rpt_mrr_movements` - MRR growth accounting (new, expansion, contraction, churn)
* `rpt_customer_ltv` - Customer lifetime value by cohort and channel
##### Product Marts:
* `rpt_feature_adoption` - Feature usage timing and engagement levels
* `rpt_activation_funnel` - User progression through activation milestones
* `rpt_user_engagement_score` - 0-100 engagement scoring
##### Retention Marts:
* `rpt_retention_cohorts` - Classic cohort retention table (weeks 0-12)
* `rpt_retention_curves` - Long-format retention data for charting
##### Experiment Marts:
* `fct_experiment_assignments` - User-variant assignment with timing
* `fct_experiment_conversions` - Conversion events post-assignment
* `rpt_experiment_results` - Statistical analysis with significance testing
* `rpt_experiment_results_by_channel` - Segmented experiment analysis
**Purpose**: Implement business logic once, enable self-service analytics
**Materialization**: Tables (fast query performance for BI tools)

#### Reporting Layer
Pre-built dashboards and visualizations via Looker

## 3. Data Models
### Core Models
**dim_users**
**Description**: One row per user containing signup information, current subscription status, and lifetime metrics
**Grain**: One row per user
**Key Fields**:
* `user_id` - Unique identifier (primary key)
* `signed_up_at` - Account creation timestamp
* `acquisition_channel` - Marketing source (organic, paid_search, sales, referral)
* `country` - User's country
* `user_lifecycle_stage` - active|churned|never_subscribed|other
* `current_plan` - Current subscription plan
* `total_events` - Lifetime event count
* `lifetime_revenue_usd` - Total revenue from this user
* `days_since_signup` - User age in days
* `days_since_last_event` - Recency metric
**Common Filters**:
* `user_lifecycle_stage = 'active'` - Current paying customers
* `is_currently_subscribed = true` - Active subscriptions
* `acquisition_channel` - Channel performance analysis
**Sample Query**:
```
select
    acquisition_channel,
    count(*) as users,
    sum(case when user_lifecycle_stage = 'active' then 1 else 0 end) as active_users,
    avg(lifetime_revenue_usd) as avg_ltv
from dim_users
group by acquisition_channel
order by avg_ltv desc;
```

**fct_events**
**Description**: Enriched event stream with user and subscription context at the time each event was fired.
**Grain**: One row per event
**Key Field**:
* `event_id` - Unique identifier (primary key)
* `user_id` - Foreign key to dim_users
* `event_name` - Event name (signup, onboarding_completed, feature_a_used, used, etc.)
* `event_at` - Event timestamp
* `device_type` - Device used
* `acquisition_channel` - User's acquisition channel
* `subscription_plan` - Plan active when event fired
* `experiment_variant` - A/B test variant
* `days_since_signup` - User age when event fired
**Common Filters**:
* `event_name = 'upgrade'` - Conversion events
* `days_since_signup <= 14` - Early lifecycle analysis
* `experiment_variant IS NOT NULL` - Users in experiments
**Sample Query**:
```
select
    event_name,
    count(distinct user_id) as unique_users,
    count(*) as total_events
from fct_events
where days_since_signup <= 7
group by event_name
order by unique_users desc;
```

### Revenue Models
**rpt_mrr_movements**
**Description**: Monthly MRR growth accounting showing how MRR changes month-over-month.
**Grain**: One row per month
**Key Metrics**:
* `total_mrr` - Total MRR at the end of the month
* `new_mrr` - MRR from new customers
* `expansion_mrr` - Additional MRR from upgrades
* `contraction_mrr` - Lost MRR from downgrades
* `churned_mrr` - Lost MRR from cancellations
* `net_mrr_change` - new + expansion - contraction - churn
* `mrr_growth_rate` - Percentage month-over-month growth
* `churn_rate` - Percent of prior month MRR churned
**Customer Counts**:
* `new_customers`, `expansion_customers`, `contraction_customers`, `churned_customers`, `retained_customers`
**Sample Query**:
```
select
    month_date,
    total_mrr,
    new_mrr,
    churned_mrr,
    net_mrr_change,
    mrr_growth_rate,
    churn_rate
from rpt_mrr_movements
order by month_date desc
limit 6;
```
**rpt_customer_ltv**
**Description**: Customer lifetime value analysis by cohort and acquistion channel.
**Grain**: One row per paying customer
**Key Metrics**:
* `ltv` - Lifetime value (total revenue to date)
* `arpu` - Average revenue per user per month
* `lifetime_months` - How long has the customer been paying
* `total_revenue` - Sum of all monthly revenue
* `days_to_first_subscription` - Time from signup to first paid subscription
**Dimensions**:
* `cohort_month` - Month user signed up
* `acquisition_channel` - Marketing source
**Sample Query**:
```
select
    acquisition_channel,
    count(*) as customers,
    avg(ltv) as avg_ltv,
    avg(arpu) as avg_arpu,
    avg(lifetime_months) as avg_lifetime
from rpt_customer_ltv
group by acquisition_channel
order by avg_ltv desc;
```

### Product Models
**rpt_feature_adoption**
**Description**: Tracks which features users adopt, when they first use them and engagement levels.
**Grain**: One row per user-feature pair
**Key Fields**:
* `feature` - Feature name (onboarding_completed, feature_a_used, feature_b_used)
* `first_used_at` - When user first used this feature
* `days_to_first_use` - Days from signup to first use
* `adoption_timeframe` - Bucketed timing (Day 0, Day 1, Days 2-3, etc.)
* `total_uses` - Number of times used
* `engagement_level` - Power User| Regular User| Occasional User | One-Time User
**Sample Query**:
```
select
    feature,
    adoption_timeframe,
    count(*) as users,
    avg(total_uses) as avg_uses
from rpt_feature_adoption
group by feature, adoption_timeframe
order by feature, adoption_time;
```
**rpt_activation_funnel**
**Description**: User progression through activation milestones.
**Grain**: One row per user
**Activation Steps**:
1. Signup (100% by definition)
2. Onboarding completed
3. Feature A Used
4. Feature B Used
5. Upgraded to Paid
**Key Fields**:
* `activation_level` - Fully Activated (Paid)| Feature User| Onboarded| Signed Up Only
* `activation_score` - 0-5 based on steps completed
* `completed_onboarding` - Boolean
* `days_to_onboarding` - Time to complete onboarding
* `days_to_upgrade` - Time to first paid subscription
**Sample Query**:
```
select
    activation_level,
    count(*) as users,
    avg(activation_score) as avg_score,
    sum(case when is_currently_subscribed then 1 else 0 end)::float / count(*) * 100 as pct_paid
from rpt_activation_funnel
group by activation_level
order by avg_score desc;
```

**rpt_user_engagement_score**
**Description**: 0-100 engagement score based on recency, frequency, and breadth of activity.
**Grain**: One row per user
**Scoring Formula**:
* Recency (30 points): Active in last 7 days = 30pts, last 30 days=15pts
* Frequency (40 points): Days active in the last 30 days (max 40)
* Breadth (30 points): Unique events in last 30 days (max 30)
**Engagement Tiers**:
* High Engagement: 70-100 points
* Medium Engagement: 40-69 points
* Low Engagement: 1-30 points
* Dormant: 0 points
**Key Fields**:
* `engagement_score` - 0-100 composite score
* `engagement_tier` - Tier classification
* `activity_status` - WAU| MAU| Dormant
* `active_days_l30d` - Days active in last 30 days
* `unique_events_l30d` - Unique event types in last 30 days
**Sample Query**:
```
select
    engagement_tier,
    count(*) as users,
    avg(engagement_score) as avg_score,
    sum(case when is_currently_subscribed then 1 else 0 end)::float / count(*) * 100 as pct_paid
from rpt_user_engagement_score
group by engagement_tier
order by avg_score desc;
```

### Retention Models
**rpt_retention_cohorts**
**Description**: Classic cohort retention table showing percentage of users active in weeks 0-12.
**Grain**: One row per cohort (weekly cohorts)
**Key Fields**:
* `cohort_week` - Month of signup week (primary key)
* `cohort_size` - Total users in cohort
* `week_0_pct` through `week_12_pct` - Retention percentages
**Sample Query**:
```
select
    cohort_week,
    cohort_size,
    week_0_pct,
    week_1_pct,
    week_4_pct, 
    week_8_pct,
    week_12_pct,
from rpt_retention_cohorts
order by cohort_week desc
limit 10;
```

**rpt_retention_curves**
**Description**: Long-format retention data optimized for charting.
**Grain**: One row per cohort-week pair
**Key Fields**:
* `cohort_week` - Cohort identifier
* `weeks_since_cohort` - 0, 1, 2, 3... weeks after signup
* `retention_pct` - Percentage still active
* `cohort_label` - Human-readable label for charts
**Sample Query**:
```
select
    cohort_label,
    weeks_since_cohort,
    retention_pct
from rpt_retention_curves
where cohort_week >= '2024-01-01'
order by cohort_week, weeks_since_cohort;
```

### Experiment Models
**rpt_experiment_results**
**Description**: A/B test results with statistical significance testing.
**Grain**: One row per conversion event
**Key Metrics (per variant)**:
* total users assigned
* converted users
* conversion rate
* average days to conversion
**Statistical Metrics**:
* `absolute_lift` - Difference in conversion rates (B - A)
* `relative_lift_pct` - Percentage lift
* `z_score` - Test statistic from two-proportion z-test
* `ci_lower`, `ci_upper` - 95% confidence interval
* `is_statistically_significant` - True if |z| > 1.96
* `winner` - Which variant performed better
**Sample Query**:
```
select
    conversion_event,
    a_conversion_rate,
    b_conversion_rate,
    relative_lift_pct,
    z_score,
    is_statistically_significant,
    winner
from rpt_experiment_results
order by conversion_event;
```

**rpt_experiment_results_by_channel**
**Description**: Segmented A/B test analysis by acquisition channel.
**Grain**: One row per channel-conversion_event pair
**Use Case**: Identify heterogeneous treatment effects (variant B might work better for certain channels)
**Sample Query**:
```
select
    acquisition_channel,
    conversion_event,
    relative_lift_pct,
    is_statistically_significant,
    winner
from rpt_experiment_results_by_channel
where conversion_event = 'upgrade'
order by abs(relative_lift_pct) desc;
```

## 4. Key Metrics & KPIs
### Business Metrics
#### Monthly Recurring Revenue (MRR)
* Definition: Sum of all active subscription monthly revenue
* Formula: `SUM(monthly_revenue_usd) WHERE is_active = true`
* Source: rpt_mrr_movements.total_mrr
* Target: Track month-over-month growth
#### MRR Growth Rate
* Definition: Month-over-month percentage change in total MRR
* Formula: `(current_month_mrr - prior_month_mrr) / prior_month_mrr * 100`
* Source: rpt_mrr_movements.mrr_growth_rate
* Benchmark: Health SaaS - 10-20% monthly growth in early stages
#### Churn Rate
* Definition: Percentage of prior month MRR lost to cancellations
* Formula: `churned_mrr / prior_month_mrr * 100`
* Source: rpt_mrr_movements.churn_rate
* Benchmark: Good SaaS <5% monthly churn
#### Customer Lifetime Value (LTV)
* Definition: Total revenue generated by a customer over their lifetime
* Formula: `SUM(monthly_revenue_usd)` for all subscription
* Source: rpt_customer_ltv.ltv
* Use Case: Compare across acquisition channels
#### Average Revenue Per User (ARPU)
* Definition: Average monthly revenue per customer
* Formula: `total_revenue/lifetime_months`
* Source: rpt_customer_ltv.arpu
* Use Cases: Track pricing power and plan mix

### Product Metrics
#### Activation Rate
* Definition: Percentage of users who complete onboarding
* Formula: `SUM(completed_onboarding/COUNT(*))`
* Source: rpt_activation_funnel
* Benchmark: 70%+ is good; 90%+ is excellent
#### Conversion Rate
* Definition: Percentage of users who upgrade to paid
* Formula: `SUM(upgraded)/COUNT(*)`
* Source: rpt_activation_funnel or dim_users
* Benchmark: Varies by product; 2-5% typical for freemium
#### Week 1 Retention
* Definition: Percentage of users active 7 days after signup
* Formula: `active_users_week_1/cohort_size`
* Source: rpt_retention_cohorts.week_1_pct
* Benchmark: 40%+ is good
#### Week 4 Retention
* Definition: Percentage of users active 28 after signup
* Formula: `active_users_week_4/cohort_size`
* Source: rpt_retention_cohorts.week_4_pct
* Benchmark: 20%+ is good
#### Engagement Score
* Definition: 0-100 score based on recency, frequency, and breadth
* Formula: recency (30) + frequency (40) + breadth (30)
* Source: rpt_user_engagement_score.engagement_socre
* Use Case: Identify at-risk users, prioritize outreach

### Experiment Metrics
#### Statistical Significance
* Definition: Confidence that observed difference is real, not random
* Formula: two-proportion z-test, |z| > 1.96 for 95% confidence
* Source: rpt_experiment_results.is_statistically_significant
* Interpretation: Only ship variants with significant results
#### Relative Lift
* Definition: Percentage improvement of variant B over variant A
* Formula: `(b_conversion_rate - a_conversion_rate) / a_conversion_rate * 100`
* Source: rpt_experiment_results.relative_lift_pct
* Interpretation: Measure of business impact

## 5. Analytics Use Cases
**Use Case 1: User Acquisition Analysis**
**Business Question**: Which acquisition channels bring the highest-value customers?
**Model**: `rpt_customer_ltv`
**Analysis Steps**:
1. Group by `acquisition_channel`
2. Calculate average LTV, ARPU, and conversion rate
3. Compare cost per acquisition (CPA) to LTV for ROI
**Sample Query**:
```
select
    acquisition_channel,
    count(*) as customers,
    avg(ltv) as avg_ltv,
    avg(arpu) as avg_arpu,
    avg(lifetime_months) as avg_lifetime,
    sum(ltv) as total_ltv
from rpt_customer_ltv
group by acquisition_channel
order by avg_ltv desc;
```
**Key Insight from Data**: All channels have similar LTV (~$49 ARPU), but paid search shows highest conversion lift in experiments.
**Action**: Invest more in paid search given 13% conversion lift in variant B.

**Use Case 2: Retention Cohort Analysis**
**Business Question**: How does retention differ across signup cohorts? Are we improving?
**Model**: `rpt_retention_cohorts` or `rpt_retention_curves`
**Analysis Steps**:
1. Compare week 1, week 4, and week 12 retention across cohorts
2. Identify trends (improving/declining retention)
3. Investigate cohorts with anomalous retention
**Sample Query**:
```
select
    cohort_week,
    cohort_size,
    week_1_pct,
    week_4_pct,
    week_12_pct
from rpt_retention_cohorts
order by cohort_week desc
limit 12;
```
**Key Insight from Data**:
* Week 1 retention: ~65% (strong)
* Week 4 retention: ~11% (weak)
* 70% drop-off happens between days 14-15
**Action**: Implement engagement campaigns in weeks 2-3 to bridge retention cliff.

**Use Case 3: Feature Adoption**
**Business Question**: Which features drive conversion to paid? How quickly do users need to adopt them?
**Model**: `rpt_feature_adoption` joined with `dim_users`
**Analysis Steps**:
1. Compare conversion rates for users who adopted each feature vs. those who didn't
2. Analyze time-to-adoption (days_to_first_use)
3. Segment by engagement_level
**Sample Query**:
```
with feature_users as (
    select distinct
        user_id,
        feature,
        engagement_level
    from rpt_feature_adoption
)
select
    f.feature,
    f.engagement_level,
    count(distinct f.user_id) as users,
    sum(case when u.is_currently_subscribed then 1 else 0 end) as paid,
    sum(case when u.is_currently_subscribed then 1 else 0 end)::float / count(distinct f.user_id) * 100 as conversion_rate
from feature_users f
left join dim_users u on f.user_id = u.user_id
group by f.feature, f.engagement_level
order by conversion_rate desc;
```
**Key Insight from Data**:
* Onboarding completion drives 5x conversion (25.6% vs. 5.3%)
* 93.7% complete onboarding (high adoption)
* Feature usage is typically one-time only (avg_uses = 1.0)
**Action**: Onboarding is working well; focus on driving repeat feature usage.

**Use Case 4: A/B Testing Analysis**
**Business Question**: Is variant B performing better than variant A? Should we ship it?
**Model**: `rpt_experiment_results` or `rpt_experiment_results_by_channel`
**Analysis Steps**:
1. Check overall conversion rates and lift
2. Review statistical significance
3. Segment by channel to find pockets of significance
4. Decide: ship, kill, or continue testing
**Sample Query**:
```
-- overall results
select
    conversion_event,
    a_conversion_rate,
    b_conversion_rate,
    relative_lift_pct,
    z_score,
    is_statistically_significant,
    winner
from rpt_experiment_results,
order by conversion_event;

--segmented by channel
select
    acquisition_channel,
    conversion_event,
    relative_lift_pct,
    z_score,
    is_statistically_significant
from rpt_experiment_results_by_channel
where conversion_event = 'upgrade'
order by abs(relative_lift_pct) desc;
```
**Key Insights from Data**:
* Overall upgrade lift: 6.1% (not significant, z=1.32)
* Paid search segment: 13% lift (close to significant, z=1.31)
* Need ~40% more users to reach significance
**Action**: Continue experiment or ship variant B to paid search traffic only.

**Use Case 5: Churn Prediction**
**Business Question**: Which users are at risk of churning? How can we intervene?
**Model**: `rpt_user_engagement_score` joined with `dim_users`
**Analysis Steps**:
1. Identify paid users with declining engagement scores
2. Filter for users with high recency (days_since_last_active)
3. Prioritize by MRR value
**Sample Query**:
```
select
    e.user_id,
    u.current_monthly_revenue_usd,
    e.engagement_score,
    e.engagement_tier,
    e.days_since_last_active,
    e.active_days_l30d,
    u.acquisition_channel
from rpt_user_engagement_score e
inner join dim_users u on e.user_id = u.user_id
where u.is_currently_subscribed = true
    nad e.engagement_tier in ('Low Engagement', 'Dormant')
    and u.current_monthly_revenue_usd > 0
order by u.current_monthly_revenue_usd desc, e.days_since_last_active desc;
```
**Key Insight from Data**: 98% of paid users are dormant (data ends in June 2024, measuring from Feb 2026).
**Action**: For live data, reach out to users with:
* Engagement score < 40
* Days since last activee > 14
* High MRR value

## 6. Key Insights from Analysis
### Critical Findings
#### 1. Day 14-15 Retention Cliff
**Finding**: 90% of users churn between day 14-15, right before before the natural conversion windown (day 15-30, median day 24).
**Data**:
* Days 1-14: ~200-350 users active per day
* Day 15+: ~60-90 users active per day (70% drop)
* Users who stay past day 14 convert at 40.5%
* Users who churn before day 14 convert at 4.2%
**Root Cause**: Engagement momentum from onboarding wears off, users haven't formed habits yet.
**Impact**: Losing 70% of potential conversions at the critical moment.
**Recommendations**:
* Add engagement hooks at day 8-10 to bring users back
* Create reasons to return multiple times in week 1 (daily tips, progressive feature unlocks)
* Goal: Get users to 4+ activity days in first 2 weeks

#### 2. Onboarding Completion Drives 5x Conversion
**Finding**: Users who complete onboarding convert at 25.6% vs 5.3% for thos who don't.
**Data**:
* 93.7% onboarding completion rate (excellent)
* Onboarding completers: 25.6% conversion
* Non-completers: 5.3% conversion
* Average time to complete: 1.5 days
**Impact**: Onboarding is a massive conversion driver.
**Recommendations**:
* Maintain current high completion rate
* Continue to optimize onboarding content
* A/B test onboarding variations to push completion higher

#### 3. Users Who Stay Past Day 14 Convert at 40.5%
**Finding**: Retention past day 14 is the #1 predictor of conversion (10x higher rate).
**Data**:
* Retained users (active past day 14): 40.5% paid
* Churned users (inactive by day 14): 4.2% paid
* Only 40% of users make it past day 14
**Key Behaviors of Retained Users**:
* Engage within first 2 days of signup
* Activity spread across 4+ days (not just 1-2 sessions)
* NOT driven by total activity volume
**Impact**: If we can move retention from 40% to 50%, we'd gain ~800 more conversions.
**Recommendations**:
* Send email/push on day 1-2 if user hasn't returned
* Implement day 8-10 re-engagement campaign
* Create daily engagement loops in product

#### 4.Paid Users Retain 18x Better Than Free Users
**Finding**: Paid users show dramatically better retention, suggesting strong product-market fit for paying segment.
**Data**:
* Paid users at week 4: 30% retention
* Free users at week 4: 1.6% retention
* Week 1 retention is identical (~50%) for both groups
* Divergence happens in weeks 2-4
**Interpretation**:
* Paying doesn't help early retention
* But paying dramtically improves long-term engagement
* Free tier doesn't provide sufficient value for retention
**Recommendations**:
* Accelerate conversion timeline (move from day 24 median to day 10-14)
* Add usage limits or time-based trials to create urgency
* Test conversion prompts at day 10-14 window

#### 5.Paid Search Shows 13% Lift in Variant B
**Finding**: Variant B shows strong performance in paid search segment, though overall results aren't significant yet.
**Data**:
* Overall upgrade conversion lift: 6.1% (z=1.32, not significant)
* Paid search segment: 13% lift (z=1.31, close to significant)
* Need ~40% more data to reach significance
* All other channels show positive but smaller lifts
**Power Analysis**:
* Current: ~2,200 users per variant
* Needed for 13% lift: ~3,500-4,000 users per variant
* Progress: 60% of the way there
**Recommendations**:
* Option A: Continue experiment for 5-7 more weeks
* Option B: Ship variant B to paid search traffic only (targeted deployment)
* Option C: Ship everywhere based on consistent positive trend

## 7.Looker Implementation
### Setup Instruction
#### 1. Configure Database Connection
* Open Looker Admin -> Connections
* Create new connection for DuckDB
* Name it appropriately (e.g. "saas_duckdb")
* Test connection

#### 2. Create New Project
* Navigate to Develop -> Projects
* Create new project: "saas_analytics"
* Initialize Git repository

#### 3. Upload LookML Files
* Upload `saas_analytics.model.lkml` to project root
* Create `/views` folder
* Upload `.view.lkml` files to `/views`

#### 4. Update Connection Name
* In `saas_analytics.model.lkml`, line 1:
* Change `connection: "your_duckdb_connection"` to your actual connection name

#### 5. Validate & Deploy
* Run LookML validator
* Fix any errors
* Commit changes
* Deploy to production

#### 6. Create Dashboards
* Use explores to build visualizations
* Save to folders (Executive, Product, Growth, etc.)

### Available Explores
**Core Analytics**:
* Users : User dimension with lifecycle analysis and event drill-downs
* Events: Behavioral analytics, feature usage, conversion funnels

**Revenue Analytics**:
* MRR Movements: Monthly growth accounting (new, expansion, contraction, churn)
* Customer LTV: Lifetime value by cohort and acquisition channel

**Product Analytics**:
* Feature Adoption: Feature usage patterns, adoption timing, engagement levels
* Activation Funnel: User progression through activation milestones
* User Engagement: Engagement scoring (0-100) and activity metrics

**Retention Analytics**:
* Retention Cohorts: Classic cohort table (weeks 0-12)
* Retention Curves: Time-series retention for charting

**Experiment Analytics**:
* A/B Test Results: Overall experiment performace
* A/B Test Results by Channel: Segmented analysis

### Recommended Dashboards
#### Executive Dashboard
**Purpose**: High-level business metrics for leadership
**Tiles**:

* MRR over time (line chart)
* MRR waterfall (monthly new, expansion, contraction, churn)
* Customer count by lifecycle stage (pie chart)
* Conversion funnel (bar chart showing drop-off at each step)
* Churn rate trend (line chart)
* LTV by acquisition channel (bar chart)

**Filters**: Date range, acquisition channel

#### Product Dashboard
**Purpose**: User engagement and feature adoption
**Tiles**:

* DAU/WAU/MAU trends (line chart)
* Feature adoption rates (bar chart)
* Engagement score distribution (histogram)
* Retention curves by cohort (line chart)
* Days to key milestones (box plot)
* Top events by unique users (table)

**Filters**: Date range, cohort, acquisition channel

#### Growth Dashboard
**Purpose**: Acquisition, activation, and conversion
**Tiles**:

* New signups over time (line chart)
* Signups by acquisition channel (stacked area chart)
* Activation funnel (funnel visualization)
* Conversion rate by channel (bar chart)
* Time to activation/conversion (histogram)
* LTV by cohort month (heatmap)

**Filters**: Date range, acquisition channel, cohort

#### Experiment Dashboard
**Purpose**: A/B test monitoring and decision-making
**Tiles**:

* Experiment results table (conversion_event, lift, significance)
* Sample size progress (gauge)
* Lift by channel (grouped bar chart)
* Conversion rates A vs B (comparison chart)
* Confidence intervals (error bar chart)

**Filters**: Experiment variant, conversion event

## 8.Maintenance & Best Practices
### Daily Operations
#### dbt Runs:
```
#full refresh (all models)
dbt run

#run with tests
dbt run && dbt test

#run specific marts
dbt run --select marts.revenue
dbt run --select marts.product
```
### Monitoring:
* Check for test failures: `dbt test`
* Review logs for errors
* Monitor query performance in DuckDB

#### Weekly Tasks
1. Review Key Metrics
* MRR growth rate and churn
* Week 1 and week 4 retention trends
* Conversion rate changes
2. Experiment Monitoring
* Update experiment results (if tests are running)
* Check for statistical significance
* Review segmented results
3. Data Quality
* Run `dbt test --select source:*` to validate source data
* Check for unexpected null values
* Verify row counts haven't dropped significantly

#### Monthly Tasks
1. Performance Review
* LTV trends by acquisition channel
* Feature adoption rates
* Cohort retention comparison
2. Model Optimization
* Review slow-running models
* Add indexes if needed
* Consider incremental models for large tables
3. Documentaion Updates
* Update .yml files for new models
* Document new metrics in this guide
* Update LookML descriptions

#### Best Practices
**dbt Development**:
* Always user `{{ ref() }}` for model references
* Add tests for all primary keys
* Document models and metrics in .yml files
* Use consistent naming (dim_, fct_, rpt_)
* Keep staging as views, marts as tables
* Add `description` to all dbt models
**SQL Best Practices**:
* Use CTEs for complex queries (improve readability)
* Add comments for business logic
* Filter early, aggregate late,
* Use explicit JOINs (not comma joins)
* Qualify all columns names in JOINs
**LookML Best Practices**:
* Group related dimensions/measures
* Add descriptions to all fields
* Use value_format_name for consistent formatting
* Hide technical fields (foreign keys)
* Add drill_fields for exploration
**Version Control**:
* Commit after each logical change
* Use descriptive commit messages
* Create branches for major changes
* Code review before merging to main

## Appendix A: Model Lineage
### Data Flow Diagram
```
Raw Sources
├── raw_users
├── raw_events
└── raw_subscriptions
        ↓
Staging Layer (views)
├── stg_users
├── stg_events
└── stg_subscriptions
        ↓
Core Marts (tables)
├── dim_users
├── fct_events
└── fct_user_activity_by_date
        ↓
Domain Marts (tables)
├── Revenue
│   ├── fct_mrr_by_month
│   ├── rpt_mrr_movements
│   └── rpt_customer_ltv
│
├── Product
│   ├── rpt_feature_adoption
│   ├── rpt_activation_funnel
│   └── rpt_user_engagement_score
│
├── Retention
│   ├── rpt_retention_cohorts
│   └── rpt_retention_curves
│
└── Experiments
    ├── fct_experiment_assignments
    ├── fct_experiment_conversions
    ├── rpt_experiment_results
    └── rpt_experiment_results_by_channel
```
### Model Dependencies
#### dim_users depends on:
* stg_users
* stg_events
* stg_subscriptions

#### fct_events depends on:
* stg_events
* stg_users
* stg_subscriptions

#### rpt_mrr_movements depends on:
* fct_mrr_by_month → stg_subscriptions

#### rpt_retention_cohorts depends on:
* fct_user_activity_by_date → stg_events + stg_users

#### rpt_experiment_results depends on:
* fct_experiment_conversions → fct_experiment_assignments → stg_events


## Appendix B: Glossary

ARPU - Average Revenue Per User. Total revenue divided by lifetime months. Measures pricing power.
Churn - When a paying customer cancels their subscription. Can be measured as customer churn (count) or revenue churn (MRR).
Cohort - A group of users who signed up in the same time period (week or month). Used for retention analysis.
Conversion Rate - Percentage of users who complete a desired action (e.g., upgrade to paid).
DAU/WAU/MAU - Daily/Weekly/Monthly Active Users. Standard engagement metrics.
dbt - Data Build Tool. SQL-based transformation tool for building data warehouses.
Dimension Table - Contains descriptive attributes about entities (users, products). One row per entity.
Fact Table - Contains measurable events or transactions. Many rows per entity (e.g., one per event).
LookML - Looker Modeling Language. Used to define dimensions, measures, and explores in Looker.
LTV - Lifetime Value. Total revenue generated by a customer over their entire relationship.
Mart - A collection of related fact and dimension tables organized around a business process (revenue, product, etc.).
MRR - Monthly Recurring Revenue. Predictable monthly subscription revenue. Key SaaS metric.
Retention Rate - Percentage of users from a cohort still active after a time period.
Statistical Significance - Confidence that an observed difference is real, not due to random chance. Typically 95% threshold (p < 0.05).
Z-Score - Test statistic measuring how many standard deviations an observation is from the mean. |z| > 1.96 indicates 95% significance.
---------------------------------------------------------------------------------------------------------------------------------------
**Document Version**: 1.0
**Last Updated**: Feb. 2026
**Author**: Hazel Donaldson
**Contact**: hazel90.hd@gmail.com