---
title: "Hydration, Fluid Deficit Kinetics, and Clinical Dehydration Grading"
doc_type: "synthesis"
track: "verisimilitude"
origin: "AI synthesized"
epistemic_status:
  confidence: "high"
  audited_by: "Gemini 3.8 Flash (Antigravity)"
  vetted_by_human: false
  vetting_notes: "Grounded in peer-reviewed clinical pathophysiology from StatPearls (Singh & Tripathi 2023), military nutritional and operational physiology (CMNR 1994), and ancient logistics benchmarks (Roth 1999)."
related_files:
  - "design/research/synthesis/hardship-and-exertion.md"
  - "design/research/synthesis/physical-harm-and-trauma.md"
  - "design/research/synthesis/consequences-exploration.md"
  - "design/research/reports/functional-decline-under-physical-hardship/report.md"
vault_sources:
  - "design/research/sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology"
  - "design/research/sources/verisimilitude/the-2021-brief-history-of-shigella"
  - "design/research/sources/verisimilitude/roth-1999-logistics-roman-army"
  - "design/research/sources/verisimilitude/cmnr-1994-food-components-performance"
---

# Hydration, Fluid Deficit Kinetics, and Clinical Dehydration Grading

## Executive Summary: Physiological Fluid Balance and Compartmental Dynamics

Water constitutes the primary physical solvent and thermodynamic medium of human physiology, comprising **55% to 65% of total body mass** in healthy adults (~60% average, or **42.0 liters** in a reference 70 kg individual) [^statpearls-tbw-compartments]. This total body water (TBW) is distributed across two major fluid compartments separated by semipermeable cell membranes:

1. **Intracellular Fluid (ICF):** Contains **two-thirds ($\approx 66.7\%$) of TBW** (~28.0 L in a 70 kg human), residing within the cell cytoplasm and maintained by active ion transporters (primarily $\text{Na}^+/\text{K}^+$-ATPase pumps) [^statpearls-tbw-compartments].
2. **Extracellular Fluid (ECF):** Contains **one-third ($\approx 33.3\%$) of TBW** (~14.0 L in a 70 kg human). The ECF is further divided into:
   - **Interstitial Fluid:** Four-fifths ($\approx 80\%$) of ECF (~11.2 L), bathing non-vascular tissue parenchyma.
   - **Intravascular Space (Plasma Volume):** One-fifth ($\approx 20\%$) of ECF (~2.8 to 3.0 L), maintaining circulating blood volume and cardiac filling pressures [^statpearls-tbw-compartments].

```
+----------------------------------------------------------------------------------------------------+
|                                TOTAL BODY WATER ARCHITECTURE (70 kg Adult: ~42.0 L)               |
+----------------------------------------------------+-----------------------------------------------+
| INTRACELLULAR FLUID (ICF): ~28.0 L (66.7% of TBW) | EXTRACELLULAR FLUID (ECF): ~14.0 L (33.3%)     |
| Maintained by Na+/K+-ATPase; osmotic buffer       +-----------------------+-----------------------+
|                                                    | INTERSTITIAL: ~11.2 L | INTRAVASCULAR: ~2.8 L |
|                                                    | (80% of ECF)          | (20% of ECF; Plasma)  |
+----------------------------------------------------+-----------------------+-----------------------+
```

### Distinction: Dehydration vs. Volume Depletion (Hypovolemia)

In clinical pathophysiology, a vital distinction exists between pure water loss and circulating volume contraction [^statpearls-volume-depletion]:

- **Dehydration (Cellular Hypohydration):** A deficit of total body water relative to solute, characterized by hypertonicity and hypernatremia, which pulls water osmotically out of the intracellular space, causing cellular shrinkage.
- **Hypovolemia (Extracellular Volume Depletion):** Loss of sodium and water from the extracellular compartment (specifically the intravascular space), reducing effective circulating arterial volume, compromising cardiac preload, and triggering baroreceptor reflexes [^statpearls-volume-depletion].
- **Coexistence:** In strenuous wilderness traversal, prolonged marches, environmental heat stress, or infectious gastroenteritis, cellular dehydration and intravascular hypovolemia routinely coexist [^statpearls-volume-depletion].

### Mathematical Fluid Deficit Calculations

Fluid deficit is quantified clinically through two primary mathematical models:

1. **Percent Body Mass Deficit ($\% \Delta BM$):**
   $$\% \Delta BM = \left(\frac{M_{\text{baseline}} - M_{\text{current}}}{M_{\text{baseline}}}\right) \times 100$$
   Because acute mass changes over hours to days reflect fluid loss rather than adipose or lean tissue catabolism, each $1.0\text{ kg}$ of acute body weight loss represents approximately $1.0\text{ liter}$ of net water deficit.

2. **Free Water Deficit ($FWD$) in Hypernatremic Dehydration:**
   $$FWD = TBW_{\text{baseline}} \times \left(1 - \frac{140}{[\text{Na}^+]_{\text{serum}}}\right)$$
   Where $TBW_{\text{baseline}} = 0.60 \times \text{Body Weight (kg)}$ (or $0.50 \times \text{Weight}$ in elderly or higher-adiposity individuals). This formula determines the liters of pure water required to restore serum sodium concentration back to the normal baseline of $140\text{ mEq/L}$.

3. **Total Body Water Deficit ($\% \Delta TBW$):**
   $$\% \Delta TBW = \frac{\text{Fluid Deficit (L)}}{TBW_{\text{baseline}} (L)} \times 100 \approx \frac{\% \Delta BM}{0.60}$$
   A 2% total body mass loss corresponds to an approximate **3.3% deficit in total body water**, whereas a 6% body mass loss represents a severe **10.0% deficit in total body water**.

---

## 1. Master Clinical Dehydration Grading Spectrum

Dehydration progresses along a continuous physiological spectrum categorized clinically into four discrete severity brackets based on acute body mass deficit, hemodynamic compensation, and central nervous system (CNS) involvement [^statpearls-clinical-grading, ^statpearls-prognosis-severity].

### Master Quantitative Reference Table

