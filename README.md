# E-Commerce Funnel Optimization: Data-Driven Conversion Analysis

### **Overview**
This project analyzes over **500,000 user events** from a multi-category e-commerce store to identify **conversion bottlenecks** and propose **data-driven strategies** to increase revenue.

>  **Key Insight:** 40% of users who add items to their cart abandon without purchasing — a $204,000 revenue opportunity.  
> By implementing targeted cart abandonment strategies, the company could increase conversions by **25%**.

---

## Executive Summary

- Built with **Python (pandas, scikit-learn, seaborn)**, **SQL**, and **Tableau**.
- Performed funnel, cohort, and predictive analyses to identify and quantify conversion drivers.
- Modeled user purchase behavior using **logistic regression (93% accuracy, 0.87 ROC-AUC)**.
- Simulated multiple **A/B testing strategies** to estimate potential revenue lift.

---

## Business Objectives

The analysis addresses four key questions:
1. Where do users drop off in the purchase funnel?
2. What factors predict whether a user completes a purchase?
3. Which customer segments have the highest conversion potential?
4. What interventions can most effectively increase revenue?

---

## Skills & Methodology

### Data Engineering
- Extracted and cleaned 500K+ event records.
- Transformed raw logs into structured funnel stages.
- Aggregated data at the user level using **SQL-style queries**.
- Created time-based and behavioral features.
- Handled missing data (32% in category codes, 15% in brand names).

### Data Analytics
- Calculated funnel conversion rates for each stage.
- Performed **cohort analysis** to identify temporal patterns.
- Measured drop-off and retention rates to isolate key friction points.

### Statistical Modeling
- Trained **logistic regression** to predict purchase probability.
- Achieved **93% accuracy** and **0.87 ROC-AUC**.
- Identified key features influencing purchase behavior.
- Conducted feature importance and coefficient analysis.

### A/B Testing & Experimentation
- Simulated five intervention strategies.
- Conducted **chi-square significance testing**.
- Estimated **expected lift** and **revenue impact** for each scenario.

### Data Visualization
- Built interactive dashboards in **Tableau**.
- Created funnel, cohort, and trend charts for executive insights.

---

## Results & Insights

### Funnel Performance
- Overall conversion rate: **10.35%**
- Cart-to-purchase conversion: **60.12%**
- Cart abandonment rate: **39.88%** → Primary revenue leakage point.
<img width="907" height="298" alt="my screenshots 2025-10-23 at 11 28 12 AM" src="https://github.com/user-attachments/assets/129fbb25-07c0-4f15-8a7e-505786f6ec6e" />

### Machine Learning Performance
- Accuracy: **93%**
- ROC-AUC: **0.866**
- Top predictor: **Cart addition (coef = 2.68)** → users are **14.5× more likely** to purchase after adding to cart.
<img width="635" height="390" alt="my screenshots 2025-10-23 at 11 34 39 AM" src="https://github.com/user-attachments/assets/64774498-cf9e-45bb-a30b-f8de7cc46511" />

### Cohort Insights
- **Electronics** (esp. smartphones): 13.9% conversion.
- **Unknown/uncategorized products**: 3.2% conversion.
- Users visiting between **9 AM–12 PM** convert **18% better** than others.
<img width="952" height="651" alt="my screenshots 2025-10-23 at 11 28 01 AM" src="https://github.com/user-attachments/assets/6b71da78-1c50-46c1-8e0b-788914e1aaa5" />

### High-Value User Identification
- Identified **1,328 users** with ≥65% purchase probability who haven’t converted.
- Represent **immediate retargeting potential**.
<img width="927" height="306" alt="my screenshots 2025-10-23 at 11 24 57 AM" src="https://github.com/user-attachments/assets/83039417-07a9-4d89-b27d-17ddb7696039" />

---

## Business Impact

| Strategy | Expected Lift | Revenue Impact |
|-----------|----------------|----------------|
| Limited-Time Discount | +25% | $204,147 |
| Free Shipping Offer | +22% | $179,490 |
| Cart Abandonment Email | +15% | $122,311 |
| Simplified Checkout | +12% | $97,849 |

> Implementing time-sensitive discounts and abandonment emails could increase revenue by over **$200K** in the next campaign cycle.

---

## Strategic Recommendations

### Immediate (Weeks 1–2)
- Launch **cart abandonment email** to the 1,328 high-probability users.
- Run an **A/B test** for limited-time discount offers on high-value categories.

###  Short-Term (Months 1–3)
- Reduce **choice overload** with improved product filtering.
- Optimize ad spend for **9 AM–12 PM** conversion window.

### Long-Term (Quarter 2+)
- Deploy logistic regression as a **real-time scoring model**.
- Automate user retargeting and re-train the model periodically.
- Focus on **category-specific** marketing for high-converting segments.

---

## Next Steps

### Validate Findings
- Extend analysis to more months (e.g., Oct & Dec).
- Segment by **device type** and **customer type** (new vs. returning).

### Production Implementation
- Automate daily funnel tracking.
- Build a real-time Tableau dashboard for business stakeholders.
- Deploy model as an API for live predictions.

### Advanced Analytics
- Add **customer lifetime value (CLV)** and **multi-touch attribution**.
- Introduce **time-series forecasting** for demand and inventory planning.

---
## 🛠️ Technologies Used

**Languages & Libraries**
- Python 3.x — pandas, numpy, scikit-learn, matplotlib, seaborn  
- SQL (PostgreSQL + MySQL syntax)

**Tools**
- Jupyter Notebook for analysis  
- Tableau for dashboards and visual storytelling

**Statistical Methods**
- Logistic Regression  
- Chi-Square Significance Testing  
- Cohort Analysis  
- A/B Test Simulation