| Clinical Bracket                | Body Mass Deficit | TBW Deficit (70 kg adult) | Net Fluid Deficit (L)  | Serum Osmolality ($\text{mOsm/kg}$) | Serum $\text{Na}^+$ ($\text{mEq/L}$) | Compensatory Markers (Urine, BUN:Cr)                                                                                                                                          | Primary Physiological & Functional Manifestations                                                                                                                                                                                                                                                                                                                                                                 | Clinical Recovery Protocol & Timeline                                                                                                                                                                                             | Primary Evidence Anchors                                                                            |
| :------------------------------ | :---------------: | :-----------------------: | :--------------------: | :---------------------------------: | :----------------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------- |
| **Mild (Class I)**              |  **1.0 – 2.0%**   |      **1.7 – 3.3%**       |    **0.7 – 1.4 L**     |         $295\text{ – }300$          |          $140\text{ – }145$          | Urine Osm $>450\text{ mOsm/kg}$; $\text{SG} > 1.020$; $\text{BUN:Cr} < 20:1$; Urine output $\ge 0.5\text{ mL/kg/h}$.                                                          | Pronounced thirst, dry oral mucosa, mild fatigue. Cognitive reaction time slows by 12–18%; working memory and vigilance degrade ([functional decline report](file:///home/tdimiduk/cardpg/cardpg/design/research/reports/functional-decline-under-physical-hardship/report.md#L170)). Cardiorespiratory vitals remain compensated at rest; thermoregulation begins degrading [^cmnr-1994-dehydration-thresholds]. | Oral rehydration: 1.0–2.0 L fresh water or standard fluids over 1–4 hours; full functional normalization within 12–24 hours [^statpearls-ort-dose].                                                                               | [^statpearls-osmolality-thresholds], [^cmnr-1994-dehydration-thresholds]                            |
| **Moderate (Class II)**         |  **3.0 – 5.0%**   |      **5.0 – 8.3%**       |    **2.1 – 3.5 L**     |         $301\text{ – }310$          |          $146\text{ – }150$          | Urine Osm $>600\text{ – }800\text{ mOsm/kg}$; $\text{SG} > 1.025$; $\text{BUN:Cr} > 20:1$; Oliguria ($<0.5\text{ mL/kg/h}$); Urine $\text{Na}^+ < 20\text{ mEq/L}$.           | Physical aerobic capacity and endurance decline by ~20% ([functional decline report](file:///home/tdimiduk/cardpg/cardpg/design/research/reports/functional-decline-under-physical-hardship/report.md#L171), [^cmnr-1994-dehydration-thresholds]). Resting and exertional tachycardia (+15–25 bpm); orthostatic hypotension upon standing; dizziness, headache, irritability, skeletal muscle cramping.           | Oral Rehydration Therapy (ORT) with balanced electrolyte solutions (reduced-osmolarity ORS) or IV isotonic crystalloids; 2.0–4.0 L over 12–24 hours in cool shade [^statpearls-ort-mechanisms].                                   | [^statpearls-physical-signs], [^statpearls-bun-cr], [^cmnr-1994-dehydration-thresholds]             |
| **Severe (Class III)**          |  **6.0 – 9.0%**   |     **10.0 – 15.0%**      |    **4.2 – 6.3 L**     |         $311\text{ – }325$          |          $151\text{ – }160$          | Intense oliguria ($<0.3\text{ mL/kg/h}$); Urine Osm $>800\text{ mOsm/kg}$; $\text{BUN:Cr} > 25:1\text{ to }30:1$; Serum lactate $1.5\text{ – }2.5\text{ mmol/L}$.             | Medical emergency. Drastically hampers physical performance and triggers severe heat injury risk [^cmnr-1994-dehydration-thresholds]. Severe intravascular depletion; resting tachycardia ($>110\text{ bpm}$); supine hypotension; profound postural syncope; loss of skin turgor; sunken eyes; delayed capillary refill ($>3\text{ s}$); cessation of sweating; delirium, confusion, lethargy; non-ambulatory.   | Intensive clinical resuscitation: 4.0–6.0 L IV isotonic crystalloids / hypotonic saline; slow sodium reduction; absolute rest for 24–72 hours [^statpearls-iv-fluids].                                                            | [^statpearls-physical-signs], [^statpearls-prognosis-severity], [^cmnr-1994-dehydration-thresholds] |
| **Critical / Shock (Class IV)** | **$\ge 10.0\%$**  |      **$> 16.7\%$**       | **$\ge 7.0\text{ L}$** |               $> 325$               |               $> 160$                | Anuria ($<5\text{ mL/h}$); acute kidney injury (ATN); metabolic acidosis ($\text{pH} < 7.20$); serum lactate $> 3.0\text{ – }4.0\text{ mmol/L}$; IVC collapsibility $> 50\%$. | Decompensated hypovolemic shock. Weak, thready pulse; undetectable postural blood pressure; cool, clammy extremities; seizures, stupor, coma; multi-organ failure. Untreated hypernatremia at this tier carries up to 50% mortality [^statpearls-hypernatremia-mortality].                                                                                                                                        | Emergency IV central venous resuscitation; aggressive fluid volume expansion followed by controlled osmolar lowering; intensive critical care. Rarely survivable in primitive wilderness without advanced medical infrastructure. | [^statpearls-hypernatremia-mortality], [^statpearls-ivc-collapse], [^statpearls-physical-signs]     |

---

## 2. Fluid Loss Etiology and Hourly Flux Dynamics

Body water is continuously lost through four obligatory physiological pathways: the skin (cutaneous), lungs (respiratory), kidneys (renal), and gastrointestinal (GI) tract [^statpearls-etiology-obligatory]. Dehydration ensues whenever cumulative water loss across these avenues exceeds fluid replenishment [^statpearls-etiology-obligatory].

### The Three Pathophysiological Types of Dehydration

Dehydration manifests biochemically in three distinct forms depending on the ratio of free water to sodium lost [^statpearls-three-types]:

```
+----------------------------------------------------------------------------------------------------+
|                               ETIOLOGICAL TAXONOMY OF DEHYDRATION                                  |
+----------------------+--------------------+---------------------+----------------------------------+
| Type                 | Water vs. Solute   | Primary Etiology    | Pathophysiological Cascade       |
|                      | Loss Ratio         |                     | & Diagnostic Markers             |
+----------------------+--------------------+---------------------+----------------------------------+
| Isotonic             | Water = Sodium     | Secretory Diarrhea, | Extracellular volume contraction |
| Dehydration          | (Proportional)     | Vomiting, Acute     | without osmolar shift. Marked    |
|                      |                    | Hemorrhage          | hypovolemia, normal serum Na+.   |
+----------------------+--------------------+---------------------+----------------------------------+
| Hypertonic           | Water Loss >       | Water Deprivation,  | Hypernatremia (>145 mEq/L);      |
| Dehydration          | Sodium Loss        | Heavy Sweating,     | Serum Osm >300 mOsm/kg. Draws    |
|                      | (Free Water)       | Osmotic Diuresis    | water from cells -> CNS collapse |
+----------------------+--------------------+---------------------+----------------------------------+
| Hypotonic            | Sodium Loss >      | Diuretic Overuse,   | Hyponatremia (<135 mEq/L);       |
| Dehydration          | Water Loss         | Salt-Wasting Renal  | Fluid shifts intracellularly ->  |
|                      | (Electrolytes)     | Disease, Adrenal    | Cerebral edema, muscle weakness. |
+----------------------+--------------------+---------------------+----------------------------------+
```

1. **Isotonic Dehydration:** Water and electrolytes are shed in equimolar proportions [^statpearls-three-types]. Intravascular and interstitial volumes contract while plasma osmolality remains normal ($285\text{–}295\text{ mOsm/kg}$) [^statpearls-three-types]. Because serum sodium does not rise, this condition evades osmolar detection tests and presents primarily with cardiovascular hypovolemia (tachycardia, delayed capillary refill, orthostatic drop) [^statpearls-three-types].
2. **Hypertonic Dehydration:** Free water loss surpasses sodium loss, elevating extracellular sodium ($[\text{Na}^+] > 145\text{ mEq/L}$) and plasma osmolality ($> 300\text{ mOsm/kg}$) [^statpearls-three-types]. The resulting transcellular osmotic gradient draws water out of body cells into the hypertonic extracellular space, causing cellular dehydration and shrinking brain neurons, leading directly to acute confusion, delirium, seizures, and hyperpyrexia [^statpearls-three-types].
3. **Hypotonic Dehydration:** Solute (sodium) loss exceeds water loss ($[\text{Na}^+] < 135\text{ mEq/L}$), driving water out of the hypotonic extracellular fluid and into cells [^statpearls-three-types]. This produces intracellular edema—most dangerously cerebral edema—alongside rapid extracellular hypovolemic shock, presenting with severe lethargy, muscle weakness, and intractable headaches [^statpearls-three-types].

### Hourly Fluid Flux Rates Across Environmental and Traversal Regimes

```
+----------------------------------------------------------------------------------------------------+
|                               HOURLY FLUID FLUX BUDGET (70 kg Adult)                               |
+-----------------------+--------------------+---------------------+---------------------------------+
| Traversal / Metabolic | Environmental      | Hourly Sweating &   | 8-Hour Fluid Deficit            |
| Condition             | Temperature        | Evaporative Flux    | Without Intake                  |
+-----------------------+--------------------+---------------------+---------------------------------+
| Basal Resting         | Temperate (20°C)   | 0.04 – 0.06 L/h     | 0.35 – 0.50 L (Mild)            |
| Sustained March       | Moderate (20–25°C) | 0.50 – 0.80 L/h     | 4.00 – 6.40 L (Moderate-Severe) |
| Loaded Combat March   | Warm (28–32°C)     | 1.00 – 1.50 L/h     | 8.00 – 12.0 L (Critical Shock)  |
| Extreme Desert March  | Hot Arid (>38°C)   | 1.50 – 2.50 L/h     | Lethal within 4 to 6 hours      |
| Infectious Dysentery  | Resting / Febrile  | 0.30 – 1.00 L/h     | 2.40 – 8.00 L (Severe to Shock) |
+-----------------------+--------------------+---------------------+---------------------------------+
```

#### Detailed Avenue Analysis:

1. **Cutaneous Evaporative Flux:**
   - **Insensible Transepidermal Diffusion:** 300 to 500 mL/day (~15 to 20 mL/h) of continuous solute-free water loss through non-sweating stratum corneum.
   - **Thermoregulatory Sweating:** Activated by preoptic hypothalamic thermoreceptors during muscular work and elevated ambient heat. Sweat is inherently hypotonic ($[\text{Na}^+] \approx 20\text{–}60\text{ mEq/L}$, compared to plasma $140\text{ mEq/L}$). Unreplaced sweating therefore drives **hypertonic dehydration**.
     - _Light work / gentle stroll (2–3 METs, $20^\circ\text{C}$):_ 0.20 to 0.40 L/h.
     - _Standard wilderness march (4–5 METs, 15 kg pack, $22^\circ\text{C}$):_ 0.50 to 0.80 L/h.
     - _Heavy tactical march / combat drills (6–8 METs, 25 kg pack or armor, $28^\circ\text{C}$):_ 1.00 to 1.50 L/h.
     - _Maximum human sweating ceiling ($>35^\circ\text{C}$, direct radiant heat):_ 2.00 to 2.50 L/h (up to 12 to 15 L/day).
2. **Respiratory Evaporative Flux:**
   - Inhaled air is warmed to $37^\circ\text{C}$ and humidified to 100% relative humidity within upper respiratory pathways; expired air carries water vapor into the atmosphere.
   - _Basal respiration:_ 300 to 400 mL/day (~15 mL/h).
   - _Exertional hyperventilation:_ High minute ventilation ($V_E > 60\text{ L/min}$) in cold, dry alpine or arid environments elevates respiratory water loss to **80 to 150 mL/h**.
3. **Renal Obligatory and Regulatory Flux:**
   - To clear the normal metabolic solute load of urea, creatinine, and electrolytes (~600 to 900 mOsm/day), the human kidney must excrete a **minimum obligatory urine volume of approximately 500 mL/day** (~20 mL/h, representing maximally concentrated urine at ~1,200 mOsm/kg) [^statpearls-urine-volume].
   - _Euvolemic baseline output:_ $\ge 0.5\text{ to }1.0\text{ mL/kg/h}$ (~35 to 70 mL/h for a 70 kg human) [^statpearls-urine-output-target].
   - _Compensated dehydration (Oliguria):_ Downregulation to 15 to 30 mL/h as antidiuretic hormone (ADH/vasopressin) inserts aquaporin-2 water channels into the collecting duct [^statpearls-adh-raas].
   - _Decompensated dehydration (Anuria):_ Cessation of filtration ($<5\text{ mL/h}$) due to prerenal hypoperfusion and drop in glomerular filtration rate (GFR).
4. **Gastrointestinal Pathological Flux:**
   - Normal fecal water excretion is minimal: 100 to 200 mL/day.
   - *Secretory Dysentery / Enteritis (*Shigella*, Cholera):* Microbial enterotoxins stimulate cyclic adenosine monophosphate (cAMP) and active chloride/fluid secretion into the intestinal lumen, causing copious secretory diarrhea of **200 to 1,000+ mL/h** (up to 5 to 15 L/day in severe bacillary dysentery), precipitating Class III/IV dehydration within 12 to 24 hours [^statpearls-three-types, ^the-2021-shigella-dysentery].
   - _Acute Emesis:_ Vomiting results in loss of 100 to 300 mL per episode alongside gastric hydrochloric acid, inducing hypokalemic, hypochloremic metabolic alkalosis [^statpearls-lab-evaluation].

---

## 3. Plasma Osmolar and Biochemical Thresholds

The diagnostic and physiological state of dehydration is mapped clinically via serum and urinary biomarkers, providing hard quantitative thresholds for bodily decompensation [^statpearls-lab-evaluation].

```
+----------------------------------------------------------------------------------------------------+
|                               MASTER BIOCHEMICAL THRESHOLD MATRIX                                  |
+--------------------+--------------------+--------------------+-------------------------------------+
| Diagnostic Marker  | Normal Reference   | Dehydration        | Clinical Pathophysiological         |
|                    | Range              | Threshold          | Significance                        |
+--------------------+--------------------+--------------------+-------------------------------------+
| Serum Osmolality   | 275 – 295 mOsm/kg  | > 295 mOsm/kg      | Impending dehydration               |
|                    |                    | > 300 mOsm/kg      | Current overt dehydration; poor     |
|                    |                    |                    | prognosis marker [^statpearls-lab-evaluation, ^statpearls-poor-prognosis]   |
+--------------------+--------------------+--------------------+-------------------------------------+
| Serum Sodium       | 135 – 145 mEq/L    | > 145 mEq/L        | Hypernatremic / hypertonic state    |
| ([Na+])            |                    | > 160 mEq/L        | Extreme hypernatremia; 50%          |
|                    |                    |                    | mortality risk untreated [^statpearls-hypernatremia-mortality]          |
+--------------------+--------------------+--------------------+-------------------------------------+
| Urine Osmolality   | 300 – 500 mOsm/kg  | > 450 mOsm/kg      | Renal water conservation response   |
|                    |                    | >= 800 mOsm/kg     | Epidemiological criterion for overt |
|                    |                    |                    | dehydration (NHANES) [^statpearls-nhanes, ^statpearls-lab-evaluation]               |
+--------------------+--------------------+--------------------+-------------------------------------+
| Urine Specific     | 1.005 – 1.015      | > 1.020            | Concentrated solute excretion;      |
| Gravity (SG)       |                    |                    | elevated tubular reabsorption [^statpearls-lab-evaluation]     |
+--------------------+--------------------+--------------------+-------------------------------------+
| BUN:Creatinine     | 10:1 – 15:1        | > 20:1             | Prerenal azotemia; proximal tubular |
| Ratio              |                    |                    | urea reabsorption via ADH [^statpearls-bun-cr]         |
+--------------------+--------------------+--------------------+-------------------------------------+
| Fractional Excret. | 1.0 – 2.0%         | < 1.0%             | Intense aldosterone-mediated renal  |
| of Sodium (FENa)   |                    |                    | sodium avidity [^statpearls-lab-evaluation]                    |
+--------------------+--------------------+--------------------+-------------------------------------+
| Serum Lactate      | 0.5 – 1.5 mmol/L   | > 2.0 mmol/L       | Systemic tissue hypoperfusion;      |
|                    |                    |                    | impending hypovolemic shock [^statpearls-lab-evaluation]       |
+--------------------+--------------------+--------------------+-------------------------------------+
| Inferior Vena Cava | 1.5 – 2.5 cm;      | < 2.1 cm with      | Marked intravascular volume         |
| (IVC) Diameter     | < 50% collapse     | > 50% inspiratory  | contraction; low right atrial       |
|                    |                    | collapse           | filling pressure [^statpearls-ivc-collapse]                   |
+--------------------+--------------------+--------------------+-------------------------------------+
| Salivary Osmolal.  | 50 – 70 mOsm/kg    | > 93 mOsm/kg       | Sensitive non-invasive marker for   |
|                    |                    |                    | hypertonic & isotonic deficit [^statpearls-salivary-osm]     |
+--------------------+--------------------+--------------------+-------------------------------------+
```

### Neuroendocrine Regulatory Cascade

When fluid loss occurs, the body activates three homeostatic feedback loops [^statpearls-adh-raas]:

1. **Hypothalamic Osmoreceptor Triggering:** Osmoreceptors in the organum vasculosum of the lamina terminalis (OVLT) detect elevations in plasma osmolality as small as **1% to 2%** [^statpearls-adh-raas]. This stimulates the conscious sensation of thirst and commands the neurohypophysis to discharge arginine vasopressin (ADH) into the bloodstream [^statpearls-adh-raas].
2. **Renal Water Conservation (ADH / V2 / AQP2):** Circulating ADH binds to basolateral V2 G-protein coupled receptors in the renal medullary collecting ducts, triggering intracellular cAMP phosphorylation and the trafficking and apical insertion of **aquaporin-2 (AQP2) water channels** [^statpearls-adh-raas]. Water is reabsorbed down the steep hypertonic medullary gradient, concentrating urine up to **1,200 mOsm/kg** and reducing urine output to obligatory minimums [^statpearls-adh-raas].
3. **Renin-Angiotensin-Aldosterone System (RAAS) Activation:** Renal baroreceptors in the juxtaglomerular apparatus sense diminished afferent arteriolar perfusion pressure, releasing renin [^statpearls-adh-raas]. Renin cleaves hepatic angiotensinogen into angiotensin I, converted by pulmonary angiotensin-converting enzyme (ACE) into angiotensin II [^statpearls-adh-raas]. Angiotensin II drives potent systemic arteriolar vasoconstriction (preserving central perfusion) and triggers adrenal cortical secretion of aldosterone [^statpearls-adh-raas]. Aldosterone upregulates epithelial sodium channels (ENaC) in the distal nephron, maximizing sodium retention ($\text{FENa} < 1\%$), with water following passively [^statpearls-adh-raas].

---

## 4. Multi-System Functional Degradation Curves

Dehydration is not an isolated fluid loss; it impairs four vital organ systems simultaneously, causing physical work capacity and cognitive function to deteriorate long before circulatory collapse occurs [^statpearls-systemic-effects, ^statpearls-physical-signs].

```
+----------------------------------------------------------------------------------------------------+
|                                PHYSIOLOGICAL DEGRADATION TRAJECTORY                                |
+-----------------------+--------------------+--------------------+----------------------------------+
| Organ System          | Mild Deficit       | Moderate Deficit   | Severe / Shock Deficit           |
|                       | (1 – 2% Mass Loss) | (3 – 5% Mass Loss) | (6 – 10%+ Mass Loss)             |
+-----------------------+--------------------+--------------------+----------------------------------+
| Cognitive & Sensory   | +12–18% Reaction   | Impaired executive | Acute delirium, hallucinations,  |
|                       | latency; working   | function, spatial  | lethargy, stupor, seizures, coma |
|                       | memory lapses      | disorientation     |                                  |
+-----------------------+--------------------+--------------------+----------------------------------+
| Cardiovascular        | Minimal resting    | Tachycardia (+20); | Resting HR >120 bpm; postural    |
|                       | change; compensated| orthostatic drop;  | syncope; supine shock; thready   |
|                       | exertional strain  | SV falls ~15–25%   | pulse; circulatory collapse      |
+-----------------------+--------------------+--------------------+----------------------------------+
| Thermoregulatory      | Core temp rises    | Core temp rises    | Anhidrosis (sweat shutdown);     |
|                       | +0.2°C per % loss; | +0.8° to +1.2°C;   | hyperpyrexia (>40°C); heat       |
|                       | sweating intact    | sweat output drops | stroke collapse                  |
+-----------------------+--------------------+--------------------+----------------------------------+
| Musculoskeletal &     | Mild cramping;     | Severe cramps;     | Exertional rhabdomyolysis;       |
| Renal                 | transient oliguria | BUN:Cr >20:1;      | anuria; acute tubular necrosis;  |
|                       |                    | AKI Stage 1        | myoglobinuric kidney failure     |
+-----------------------+--------------------+--------------------+----------------------------------+
```

### 1. Cognitive & Sensorimotor Performance Degradation

Cognitive faculties degrade before gross muscular failure becomes apparent:

- **At 1–2% Fluid Deficit:** Auditory and visual choice reaction times slow by **12% to 18%** ([functional decline report](file:///home/tdimiduk/cardpg/cardpg/design/research/reports/functional-decline-under-physical-hardship/report.md#L170), [^cmnr-1994-dehydration-thresholds]). Working memory updating, mental arithmetic, and continuous psychomotor vigilance show measurable decrements. Irritability, self-reported fatigue, and headaches begin.
- **At 3–5% Fluid Deficit:** Executive decision-making, spatial processing, and dual-task coordination collapse. Tactical situational awareness is severely degraded; individuals fail to track environmental hazards or assess physical risks. Motor coordination becomes jerky, and fine manual dexterity declines by 20% to 30%.
- **At $\ge 6\%$ Fluid Deficit:** Severe hypertonicity causes intracellular dehydration of cerebral neurons, resulting in cellular shrinkage and traction on cerebral bridging vessels [^statpearls-neurological-effects]. Manifests as profound apathy, delirium, visual and auditory hallucinations, ataxia, dysarthria, and eventual stupor or tonic-clonic seizures [^statpearls-physical-signs, ^statpearls-neurological-effects].

### 2. Cardiovascular & Hemodynamic Dynamics

Plasma volume loss directly impacts the mechanics of the circulatory loop:

- **Cardiac Output & Stroke Volume:** Intravascular volume loss contracts venous return (preload) to the right atrium [^statpearls-ivc-collapse]. Stroke volume (SV) falls by **15% to 25%** during moderate dehydration.
- **Compensatory Tachycardia:** To maintain cardiac output ($CO = HR \times SV$) and mean arterial pressure (MAP), sympathetic outflow drives resting heart rate upward by **3 to 5 bpm per 1% of body mass lost**. At 4% dehydration, resting pulse is elevated by 15 to 25 bpm, and light marching paces push heart rates into near-maximal zones.
- **Orthostatic Intolerance & Syncope:** When standing up from rest, gravity pools 500 to 800 mL of blood in lower-limb venous capacitance beds. With contracted plasma volume, venous return collapses, triggering profound postural hypotension (systolic drop $>20\text{ mmHg}$, diastolic drop $>10\text{ mmHg}$) and orthostatic syncope [^statpearls-physical-signs, ^statpearls-orthostatic-falls].
- **Hypovolemic Shock:** At $>10\%$ fluid loss, compensatory vasoconstriction fails. Mean arterial pressure drops below critical autoregulatory limits ($MAP < 60\text{ mmHg}$), tissue perfusion halts, systemic lactate spikes ($>2.0\text{–}4.0\text{ mmol/L}$), and decompensated hypovolemic shock ensues [^statpearls-physical-signs, ^statpearls-lab-evaluation].

### 3. Thermoregulation & Core Temperature Trajectory

Sweating relies entirely on fluid diverted from the plasma volume:

- **Core Temperature Elevation:** Hypohydration diminishes cutaneous vasodilation (to protect central arterial pressure), reducing skin blood flow. Consequently, core temperature ($T_{\text{core}}$) during physical exertion rises by approximately **$0.15^\circ\text{C}$ to $0.25^\circ\text{C}$ for every 1% of body mass deficit**.
- **Sweating Cutoff (Anhidrosis):** When dehydration reaches Class III ($\ge 6\text{–}8\%$), hypothalamic baroreceptor inputs override thermoregulatory drive, sharply decreasing sweat rate to conserve blood volume. The body ceases evaporative cooling; core temperature spikes violently past $40.5^\circ\text{C}$ ($105^\circ\text{F}$), causing immediate exertional heat stroke, disseminated intravascular coagulation, and hyperpyrexic death.

### 4. Musculoskeletal & Renal Breakdown

- **Skeletal Muscle Cramping:** Transcellular fluid shifts and extracellular electrolyte depletion destabilize the resting membrane potential of alpha-motor neurons, causing involuntary, high-intensity skeletal muscle spasms (heat cramps) in heavily worked muscle groups (calves, quadriceps, back) [^statpearls-musculoskeletal-effects].
- **Exertional Rhabdomyolysis:** Inadequate muscular microvascular perfusion combined with hyperthermia induces sarcolemmal rupture, releasing intracellular creatine kinase, potassium, and myoglobin into the circulation [^statpearls-rhabdomyolysis].
- **Prerenal Acute Kidney Injury (AKI):** Renal hypoperfusion elevates the BUN:creatinine ratio past **20:1** [^statpearls-bun-cr]. If uncorrected, prolonged renal ischemia combined with myoglobinuria precipitates acute tubular necrosis (ATN), uremic toxemia, and irreversible renal parenchymal destruction [^statpearls-renal-effects].

---

## 5. Rehydration Kinetics, Absorption Ceilings, and Recovery Curves

Recovery from dehydration is fundamentally bounded by the biophysics of intestinal fluid transport and the clinical hazards of osmolar shifts [^statpearls-ort-dose, ^statpearls-sodium-correction].

```
+----------------------------------------------------------------------------------------------------+
|                               REHYDRATION PHYSIOLOGY & TIME CONSTRAINTS                            |
+-----------------------+--------------------+---------------------+---------------------------------+
| Modality              | Maximum Absorption | Mechanism           | Clinical Rate-Limiting Danger   |
|                       | Ceiling            |                     |                                 |
+-----------------------+--------------------+---------------------+---------------------------------+
| Oral Rehydration      | 0.80 – 1.20 L/h    | Intestinal SGLT-1   | Gastric distension, emesis,     |
| Therapy (ORT)         | (Gut transit limit)| Na+/Glucose symport | dilutional hyponatremia         |
+-----------------------+--------------------+---------------------+---------------------------------+
| Intravenous Isotonic  | 1.00 – 2.00 L/h    | Direct intravascular| Hyperchloremic acidosis (saline)|
| Crystalloids          | (Fluid resuscitation)| expansion         | Peripheral tissue edema         |
+-----------------------+--------------------+---------------------+---------------------------------+
| Hypernatremia Rate    | Max 1.0 mmol/L/h   | Slow cell volume    | Cerebral edema / brain          |
| of Correction         | (Acute: 10–12/day) | re-expansion        | herniation from rapid influx    |
+-----------------------+--------------------+---------------------+---------------------------------+
| Hyponatremia Rate     | Max 4–8 mEq/L/day  | Controlled plasma   | Central pontine myelinolysis /  |
| of Correction         | (Ideally 4–6/day)  | osmolar elevation   | osmotic demyelination syndrome  |
+-----------------------+--------------------+---------------------+---------------------------------+
```

### Gastrointestinal Absorption Mechanics

1. **Intestinal SGLT-1 Symport:** In the small intestine (jejunum and ileum), water absorption across the enterocyte brush border cannot occur against osmotic gradients via simple diffusion. Instead, it is actively coupled to the **Sodium-Glucose Cotransporter 1 (SGLT-1)**, which transports two sodium ions alongside one glucose molecule [^statpearls-ort-mechanisms]. This creates a local intercellular hypertonic microenvironment that draws water through paracellular junctions and transcellular aquaporin channels [^statpearls-ort-mechanisms]. This mechanism remains completely intact even during infectious enterotoxin-induced diarrhea [^statpearls-ort-mechanisms].
2. **Absorption Ceiling:** Maximal human gastric emptying and intestinal water absorption caps at **800 to 1,200 mL/hour**. Consuming water in excess of this ceiling does not accelerate hydration; it pools in the stomach and small bowel, precipitating nausea, vomiting, abdominal cramping, and diaphragmatic splinting.
3. **Portal-Hepatic Osmoreceptor Reflex:** Oral ingestion of water stimulates hepatic portal osmoreceptors, triggering an immediate reflex autonomic pressor response that elevates systemic blood pressure and cardiac output within minutes of swallowing—long before the fluid has been absorbed into the systemic circulation [^statpearls-ort-mechanisms]. Oral rehydration thus achieves hemodynamic stabilization faster per unit volume than IV infusion [^statpearls-ort-mechanisms].
4. **Reduced-Osmolarity ORS Formulation:** Modern World Health Organization (WHO) and clinical guidelines require **reduced-osmolarity ORS ($< 250\text{ mOsm/L}$)** rather than traditional hypertonic solutions [^statpearls-ors-reduced-osm]. Hypertonic fluids ($> 300\text{ mOsm/L}$, such as undiluted fruit juice or modern commercial soda) draw water osmotically _out_ of plasma into the bowel lumen, worsening diarrhea and accelerating dehydration [^statpearls-ors-reduced-osm, ^statpearls-ors-recipe].
   - _Emergency Field Formulation:_ 1.0 liter clean boiled water + **half teaspoon salt ($\approx 3.0\text{ g NaCl}$)** + **six teaspoons sugar ($\approx 25\text{ g sucrose}$)** [^statpearls-ors-recipe].

### Intravenous Fluid Resuscitation Dynamics

In severe dehydration (Class III/IV) or when vomiting prevents oral intake, intravenous crystalloid infusion is mandatory [^statpearls-iv-fluids]:

- **Crystalloid Distribution Physics:** When $1.0\text{ liter}$ of isotonic crystalloid (0.9% Normal Saline or Lactated Ringer) is infused intravenously, it equilibrates rapidly across the entire extracellular compartment. Because the intravascular space represents only ~20% of ECF, **only 200 to 250 mL of each liter of crystalloid remains within the intravascular bloodstream after 60 to 90 minutes**, with 750 to 800 mL filtering into the interstitial spaces. Thus, resuscitating a 3.0 L intravascular deficit requires infusing 9.0 to 12.0 L of crystalloid over clinical timescales.
- **Choice of Crystalloid:** Balanced crystalloids (Lactated Ringer, Plasma-Lyte A) are preferred over massive volumes of 0.9% normal saline, as large-volume saline infusions cause hyperchloremic metabolic acidosis and renal vasoconstriction [^statpearls-iv-fluids].

### Strict Osmolar Correction Rate Limits: Avoiding Neurological Catastrophe

Rapid, unguided rehydration in established severe dehydration carries lethal iatrogenic risks [^statpearls-sodium-correction, ^statpearls-sodium-hyponatremia]:

1. **Hypernatremic Dehydration Correction Limits (Preventing Cerebral Edema):**
   - In hypernatremic dehydration ($[\text{Na}^+] > 150\text{ mEq/L}$), brain cells synthesize intracellular "idiogenic osmoles" (amino acids, polyols) over 24 to 48 hours to draw water inward and resist cellular shrinkage.
   - If free water is infused too rapidly, extracellular osmolality drops precipitously below intracellular osmolality. Water rushes into the brain cells down the steep gradient, causing acute **cerebral edema, elevated intracranial pressure, brainstem herniation, and death** [^statpearls-neurological-effects, ^statpearls-sodium-correction].
   - _Clinical Rate Limit:_ For chronic or unknown-duration hypernatremia, serum sodium reduction **must not exceed 10 mEq/L per 24 hours** (or ~0.5 mmol/L per hour) [^statpearls-sodium-correction]. In acute hypernatremia of known rapid onset (<24 h), correction at **1.0 mmol/L per hour** is clinically safe [^statpearls-sodium-correction, ^statpearls-sodium-pearls].
2. **Hyponatremic Dehydration Correction Limits (Preventing Central Pontine Myelinolysis):**
   - In hypotonic/hyponatremic dehydration ($[\text{Na}^+] < 130\text{ mEq/L}$), brain cells have adapted to low extracellular sodium by extruding solutes.
   - If hypertonic saline is administered rapidly to correct hyponatremia, the sudden rise in extracellular sodium pulls water violently out of brain cells, causing dehydration and shearing of oligodendrocyte cell bodies. This triggers **Osmotic Demyelination Syndrome (Central Pontine Myelinolysis)**, causing irreversible flaccid quadriplegia, pseudobulbar palsy ("locked-in" syndrome), and death [^statpearls-sodium-hyponatremia, ^statpearls-sodium-pearls].
   - _Clinical Rate Limit:_ Serum sodium rise **must not exceed 4 to 8 mEq/L per 24 hours** (ideally **4 to 6 mEq/L per 24 hours**) [^statpearls-sodium-hyponatremia, ^statpearls-sodium-pearls].

---

## 6. Operational Constraints for Tabletop Rules Grounding

This section establishes domain-pure empirical constraints and degradation curves for rules designers modeling wilderness traversal, forced marches, desert exploration, and logistical attrition.

### 1. Mandatory Daily Fluid Baseline and Scaling Ratios

- **Sedentary Baseline:** An adult human requires **2.0 to 3.0 liters of water daily** under temperate, non-exertional conditions merely to offset obligatory cutaneous, respiratory, and renal solute losses [^statpearls-daily-intake, ^roth-1999-roman-water].
- **Exertional March Scaling:** Sustained hiking under moderate load (15–20 kg) in temperate weather elevates daily requirement to **4.0 to 6.0 liters/day** [^roth-1999-roman-water, ^cmnr-1994-dehydration-thresholds].
- **Thermal and Armor Multiplier:** Heavy physical exertion in combat armor or arid desert environments ($>32^\circ\text{C}$) pushes daily fluid requirement to **8.0 to 12.0 liters/day** [^roth-1999-salt-water, ^cmnr-1994-dehydration-thresholds]. Carrying sufficient water for multi-day desert operations without local water sources quickly exceeds human load carriage capacity (1 liter = 1.0 kg).

### 2. Temporal Asymmetry: Cognitive Lapses Precede Physical Collapse

- Functional degradation begins at **1% to 2% body mass loss** ($0.7\text{ to }1.4\text{ L}$ deficit) ([functional decline report](file:///home/tdimiduk/cardpg/cardpg/design/research/reports/functional-decline-under-physical-hardship/report.md#L170), [^cmnr-1994-dehydration-thresholds]).
- Reaction time slowing (+12–18%), loss of vigilant attention, and executive judgment errors occur **hours before** muscular cramping or circulatory failure set in ([functional decline report](file:///home/tdimiduk/cardpg/cardpg/design/research/reports/functional-decline-under-physical-hardship/report.md#L170)). Characters make critical navigational, tactical, and packing errors while feeling only "mildly thirsty."

### 3. The Rehydration Absorption Ceiling (No "Instant Quenching")

- The human gastrointestinal tract cannot process more than **~1.0 liter of fluid per hour** [^statpearls-ort-dose].
- If a character incurs a 4.0-liter fluid deficit (Class II/III dehydration) during a grueling desert crossing, drinking 4.0 liters of water at an oasis cannot instantly reverse the deficit. Attempting to ingest large volumes rapidly triggers acute gastric dilation and vomiting. Complete physiological rehydration from moderate-to-severe deficit requires **12 to 24 hours of rest and staged rehydration** [^statpearls-prognosis-severity, ^statpearls-ort-dose].

### 4. The Solute Requirement: Water Alone Cannot Cure Severe Sweat Loss

- Sweating sheds both water and sodium. Drinking copious volumes of solute-free pure water after profuse sweating dilutes extracellular sodium, inducing **acute hypotonic hyponatremia** [^statpearls-three-types, ^statpearls-education-intake].
- In wilderness settings, rehydration after heavy exertion requires sodium and carbohydrates (salt broths, oral rehydration solutions, or salted rations) to enable SGLT-1 intestinal transport and maintain extracellular osmolality [^statpearls-ort-mechanisms, ^statpearls-ors-recipe].

### 5. Multiplier Effect with Environmental Stressors

- Dehydration degrades peripheral thermoregulatory vasoconstriction and shivering endurance, accelerating the onset of **accidental hypothermia** in cold, wet environments [^report-hardship-severe].
- Conversely, in hot environments, dehydration halts sweat production, triggering lethal **heat stroke** within 30 to 60 minutes of anhidrosis onset.

---

## Primary Evidence Anchors

[^statpearls-tbw-compartments]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Pathophysiology ([extracted.md#L56](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L56))"
    quote: "The human body is composed of 55% to 65% water (total body water), with two-thirds intracellular and one-third extracellular. Of the extracellular water, one-fifth is found in the intravascular space."
    status: unverified

[^statpearls-volume-depletion]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Pathophysiology ([extracted.md#L58](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L58))"
    quote: "Dehydration is often used interchangeably with hypovolemia or volume depletion, which is a reduction in intravascular volume.[1] Both of these can coexist in some conditions like inadequate fluid intake, gastrointestinal losses through diarrhea or vomiting, osmotic diuresis, and excessive sweating."
    status: unverified

[^statpearls-etiology-obligatory]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Etiology ([extracted.md#L32](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L32))"
    quote: "Body water is lost through the skin, lungs, kidneys, and gastrointestinal tract. Dehydration occurs when water loss exceeds replacement and may result from the loss of free water with or without sodium. This condition often arises when obligatory water losses are not adequately replaced."
    status: unverified

[^statpearls-three-types]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Pathophysiology: Types of Dehydration ([extracted.md#L72-L74](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L72-L74))"
    quote: "Isotonic dehydration: This occurs when water and sodium are lost in equal proportions, as seen in conditions such as vomiting, diarrhea, and hemorrhage. This leads to hypovolemia or reduced plasma volume, manifesting as tachycardia, hypotension, and diminished organ perfusion. ... Hypertonic dehydration: This occurs when free water loss exceeds sodium loss, resulting in hypernatremia and increased plasma osmolality (>300 mOsm/kg). ... An increased osmotic gradient draws water out of cells, leading to intracellular volume contraction. ... Hypotonic dehydration: This occurs when sodium loss exceeds water loss, resulting in hyponatremia; it is commonly seen in individuals using diuretics or those with chronic kidney disease (CKD) or adrenal insufficiency. Hyponatremia results in decreased osmotic gradient, which drives water into the cells, leading to intracellular swelling and concurrent extracellular volume depletion."
    status: unverified

[^statpearls-clinical-grading]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Introduction ([extracted.md#L26](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L26))"
    quote: "Clinically, dehydration ranges from mild symptoms, such as thirst and fatigue, to severe manifestations, including confusion, hypotension, and multiple organ dysfunction."
    status: unverified

[^statpearls-physical-signs]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: History and Physical ([extracted.md#L106](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L106))"
    quote: "The physical examination may reveal tachycardia, hypotension upon standing, and delayed capillary refill, indicating reduced intravascular volume ... Severe cases may present with confusion, lethargy, or even coma, especially with hypernatremia. Dark-colored urine and oliguria are frequently observed, and in extreme cases, dehydration can lead to shock, characterized by profound hypotension, cool, moist, and clammy skin, and poor circulation to vital organs."
    status: unverified

[^statpearls-prognosis-severity]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Prognosis Based on Severity ([extracted.md#L226-L227](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L226-L227))"
    quote: "Mild-to-moderate dehydration: Most cases resolve quickly with oral or intravenous fluid replacement, and patients typically recover within 24 to 48 hours without complications. ... Severe dehydration: The prognosis worsens if hypovolemia, electrolyte imbalances, or organ dysfunction develop. If left untreated, severe dehydration can lead to hypovolemic shock, acute kidney injury, and multiple organ failure."
    status: unverified

[^statpearls-osmolality-thresholds]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Laboratory Evaluation ([extracted.md#L114](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L114))"
    quote: "direct measurement of serum osmolality is a valuable diagnostic marker for assessing hypertonic dehydration, with values greater than 295 mOsm/kg suggesting impending dehydration, and greater than 300 mOsm/kg indicating current dehydration. ... However, it cannot detect isotonic dehydration, and the rate of fluid loss can influence its accuracy."
    status: unverified

[^statpearls-nhanes]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Introduction ([extracted.md#L22](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L22))"
    quote: "defining dehydration as a urine osmolality of 800 mOsm/kg or greater, an estimated 29.5% of adults in the United States were classified as dehydrated."
    status: unverified

[^statpearls-lab-evaluation]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Laboratory Evaluation ([extracted.md#L116-L120](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L116-L120))"
    quote: "Hypernatremia (sodium >145 mEq/L) suggests water loss or hypertonic dehydration, whereas hyponatremia (sodium <135 mEq/L) indicates sodium loss or hypotonic dehydration. ... Elevated lactate (>2 mmol/L) suggests tissue hypoperfusion and may indicate hypovolemic shock. ... Urine specific gravity greater than 1.020 and urine osmolality exceeding 450 mOsm/kg indicate concentrated urine, reflecting renal compensation for fluid loss. ... Urine sodium levels below 20 mEq/L and Fractional Excretion of Sodium (FENa) less than 1% suggest hypovolemia"
    status: unverified

[^statpearls-bun-cr]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Laboratory Evaluation ([extracted.md#L116](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L116))"
    quote: "A blood urea nitrogen-to-creatinine ratio (BUN:Cr) greater than 20:1 suggests prerenal azotemia, consistent with volume depletion, due to increased proximal tubular urea reabsorption and water retention with vasopressin release."
    status: unverified

[^statpearls-ivc-collapse]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Point-of-Care Assessments ([extracted.md#L124](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L124))"
    quote: "IVC diameter less than 2.1 cm with more than 50% inspiratory collapse suggests low right atrial pressure and possible intravascular volume depletion."
    status: unverified

[^statpearls-salivary-osm]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Point-of-Care Assessments ([extracted.md#L126](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L126))"
    quote: "salivary osmolality, with values more than 93 mOsm showing good sensitivity and specificity for detecting both hypertonic and isotonic dehydration."
    status: unverified

[^statpearls-ort-mechanisms]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Mild-to-Moderate Dehydration ([extracted.md#L134](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L134))"
    quote: "Oral rehydration therapy (ORT) is the preferred treatment for mild-to-moderate dehydration if the patient can tolerate oral intake. ... The physiological basis of ORT is that coupled sodium-glucose cotransport across the intestinal brush border remains intact even during diarrhea, enabling enhanced water absorption. ... ORT may require less volume than intravenous fluid therapy to achieve a similar pressor effect because oral fluid has an independent pressor effect mediated by the portal-hepatic osmoreceptor reflex."
    status: unverified

[^statpearls-ort-dose]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Mild-to-Moderate Dehydration: ORT administration ([extracted.md#L145](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L145))"
    quote: "Adults should consume 1 to 2 liters of oral rehydration over the first 4 hours, continuing as needed to maintain hydration."
    status: unverified

[^statpearls-ors-reduced-osm]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Mild-to-Moderate Dehydration ([extracted.md#L138](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L138))"
    quote: "Reduced-osmolarity oral rehydration solutions (<250 mOsm/L) are preferred over the older standard WHO-ORS (311 mOsm/L), as they reduce the risk of hypernatremia."
    status: unverified

[^statpearls-ors-recipe]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Mild-to-Moderate Dehydration ([extracted.md#L142](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L142))"
    quote: "Homemade oral rehydration solution: Half teaspoon salt + 6 teaspoons sugar + 1 liter of water."
    status: unverified

[^statpearls-iv-fluids]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Severe Dehydration ([extracted.md#L151](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L151))"
    quote: "Isotonic crystalloids: Lactated Ringer solution, Plasma-Lyte A, or 0.9% normal saline are preferred first-line management options. Balanced crystalloids, such as Lactated Ringer solution or Plasma-Lyte, may reduce the risk of hyperchloremic metabolic acidosis and major adverse kidney events compared with 0.9% normal saline in hospitalized and critically ill adults."
    status: unverified

[^statpearls-sodium-correction]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Electrolyte and Acid-Base Correction: Hypernatremia ([extracted.md#L162](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L162))"
    quote: "Previous recommendations have been to reduce serum sodium by no more than 10 mEq/L per 24 hours (or 0.5 mmol/L per hour) for chronic or unknown-duration hypernatremia to avoid cerebral edema. ... In acute hypernatremia (developed over hours), rapid correction at 1 mmol/L per hour is appropriate and improves prognosis without increasing the risk of cerebral edema."
    status: unverified

[^statpearls-sodium-hyponatremia]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Electrolyte and Acid-Base Correction: Hyponatremia ([extracted.md#L163](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L163))"
    quote: "Hypovolemic hyponatremia should be treated with isotonic crystalloid solutions to restore intravascular volume. If symptomatic (eg, seizures and confusion), hypertonic saline (3% NaCl) should be administered cautiously under close monitoring, with a correction rate not exceeding 4 to 8 mEq/L per 24 hours to avoid osmotic demyelination syndrome."
    status: unverified

[^statpearls-hypernatremia-mortality]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Death and Mortality Risk ([extracted.md#L309](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L309))"
    quote: "If left untreated, hypernatremia can have a mortality rate as high as 50% when sodium levels exceed 160 mEq/L."
    status: unverified

[^statpearls-sodium-pearls]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Pearls and Other Issues ([extracted.md#L355-L357](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L355-L357))"
    quote: "The previous recommendation was to slowly correct hypernatremia, not exceeding 6 to 12 mEq/L per 24 hours, to prevent cerebral edema. However, emerging evidence suggests that rapid correction at 1 mmol/L per hour is appropriate and improves prognosis without increasing the risk of cerebral edema. ... A slower sodium correction is preferred for hyponatremia, with a correction rate not exceeding 4 to 8 mEq/L per 24 hours (ideally 4-6 mEq/L per 24 hours). ... In severe hyponatremia, rapid volume repletion may cause a sharp rise in serum sodium, increasing the risk of central pontine myelinolysis."
    status: unverified

[^statpearls-daily-intake]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Deterrence and Patient Education ([extracted.md#L337](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L337))"
    quote: "adults are generally encouraged to consume between 2 and 3 liters of water daily.[59] Patients should adjust fluid intake based on their activity level."
    status: unverified

[^statpearls-poor-prognosis]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Prognosis: Poor prognostic factors ([extracted.md#L239-L240](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L239-L240))"
    quote: "Poor prognostic factors ... Serum osmolality more than 300 mOsm/kg.[1]"
    status: unverified

[^statpearls-urine-volume]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Complications: Renal Complications ([extracted.md#L260](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L260))"
    quote: "Chronic dehydration reduces urine volume and increases solute supersaturation, which promotes the formation of calcium oxalate and uric acid stones."
    status: unverified

[^statpearls-urine-output-target]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Monitoring and Prevention ([extracted.md#L189](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L189))"
    quote: "Urine output goal: More than or equal to 0.5 mL/kg/h, indicating normal hydration status."
    status: unverified

[^statpearls-adh-raas]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Pathophysiology: Physiological Mechanisms ([extracted.md#L64-L66](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L64-L66))"
    quote: "Specialized neurons in the hypothalamus (osmoreceptors) can detect increased plasma osmolality and trigger a thirst response, promoting increased water intake. ... When plasma osmolality increases, the posterior pituitary gland secretes ADH, also known as arginine vasopressin (AVP). AVP acts on V2 receptors in the renal collecting duct to insert aquaporin-2 (AQP2) water channels into the apical membrane, increasing water reabsorption and concentrating the urine. ... When intravascular volume is low, the kidneys release renin, which converts angiotensinogen into angiotensin I. The angiotensin-converting enzyme (ACE) then converts angiotensin I to angiotensin II. Angiotensin II stimulates aldosterone release from the adrenal glands, which increases sodium reabsorption through epithelial sodium channels in the distal nephron. Water reabsorption occurs secondarily by following the osmotic gradient created by sodium transport."
    status: unverified

[^statpearls-systemic-effects]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Pathophysiology: Systemic Effects of Dehydration ([extracted.md#L80-L84](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L80-L84))"
    quote: "Cardiovascular effects: Hypovolemia decreases cardiac output, which stimulates tachycardia and hypotension. In severe cases, shock and multiple organ failure may occur. ... Neurological effects: Hypertonic dehydration induces an osmotic shift, causing brain cells to shrink and leading to delirium, confusion, and seizures. ... Renal effects: Reduced renal perfusion can lead to an acute kidney injury, presenting with oliguria or anuria. ... Gastrointestinal effects: Hypoperfusion of the gut mucosa can lead to ischemic injury, resulting in nausea and impaired nutrient absorption. ... Musculoskeletal effects: Fluid and electrolyte imbalances can cause muscle cramps, weakness, and an increased risk of falls"
    status: unverified

[^statpearls-neurological-effects]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Complications: Neurological Complications ([extracted.md#L272-L275](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L272-L275))"
    quote: "Cognitive impairment and delirium: Dehydration can reduce cerebral perfusion, causing confusion, disorientation, and delirium ... Seizures: Electrolyte imbalances such as hypernatremia or hyponatremia can disrupt neuronal function, leading to seizures and altered mental status. ... Cerebral edema: Rapid correction of hypernatremia can cause osmotic shifts, resulting in brain swelling and increased intracranial pressure. ... Cerebral hemorrhage: Severe hypernatremia can cause brain shrinkage, leading to vascular rupture and intracranial hemorrhage."
    status: unverified

[^statpearls-orthostatic-falls]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Complications: Cardiovascular Complications ([extracted.md#L267](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L267))"
    quote: "Orthostatic hypotension and falls: Reduced circulating volume can cause dizziness and syncope upon standing, increasing the risk of falls and fractures"
    status: unverified

[^statpearls-musculoskeletal-effects]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Complications: Musculoskeletal Complications ([extracted.md#L285](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L285))"
    quote: "Muscle spasms and weakness: Electrolyte imbalances, including sodium, potassium, and magnesium deficiencies, can lead to muscle spasms and weakness."
    status: unverified

[^statpearls-rhabdomyolysis]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Complications: Musculoskeletal Complications ([extracted.md#L286](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L286))"
    quote: "Risk of rhabdomyolysis: Severe dehydration, particularly in athletes, military personnel, or patients with critical illness, can trigger muscle breakdown, presenting with myoglobinuria and acute kidney injury."
    status: unverified

[^statpearls-renal-effects]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Complications: Renal Complications ([extracted.md#L258](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L258))"
    quote: "Acute kidney injury: Reduced renal perfusion due to dehydration leads to prerenal azotemia, which, if not managed promptly, can progress to acute tubular necrosis."
    status: unverified

[^statpearls-education-intake]:
    source: statpearls-2023-adult-dehydration-pathophysiology
    locator: "Section: Deterrence and Patient Education ([extracted.md#L337](../sources/verisimilitude/statpearls-2023-adult-dehydration-pathophysiology/extracted.md#L337))"
    quote: "Excessive water intake in older adults can lead to hyponatremia; therefore, balanced hydration solutions are recommended to maintain proper electrolyte levels."
    status: unverified

[^the-2021-shigella-dysentery]:
    source: the-2021-brief-history-of-shigella
    locator: "Section: Dysentery - Clinical Symptoms and Transmission ([extracted.md#L22](../sources/verisimilitude/the-2021-brief-history-of-shigella/extracted.md#L22))"
    quote: "The disease ranges from mild diarrhea to frank dysentery, which is marked by fever, abdominal pain and cramps, tenesmus, and the passage of bloody, mucoid stools ... These symptoms are manifestations of the ability of _Shigella_ to invade, and multiply within, epithelial cells of the large intestine, spread to adjacent cells, and ultimately kill the infected cells."
    status: unverified

[^cmnr-1994-dehydration-thresholds]:
    source: cmnr-1994-food-components-performance
    locator: "Part II: Food Components That May Optimize Physical Performance, p. 232 ([extracted.txt#L12323-L12334](../sources/verisimilitude/cmnr-1994-food-components-performance/extracted.txt#L12323-L12334))"
    quote: "sweating can reach 3 to 4 liters. A water loss equivalent to 2 percent of body weight will impair cardiovascular function and the thermal regulatory ... mechanisms of the body ... Water loss of 4 percent of body weight will reduce muscle endurance and work capacity ... Water loss that exceeds 6 percent of body weight will drastically hamper physical performance and possibly lead to severe heat injury."
    status: unverified

[^roth-1999-roman-water]:
    source: roth-1999-logistics-roman-army
    locator: "Chapter 1: Supply Needs and Rations, pp. 36–37 ([extracted.txt#L2280-L2373](../sources/verisimilitude/roth-1999-logistics-roman-army/extracted.txt#L2280-L2373))"
    quote: "The most basic need of troops in the field is not food, but liquid. ... but without liquids death will follow in a matter of days. ... soldiers on the march would have required at least two liters per day in order to operate effectively."
    status: unverified

[^roth-1999-salt-water]:
    source: roth-1999-logistics-roman-army
    locator: "Chapter 1: Supply Needs and Rations, p. 41 ([extracted.txt#L2556-L2584](../sources/verisimilitude/roth-1999-logistics-roman-army/extracted.txt#L2556-L2584))"
    quote: "Human salt and water requirements are closely linked: the body needs extra sodium chloride to retain water ... modern armies issued salt tablets to soldiers during periods of extreme heat stress."
    status: unverified
