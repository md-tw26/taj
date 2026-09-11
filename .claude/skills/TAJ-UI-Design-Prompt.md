# تاج | TAJ ERP — دليل تصميم الواجهات (UI/UX Design Prompt)

> **الحالة:** دليل تصميم عام مستقل عن الأداة (Figma / أي أداة ذكاء اصطناعي / مصمم بشري).
> **Status:** Tool‑agnostic UI/UX design guide (Figma / any AI design tool / human designer).
>
> **مهم:** هذا الملف **لا يحتوي ألوان المشروع الخاصة** (الزمردي/الذهبي/البنفسجي). نظام الألوان الأساسي هنا مأخوذ من **Minimals** لبدء تصميم محايد.
> **Important:** This file **excludes the project's brand colors** (Emerald/Gold/Purple) on purpose. The base color system is taken from **Minimals** so you start from a neutral, professional foundation.

---

## 0. كيف تستخدم هذا الـ Prompt | How to use this prompt

**عربي —** الصق هذا الملف كاملًا في أداة التصميم أو أعطه للمصمم. صُمّم الواجهات الـ 18 المذكورة في القسم 7 باستخدام:
- **نظام تصميم أساسي:** Minimals (الألوان، الطباعة، المكوّنات الأساسية).
- **التنقل:** بأسلوب **Linear**.
- **الجداول:** بأسلوب **Stripe**.
- **البطاقات:** بأسلوب **Notion**.
- **الفلاتر:** بأسلوب **ClickUp**.
- **اللغة/الاتجاه:** العربية RTL أساسيًا، مع دعم الإنجليزية LTR.

**EN —** Paste this whole file into your design tool or hand it to the designer. Design the 18 screens in Section 7 using: **Minimals** as the base design system (colors, type, core components); **Linear** for navigation; **Stripe** for tables; **Notion** for cards; **ClickUp** for filters. Arabic RTL is the primary direction, with English LTR support.

**تعليمة رئيسية جاهزة للّصق | Master instruction (paste‑ready):**

> Design a professional, Odoo‑style ERP called **TAJ**. Use the **Minimals** design system as the visual base (color tokens, Public Sans typography, soft cards, 8px grid). Borrow the **navigation model from Linear**, **data tables from Stripe**, **cards from Notion**, and **filtering UX from ClickUp**. Primary direction is **Arabic RTL** with English LTR support, light + dark mode. Keep the UI simple for the user while the logic stays in the backend. Do **not** introduce brand colors yet — keep the Minimals palette.

---

## 1. مبادئ التصميم | Design Principles

**عربي —**
- **بساطة أمامية، تعقيد خلفي:** واجهة نظيفة للمستخدم، والمنطق المحاسبي يعمل تلقائيًا في الخلف (فلسفة Odoo).
- **RTL أولًا:** كل تخطيط يُبنى للعربية أولًا ثم ينعكس للإنجليزية. استخدم بدائل الاتجاه (start/end) لا (left/right).
- **تنقل حسب الدور:** الوحدات المخفية لا تُبنى أصلًا في الشجرة (المدير يرى الكل، الكاشير يرى POS فقط…).
- **Offline‑first مرئي:** مؤشر حالة اتصال/مزامنة دائم في الشريط العلوي (متصل / أوف‑لاين / جارٍ المزامنة / عدد المعلّق).
- **متجاوب:** هاتف (تنقل سفلي) / تابلت وديسكتوب (شريط جانبي + Master‑Detail).
- **قابلية النقر في كل رقم:** كل مؤشر أو مبلغ ينقل لسجلّه التفصيلي.
- **سرعة قصوى في POS:** أقل عدد نقرات، لمس كبير، لا مسارات زائدة.

**EN —** Simple front / automated back (Odoo philosophy). RTL‑first with logical start/end insets. Role‑based navigation (hidden modules are not rendered). A persistent offline/sync indicator in the top bar. Responsive: phone bottom‑nav, tablet/desktop sidebar + master‑detail. Every number is clickable into its detail record. POS is optimized for maximum speed and touch.

---

## 2. نظام الألوان | Color System — **Minimals** (لا ألوان مشروع | no brand colors)

> المصدر الرسمي | Source: Minimals UI Kit color foundation. القيم أدناه مطابقة للنسخة الرسمية.
> استخدم **primary** كلون العلامة مؤقتًا. عند الرغبة لاحقًا يمكن استبدال قيم `primary` فقط بلون المشروع دون لمس باقي النظام.

### 2.1 الألوان الأساسية والدلالية | Core & semantic tokens

| Token | lighter | light | **main** | dark | darker | الاستخدام في تاج \| Usage in TAJ |
|---|---|---|---|---|---|---|
| **primary** | `#C8FAD6` | `#5BE49B` | `#00A76F` | `#007867` | `#004B50` | الإجراءات الرئيسية، الروابط، عنصر التنقل النشط \| primary actions, links, active nav |
| **secondary** | `#EFD6FF` | `#C684FF` | `#8E33FF` | `#5119B7` | `#27097A` | تمييز ثانوي، وسوم التحليلات \| secondary accent, analytics tags |
| **info** | `#CAFDF5` | `#61F3F3` | `#00B8D9` | `#006C9C` | `#003768` | **الاقتراح الذكي، المساعد الذكي، تلميحات معلوماتية** \| smart‑suggestion cards, AI assistant, info hints |
| **success** | `#D3FCD2` | `#77ED8B` | `#22C55E` | `#118D57` | `#065E49` | أرباح، مدفوع، تمت المزامنة، فروق موجبة \| profit, paid, synced, positive delta |
| **warning** | `#FFF5CC` | `#FFD666` | `#FFAB00` | `#B76E00` | `#7A4100` | مخزون منخفض، قرب الاستحقاق، مزامنة معلّقة، جزئي \| low stock, due soon, pending sync, partial |
| **error** | `#FFE9D5` | `#FFAC82` | `#FF5630` | `#B71D18` | `#7A0916` | عجز، متأخر، ملغى، فشل، نقص \| deficit, overdue, cancelled, failed, shortage |

**contrastText:** أبيض `#FFFFFF` فوق main لكل الألوان، ما عدا **warning** استخدم نصًا داكنًا `#1C252E`.

### 2.2 الرماديات والمحايدة | Greys & neutrals

| 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|
| `#F9FAFB` | `#F4F6F8` | `#DFE3E8` | `#C4CDD5` | `#919EAB` | `#637381` | `#454F5B` | `#212B36` | `#161C24` |

- **Text primary:** grey `#212B36` — **Text secondary:** grey `#637381` — **Text disabled:** grey `#919EAB`.
- **Divider/Border:** grey 300 `#DFE3E8` (أو `#919EAB` بشفافية 20% \| or grey‑500 @20%).
- **Background (light):** `#FFFFFF` — **Surface/Card:** `#FFFFFF` فوق خلفية grey‑100 `#F9FAFB` للصفحة.
- **Common:** black `#000000`, white `#FFFFFF`.

### 2.3 الوضع الداكن | Dark mode

**عربي —** الخلفية grey‑900 `#161C24`، الأسطح/البطاقات grey‑800 `#212B36`، النص الأساسي `#FFFFFF` والثانوي grey‑500 `#919EAB`. أبقِ ألوان main كما هي (تعمل على الوضعين) واستخدم درجات lighter للنصوص الملوّنة فوق الداكن.

**EN —** Dark bg = grey‑900, surfaces = grey‑800, primary text white, secondary = grey‑500. Keep `main` hues; use `lighter` tints for colored text on dark.

### 2.4 قواعد استخدام اللون | Color usage rules
- لا لون Hardcoded داخل المكوّنات — كل شيء من التوكنز. \| No hardcoded colors; everything from tokens.
- الحالة المالية دائمًا بالدلالة: ربح/دائن = success، خسارة/مدين = error، معلّق = warning، معلوماتي = info.
- خلفيات الشارات (badges) = درجة `lighter`، ونصها = درجة `dark` من نفس اللون. \| Badge bg = `lighter`, badge text = `dark` of same hue.

---

## 3. الطباعة | Typography

**عربي —**
- **الخط اللاتيني:** `Public Sans` (خط Minimals الأساسي) — والعناوين البارزة يمكن `Barlow`.
- **الخط العربي:** `IBM Plex Sans Arabic` أو `Cairo` (لأن Public Sans لا يدعم العربية). طابِق الأوزان بين الخطّين.
- **الأرقام:** استخدم أرقامًا جدولية (tabular figures) لكل المبالغ والجداول.
- **الأوزان:** 400 نص، 500 متوسط، 600 شبه عريض (عناوين فرعية/أزرار)، 700–800 عناوين.

**EN —** Latin = **Public Sans** (Minimals default), display = optional **Barlow**. Arabic = **IBM Plex Sans Arabic** / **Cairo**. Use tabular figures for all amounts. Weights 400/500/600/700/800.

### مقياس الطباعة | Type scale (rem @16px base)

| Style | Size | Weight | Line‑height |
|---|---|---|---|
| h1 | 2.5rem (40) | 800 | 1.25 |
| h2 | 2rem (32) | 800 | 1.33 |
| h3 | 1.5rem (24) | 700 | 1.5 |
| h4 | 1.25rem (20) | 700 | 1.5 |
| h5 | 1.125rem (18) | 700 | 1.5 |
| h6 | 1rem (17) | 600 | 1.55 |
| subtitle1/2 | 16 / 14 | 600 | 1.5 |
| body1/2 | 16 / 14 | 400 | 1.5 |
| caption | 12 | 400 | 1.5 |
| button | 14–15 | 600 | 1.7 (no ALL‑CAPS) |

---

## 4. المسافات، الزوايا، الظلال | Spacing, Radius, Shadows

**عربي —**
- **الشبكة:** مضاعفات 8 (4، 8، 12، 16، 24، 32، 40). حشوة البطاقة الافتراضية 24.
- **الزوايا (radius):** عناصر صغيرة 8، بطاقات 16، حقول/أزرار 8، شارات/حبوب pill كاملة، صور مصغّرة 8–12.
- **الظلال:** ناعمة ومنخفضة التباين على نمط Minimals — ظل البطاقة خفيف (`0 0 2px rgba(145,158,171,.2), 0 12px 24px -4px rgba(145,158,171,.12)`). ظلال أعمق للقوائم المنسدلة والحوارات. تجنّب الظلال الحادة.
- **الحدود:** 1px grey‑300 للفواصل والبطاقات المسطّحة.

**EN —** 8px grid (4/8/12/16/24/32/40), card padding 24. Radius: small 8, cards 16, inputs/buttons 8, badges pill, thumbnails 8–12. Soft low‑contrast Minimals shadows; card shadow is light, dropdowns/dialogs deeper. Borders 1px grey‑300.

---

## 5. أنماط المكوّنات المستعارة | Borrowed Component Patterns

### 5.1 التنقل — بأسلوب **Linear** | Navigation — Linear

**عربي —**
- **شريط جانبي** بعرض ~260px (قابل للطي إلى أيقونات فقط ~72px). في RTL يكون على **يمين** الشاشة.
- **أعلى الشريط:** محوّل الشركة/الفرع (Workspace switcher): شعار + اسم الشركة + سهم منسدل.
- **بحث عام + لوحة أوامر (Command Palette) بـ `Ctrl/Cmd+K`** تفتح للبحث والانتقال وتنفيذ أوامر سريعة.
- **عناصر ثابتة أعلى:** لوحة التحكم، الإشعارات (Inbox)، اليوم التشغيلي.
- **أقسام قابلة للطي** لكل مجموعة وحدات (المبيعات، المشتريات، المخزون، المالية، الموارد البشرية، النظام) — كل قسم يوسّع عناصره.
- **المفضلة (Favorites):** تثبيت الشاشات كثيرة الاستخدام.
- **العنصر النشط:** خلفية خفيفة `primary.lighter` + شريط/أيقونة `primary.main`، أيقونات خطية رفيعة رمادية للبقية.
- **مسار تنقل (Breadcrumb)** أعلى منطقة المحتوى + لوحات معاينة (Peek) تنزلق من الجانب عند فتح سجل دون مغادرة القائمة.
- **حركة كيبورد كاملة** واختصارات ظاهرة بجانب العناصر.
- **حسب الدور:** الأقسام غير المصرّح بها لا تظهر إطلاقًا.

**EN —** ~260px collapsible sidebar (→ 72px icon rail), **right side in RTL**. Top: company/branch **workspace switcher**. Global search + **`Cmd/Ctrl+K` command palette** for navigate/run. Pinned top items (Dashboard, Inbox, Operating Day), collapsible module groups, Favorites. Active item = `primary.lighter` bg + `primary.main` marker; thin grey line icons otherwise. Breadcrumb on top of content + slide‑in **peek panels**. Keyboard‑first with visible shortcuts. Role‑based: unauthorized groups are never rendered.

### 5.2 الجداول — بأسلوب **Stripe** | Data Tables — Stripe

**عربي —**
- **رؤوس أعمدة** صغيرة، رمادية `#637381`، محاذاة start؛ الأرقام والمبالغ محاذاة end بأرقام جدولية.
- **صفوف** بارتفاع مريح (52–56px)، فاصل سفلي 1px grey‑300، وتمرير مثبّت للرأس (sticky header).
- **Hover للصف:** خلفية grey‑100 خفيفة جدًا، وتظهر إجراءات (…) في نهاية الصف.
- **العمود الأول** = المعرّف الأساسي (اسم غامق) + سطر ثانوي رمادي (كود/تاريخ).
- **الحالة كـ Badge** (نجاح/معلّق/فشل) بألوان دلالية.
- **شريط أدوات أعلى الجدول:** بحث + فلاتر (5.4) + نطاق زمني + زر **تصدير** (PDF/Excel) + تخصيص الأعمدة.
- **النقر على الصف** يفتح لوحة تفصيل (Peek) أو صفحة السجل.
- **صفحنة** بسيطة (السابق/التالي + العدد) أو تحميل تدريجي، مع فرز أعمدة بسهم خفيف.
- **حالة فارغة** مصمّمة (أيقونة + نص + زر إجراء)، وهيكل تحميل (skeleton rows).

**EN —** Small grey column headers, start‑aligned (numbers end‑aligned, tabular). 52–56px rows, 1px grey‑300 divider, sticky header. Row hover = faint grey‑100 with trailing `…` actions. First column = bold identifier + muted secondary line. Status as semantic **badges**. Table toolbar: search + filters (§5.4) + date range + **Export (PDF/Excel)** + column settings. Row click → peek/detail. Simple pagination or lazy‑load, sortable columns, designed empty + skeleton states.

### 5.3 البطاقات — بأسلوب **Notion** | Cards — Notion

**عربي —**
- **بطاقة نظيفة:** سطح أبيض، زوايا 12–16، حد 1px خفيف أو ظل ناعم جدًا، حشوة سخية.
- **رأس اختياري:** أيقونة/إيموجي أو شريط لون علوي رفيع للتصنيف.
- **الجسم:** عنوان (وزن 600) ثم خصائص كأسطر صغيرة أو **حبوب ملوّنة باستيل** (`lighter` خلفية / `dark` نص).
- **Hover:** ارتفاع ظل خفيف + تغميق حد بسيط، ومقبض سحب يظهر (للوحات Kanban).
- **بطاقة شبح "+ إضافة"** لإنشاء عنصر جديد.
- **استخدامها في تاج:** بطاقات KPI في لوحة التحكم، بطاقات المنتجات (POS/الأصناف)، بطاقات بنود المصروفات، بطاقات "اقتراح ذكي"، بطاقات الأسئلة الجاهزة في التقارير الذكية.

**EN —** Clean white cards, 12–16 radius, hairline border or very soft shadow, generous padding. Optional icon/emoji or top color strip. Title (600) + properties as small rows or **pastel pills** (`lighter` bg / `dark` text). Hover = slight lift + border darken + drag handle (Kanban). Ghost "+ New" card. Use for: dashboard KPI cards, product cards (POS/Items), expense‑category cards, smart‑suggestion cards, ready‑question cards.

### 5.4 الفلاتر — بأسلوب **ClickUp** | Filters — ClickUp

**عربي —**
- **شريط فلاتر** بزر **"+ إضافة فلتر"**. كل فلتر = **حبة (chip)** بالشكل: `[الحقل] [الشرط] [القيمة] (✕)`.
- **دمج الشروط** بمبدّل **AND/OR**.
- **منتقي الحقل:** الحالة، الفرع، الموظف/الكاشير، التصنيف، المورد/العميل، طريقة الدفع، التاريخ، الوسوم، حقول مخصّصة.
- **الشرط حسب نوع الحقل:** (هو/ليس، يحتوي، مضبوط/غير مضبوط، نطاق تاريخي).
- **منتقي القيمة:** متعدّد الاختيار بمربّعات + صور رمزية للأشخاص + نقاط لون للحالة/الأولوية.
- **بجانب الفلاتر:** **تجميع حسب (Group by)** و**ترتيب حسب (Sort by)**.
- **طرق عرض محفوظة (Saved Views):** كل عرض يتذكّر فلاتره (يومي/أسبوعي/فرع محدّد…)، وشارة تُظهر عدد الفلاتر الفعّالة + "مسح الكل".

**EN —** Filter bar with **"+ Add Filter"**; each filter is a **chip** `[Field] [Operator] [Value] (✕)`. Combine with **AND/OR** toggle. Field picker (status, branch, employee/cashier, category, supplier/customer, payment method, date, tags, custom fields). Type‑aware operators (is/is‑not, contains, is‑set, date range). Value picker = multi‑select checkboxes + people avatars + status/priority color dots. Alongside: **Group by** + **Sort by**. **Saved Views** remember their filters; active‑filter count badge + "Clear all".

### 5.5 مكوّنات Minimals الأساسية | Minimals base components

**عربي —** أزرار (contained / outlined / soft / text)، حقول إدخال بحواف 8 وعنوان عائم، قوائم منسدلة، تبويبات، حبوب/شارات، Avatars، Tooltips، حوارات (Dialogs) بظل عميق، Snackbars للتنبيهات، أشرطة تقدّم، مبدّلات (Switch/Checkbox/Radio)، **بطاقات KPI** برقم كبير + دلتا ملوّن + رسم مصغّر (sparkline)، ورسوم بيانية (خطية/أعمدة/دائرية) بألوان التوكنز. حالات: **Skeleton** للتحميل، **Empty** مصمّمة، **Error** برسالة عربية واضحة.

**EN —** Buttons (contained/outlined/soft/text), 8‑radius inputs with floating label, menus, tabs, chips/badges, avatars, tooltips, deep‑shadow dialogs, snackbars, progress, switches/checkboxes/radios, **KPI cards** (big number + colored delta + sparkline), charts (line/bar/donut) in token colors. States: **skeleton** loading, designed **empty**, clear Arabic **error**.

---

## 6. القالب العام والهيكل | Global Layout & App Shell

**عربي —**
- **الهيكل:** شريط جانبي (يمين في RTL) + شريط علوي + منطقة محتوى.
- **الشريط العلوي:** مسار تنقل (Breadcrumb)، بحث، **مؤشّر المزامنة/الاتصال**، محوّل اللغة (ع/EN)، الوضع الداكن، الإشعارات، صورة المستخدم/القائمة.
- **نقاط الكسر (Responsive):** هاتف <600 (تنقل سفلي Bottom‑nav + شاشة واحدة)، تابلت 600–1024 (شريط جانبي مطوي أيقونات)، ديسكتوب >1024 (شريط كامل + عرض Master‑Detail بعمودين).
- **RTL:** استخدم `EdgeInsetsDirectional` و`AlignmentDirectional`؛ الأيقونات ذات الاتجاه (رجوع/تقدّم) تنعكس.
- **الكثافة:** واسعة على الديسكتوب، ومريحة للّمس على الهاتف/POS.

**EN —** Shell = sidebar (right in RTL) + top bar + content. Top bar: breadcrumb, search, **sync/connection indicator**, language switch (AR/EN), dark‑mode, notifications, user menu. Breakpoints: phone <600 (bottom‑nav, single pane), tablet 600–1024 (icon‑rail), desktop >1024 (full sidebar + 2‑pane master‑detail). RTL via directional insets/alignment; directional icons mirror. Comfortable density on desktop, touch‑friendly on phone/POS.

---

## 7. الشاشات (18) | Screens (18)

> لكل شاشة: **التخطيط / المكوّنات / النمط المستعار / الحالات**. صمّمها بنظام ألوان Minimals أعلاه.
> Each screen: **Layout / Components / Borrowed pattern / States**. Design with the Minimals palette above.

### 7.0 المصادقة والتوجيه | Auth & Routing (Login / Splash)
- **التخطيط \| Layout:** Splash بشعار "تاج" على خلفية grey‑100؛ Login بطاقة وسطية (البريد/المستخدم، كلمة السر، تذكّرني، اختيار الفرع).
- **المكوّنات \| Components:** حقول Minimals، زر `primary` كبير، مبدّل اللغة، رابط "نسيت كلمة السر".
- **النمط \| Pattern:** بطاقة Notion‑style موسّطة.
- **التوجيه حسب الدور \| Role routing:** الكاشير → POS مباشرة؛ المحاسب → المحاسبة/التقارير؛ المدير → لوحة التحكم.

### 7.1 لوحة التحكم | Dashboard
- **التخطيط:** شبكة **بطاقات KPI** قابلة للنقر (مبيعات اليوم/الشهر، أرباح، مصروفات، مشتريات، نقدية الصندوق، أرصدة البنوك، ديون العملاء، مستحقات الموردين، مخزون منخفض/منتهٍ، الأفضل مبيعًا، أفضل العملاء، أعلى الموظفين، رواتب مستحقة).
- **المكوّنات:** بطاقات Notion + رقم كبير + دلتا ملوّن (success/error) + **sparkline**؛ صفّ رسوم بيانية (مبيعات زمنيًا، مصروفات حسب البند).
- **النمط:** بطاقات **Notion**؛ كل بطاقة تنقل لجدول **Stripe** التفصيلي.
- **الحالات:** Skeleton للبطاقات، فارغة عند غياب البيانات.

**EN —** Clickable KPI grid (Notion cards + big number + colored delta + sparkline) + chart row. Each card → Stripe detail table. Skeleton/empty states.

### 7.2 الأصناف | Products / Items
- **التخطيط:** قائمة/جدول **Stripe** (صورة، اسم، باركود، تصنيف، سعر، مخزون، حالة) + **فلاتر ClickUp** (تصنيف/علامة/حالة) + بحث فوري. عرض بديل **بطاقات Notion** (Grid).
- **شاشة الصنف:** تبويبات (عام، الأسعار متعدّدة المستويات، المخزون/المستودعات، الخصائص Variants: لون/مقاس، الحركة التاريخية).
- **النمط:** جدول **Stripe** + فلاتر **ClickUp** + بطاقات **Notion** للعرض الشبكي.
- **الحالات:** فارغة (لا أصناف)، تحميل، خطأ حفظ.

**EN —** Stripe table (image, name, barcode, category, price, stock, status) + ClickUp filters + instant search; alt Notion grid. Item screen with tabs (general, tiered prices, stock/warehouses, variants, history).

### 7.3 المخزون والجرد | Inventory & Stocktake
- **التخطيط:** شاشة جرد بمسح الباركود (كاميرا/ماسح): عدّاد يتزايد تلقائيًا + اهتزاز/صوت تأكيد. بعدها **شاشة مقارنة** (فعلي × دفتري) بجدول **Stripe** يُظهر العجز/الزيادة/قيمة الفروقات.
- **الاقتراح الذكي:** **بطاقة info** تعرض السبب المحتمل + زر "اعتماد التسوية" بضغطة.
- **النمط:** جدول **Stripe** للمقارنة + بطاقة **info (Minimals)** للاقتراح + فلاتر **ClickUp** (فرع/مستودع/صنف).
- **الحالات:** أثناء المسح (عدّاد حي)، لا فروقات (نجاح)، فروقات (warning/error).

**EN —** Barcode‑scan count (auto‑increment + haptic/sound), then a compare screen (actual vs book) as a Stripe table (deficit/surplus/value). **info‑colored smart‑suggestion card** + one‑tap "Approve adjustment". ClickUp filters by branch/warehouse/item.

### 7.4 المبيعات | Sales
- **التخطيط:** جدول فواتير **Stripe** (رقم، عميل، تاريخ، إجمالي، حالة: مدفوعة/آجلة/مرتجع) + **فلاتر ClickUp** + نطاق زمني + تصدير.
- **إنشاء فاتورة:** نموذج من صفحة واحدة؛ إجراءات: طباعة، PDF، واتساب، مرتجع، تعليق، إلغاء.
- **النمط:** جدول **Stripe**؛ حالة الفاتورة كـ Badge دلالي.
- **الحالات:** فارغة، تحميل، تأكيد بعد الحفظ (ملخّص ما نفّذه النظام).

**EN —** Stripe invoice table (No., customer, date, total, status badge) + ClickUp filters + date range + export. Single‑page create; print/PDF/WhatsApp/return/hold/cancel actions.

### 7.5 نقاط البيع (POS) — أهم شاشة | Point of Sale — most important
- **التخطيط:** شاشة لمس مخصّصة: **شبكة أصناف ببطاقات Notion كبيرة بصور**، بحث/مسح باركود أعلى، **سلة جانبية** (يسار في RTL) بالإجمالي، أزرار دفع ضخمة.
- **قيود:** حقل السعر **مقفل تمامًا**؛ الخصم يظهر فقط لمن يملك صلاحيته؛ الكاشير لا يرى أي قوائم أخرى.
- **النمط:** بطاقات **Notion** للأصناف؛ الحد الأدنى من التنقل (لا شريط جانبي للكاشير)؛ يعمل أوف‑لاين بالكامل.
- **الحالات:** أوف‑لاين (شارة)، سلة فارغة، دفع ناجح (إيصال/طباعة حرارية + PDF).

**EN —** Touch‑first: large image **product cards (Notion)** grid, top search/scan, side cart (left in RTL), huge pay buttons. **Price locked**, discount gated by permission, cashier sees no other menus, fully offline. States: offline badge, empty cart, successful payment (thermal receipt + PDF).

### 7.6 المشتريات | Purchases
- **التخطيط:** نموذج إدخال من صفحة واحدة (مورد، رقم/تاريخ الفاتورة، أصناف/كميات/أسعار، ضريبة، خصم، سداد نقدي/آجل، استحقاق، ملاحظات، **إرفاق صورة الفاتورة بالكاميرا**).
- **بعد الحفظ:** رسالة تأكيد بما نفّذه النظام (تحديث مخزون، رصيد مورد، قيد محاسبي).
- **النمط:** نموذج Minimals + جدول أصناف قابل للإضافة (Stripe‑style rows) + قائمة مشتريات سابقة **Stripe** بفلاتر **ClickUp**.
- **الحالات:** تحميل، تأكيد، خطأ.

**EN —** Single‑page purchase form (supplier, invoice no./date, line items, tax, discount, cash/credit, due date, notes, **camera attach**). Post‑save confirmation of automated effects. Editable line rows + past‑purchases Stripe table with ClickUp filters.

### 7.7 المصروفات | Expenses
- **التخطيط:** **بنود جاهزة كبطاقات Notion** (إيجار، كهرباء، ماء، إنترنت، صيانة، نقل، ضيافة، قرطاسية، تسويق، بنكية، تشغيلية، إدارية، **مرتبات**، مكافآت، سلف، مسحوبات + بند مخصّص).
- **نموذج الإدخال:** اسم، مبلغ، تاريخ، فرع، طريقة دفع، جهة مستفيدة، رقم مستند، ملاحظات، إرفاق صورة. عند **مرتبات** → يظهر **منتقي الموظف** ويُربط المصروف بملفه.
- **النمط:** بطاقات **Notion** للبنود + سجل مصروفات **Stripe** + فلاتر **ClickUp** (بند/فرع/موظف/طريقة دفع/فترة).
- **الحالات:** فارغة، تحميل، تأكيد ربط الموظف.

**EN —** Ready categories as **Notion cards**; entry form (name, amount, date, branch, method, payee, doc no., notes, attach). "Salaries" reveals an employee picker linking the expense to the profile. Expense log = Stripe table + ClickUp filters.

### 7.8 العملاء والموردون | Customers & Suppliers
- **التخطيط:** جدول **Stripe** (اسم، هاتف، رصيد، سقف ائتمان، آخر عملية) + فلاتر **ClickUp**. بطاقة عميل/مورد: بيانات + كشف حساب + سجلّات (فواتير/تحصيلات/مدفوعات/مرتجعات) في تبويبات، وزر "تذكير بالديون".
- **النمط:** جدول **Stripe** + بطاقة تفصيل (Peek) + بطاقات ملخّص **Notion** أعلى الملف.
- **الحالات:** فارغة، تحميل، رصيد سالب (error) / موجب (success).

**EN —** Stripe list (name, phone, balance, credit limit, last activity) + ClickUp filters. Profile: data + statement + tabbed records + "debt reminder". Peek detail + Notion summary cards.

### 7.9 الموظفون والرواتب | Employees & Payroll
- **التخطيط:** جدول **Stripe** للموظفين + ملف كامل: بيانات، مسمّى، فرع، راتب أساسي، بدلات، مكافآت، خصومات، سلف، مسحوبات، مستحقات، عمولات، إضافي، **صافي الراتب**، حالة (مدفوع/غير مدفوع/جزئي كـ Badge).
- **الترابط:** كل مصروف مرتبط بالموظف يظهر تلقائيًا ويحدّث الصافي.
- **النمط:** جدول **Stripe** + بطاقات **Notion** لملخّص الراتب + فلاتر **ClickUp** (فرع/حالة الراتب/شهر).
- **الحالات:** فارغة، تحميل، تحذير مستحقات غير مصروفة (warning).

**EN —** Stripe employee table + full profile (base, allowances, bonuses, deductions, advances, withdrawals, dues, commissions, overtime, **net**, status badge). Linked expenses auto‑update net. Notion salary‑summary cards + ClickUp filters.

### 7.10 الخزائن والبنوك | Treasury & Banks
- **التخطيط:** بطاقات **Notion** لكل صندوق/بنك (الاسم + الرصيد الحالي) + جدول **Stripe** للحركة اليومية (إيداع/سحب/تحويل/مطابقة).
- **النمط:** بطاقات **Notion** (الأرصدة) + جدول **Stripe** (الحركات) + فلاتر **ClickUp** (نوع الحركة/فرع/فترة).
- **الحالات:** فارغة، تحميل، عدم تطابق الرصيد (warning).

**EN —** Notion cards per cash/bank account (name + balance) + Stripe daily‑movement table (deposit/withdraw/transfer/reconcile) + ClickUp filters. Balance‑mismatch warning state.

### 7.11 المحاسبة | Accounting
- **التخطيط:** عمودان (Master‑Detail): **دليل حسابات شجري** (Tree View قابل للطي) يسارًا/يمينًا حسب RTL، وتفاصيل الحساب + القيود يمينًا.
- **القيود:** جدول **Stripe** (تلقائية/يدوية، ترحيل، عكس، اعتماد، بحث)؛ كل قيد يعرض **شرحًا مبسّطًا بالعربية** لغير المحاسب.
- **النمط:** شجرة تنقل **Linear‑style** (طيّ/توسيع) + جدول قيود **Stripe** + فلاتر **ClickUp** (نوع القيد/حالة/فترة).
- **الحالات:** تحميل، فارغة، قيد غير متوازن (error).

**EN —** Master‑detail: collapsible **tree** chart of accounts + account detail/entries. Journal entries as Stripe table (auto/manual, post, reverse, approve, search) with a plain‑Arabic explanation per entry. Linear‑style tree + ClickUp filters.

### 7.12 التقارير | Reports
- **التخطيط:** مركز تقارير موحّد (ميزان مراجعة، قائمة دخل، ميزانية، تدفقات نقدية، أرباح/خسائر، أستاذ/يومية، ضرائب، زكاة، رواتب، موظفون، موردون/عملاء، مصروفات) كـ **بطاقات Notion** تفتح على جدول **Stripe**.
- **ثابت لكل تقرير:** زرَّا **تصدير PDF** و**Excel** + **فلاتر ClickUp** (فترة/فرع).
- **النمط:** بطاقات **Notion** (فهرس) + جدول **Stripe** (النتيجة) + فلاتر **ClickUp**.
- **الحالات:** تحميل، فارغة، خطأ توليد.

**EN —** Unified report center as **Notion cards** → **Stripe** result tables. Every report has fixed **PDF + Excel export** + **ClickUp** period/branch filters.

### 7.13 التقارير الذكية والتحليلات | Smart Reports & Analytics
- **التخطيط:** **أسئلة جاهزة كبطاقات Notion** ("أين يذهب المال؟"، "أكثر المنتجات ربحًا؟"…) تفتح إجابات مرئية. لوحة رسوم بيانية تفاعلية (مبيعات حسب الوقت/الموظف/الفرع/العميل/الصنف/المورد/طريقة الدفع؛ مصروفات حسب البند).
- **النمط:** بطاقات **Notion** للأسئلة + **فلاتر/Slicing بأسلوب ClickUp** (تقطيع حسب أي بُعد) + تمييز **info** للبطاقات التفسيرية.
- **الحالات:** تحميل رسم، لا بيانات كافية.

**EN —** Ready **question cards (Notion)** → visual answers + interactive charts, sliced by any dimension via **ClickUp‑style filters**. info accent for explanatory cards.

### 7.14 الإشعارات | Notifications
- **التخطيط:** مركز إشعارات (Inbox بأسلوب **Linear**): قائمة مقروء/غير مقروء، تجميع حسب النوع، كل إشعار ينقل للشاشة المعنية (نفاد مخزون، تأخّر سداد، فواتير مستحقة، فروقات جرد، رواتب غير مصروفة، مصروفات غير معتادة…).
- **النمط:** قائمة **Linear Inbox** + فلاتر/تجميع **ClickUp** (النوع/الأولوية) + شارات دلالية.
- **الحالات:** فارغة (لا جديد)، تحميل.

**EN —** **Linear‑style Inbox**: read/unread, grouped by type, each item deep‑links to its screen. ClickUp grouping/filters + semantic badges.

### 7.15 الإقفال اليومي | Day Closing
- **التخطيط:** شاشة "اليوم التشغيلي" (يبقى مفتوحًا حتى يُقفل يدويًا). **معالج (Wizard)** بخطوات: تجميع المبيعات/المصروفات/المرتجعات، فروق الصندوق والمخزون، العجز/الزيادة، ثم توليد التقرير اليومي.
- **النمط:** Stepper من Minimals + بطاقات **Notion** لملخّص كل خطوة + جدول **Stripe** للفروقات.
- **الحالات:** يوم مفتوح (info)، جاهز للإقفال (success)، فروقات تحتاج مراجعة (warning/error).

**EN —** Operating‑Day screen (stays open until manually closed). **Wizard**: aggregate sales/expenses/returns, cash & stock variances, deficit/surplus, then final daily report. Minimals stepper + Notion summary cards + Stripe variance table.

### 7.16 المساعد الذكي | AI Assistant
- **التخطيط:** واجهة محادثة (Chat) تتصل بـ endpoint المساعد؛ **أسئلة مقترحة جاهزة كحبوب/بطاقات**، والإجابات تُعرض **كبطاقات ورسوم لا نصًا فقط**.
- **النمط:** فقاعات محادثة + بطاقات **Notion** للإجابات الرقمية + تمييز **info** بارز (لون المساعد).
- **الحالات:** كتابة (typing)، فارغة (اقتراحات)، خطأ اتصال.

**EN —** Chat UI to the assistant endpoint; **suggested‑question chips/cards**; answers rendered as **cards + charts, not plain text**. Notion answer cards + prominent **info** accent. Typing/empty/error states.

### 7.17 المستخدمون والصلاحيات | Users & Permissions
- **التخطيط:** جدول **Stripe** للمستخدمين والأدوار + **مصفوفة صلاحيات** تفصيلية (خصوصًا POS: من يفتح/ينفّذ/يخصم/يلغي/يرجّع/يعلّق/يطبع/يراجع الإقفال) + **سجل تدقيق (Audit Log)** كجدول **Stripe** (من/متى/ماذا تغيّر).
- **النمط:** جدول **Stripe** + مصفوفة Checkboxes (Minimals) + فلاتر **ClickUp** للسجل.
- **الحالات:** فارغة، تحميل، تحذير صلاحية حسّاسة.

**EN —** Stripe users/roles table + detailed **permission matrix** (esp. POS actions) + **Audit Log** as a Stripe table (who/when/what). Checkbox matrix + ClickUp filters on the log.

### 7.18 الإعدادات | Settings
- **التخطيط:** تنقل جانبي فرعي **Linear‑style** لأقسام الإعدادات: **المظهر** (اختيار السمة — *يُترك محايدًا الآن دون ألوان مشروع* + مفتاح الوضع الداكن + معاينة حية)، اللغة/العملة/الضرائب، شكل الفواتير والطباعة، **سياسة الخصم** (نطاق: صنف/مجموعة/تصنيف/الكل، مدة، فرع، مستخدمون مخوّلون، إيقاف تلقائي)، سياسة الإقفال اليومي، المزامنة والنسخ الاحتياطي.
- **النمط:** قائمة أقسام **Linear** + بطاقات إعداد **Notion** + نماذج Minimals.
- **الحالات:** حفظ ناجح (success)، تغييرات غير محفوظة (warning).

**EN —** **Linear‑style** settings sub‑nav: Appearance (theme picker — *kept neutral, no brand colors yet* + dark‑mode + live preview), language/currency/tax, invoice & print, **discount policy** (scope/duration/branch/authorized users/auto‑off), day‑closing policy, sync & backup. Linear section list + Notion setting cards + Minimals forms.

---

## 8. الحالات المشتركة | Shared States (design once, reuse)

| الحالة \| State | التصميم \| Design |
|---|---|
| تحميل \| Loading | **Skeleton** (Minimals) — صفوف/بطاقات رمادية نابضة، لا Spinner للصفحات الكاملة. |
| فارغة \| Empty | أيقونة + عنوان + سطر شرح + زر إجراء أساسي (`primary`). |
| خطأ \| Error | رسالة عربية واضحة + سبب + زر "إعادة المحاولة"، بلون `error`. |
| أوف‑لاين \| Offline | شارة `warning` في الشريط العلوي + شارة على العمليات المعلّقة (`pending`). |
| نجاح \| Success | Snackbar `success` قصير + تحديث فوري للبيانات. |

---

## 9. إمكانية الوصول و RTL | Accessibility & RTL checklist
- تباين نص/خلفية ≥ 4.5:1 (WCAG AA)؛ لا تعتمد على اللون وحده — أضف أيقونة/نصًا للحالة. \| ≥4.5:1 contrast; never color‑only.
- أهداف لمس ≥ 44×44px (خصوصًا POS). \| Touch targets ≥44px.
- كل التخطيطات بـ start/end لا left/right؛ الأيقونات الاتجاهية تنعكس في RTL. \| Logical directions; mirror directional icons.
- الأرقام والعملات والتواريخ بـ `intl` (ميلادي/هجري)، وأرقام جدولية في الجداول. \| Localized numerals/dates, tabular figures.
- تركيز واضح للكيبورد (Linear‑style) واختصارات ظاهرة. \| Visible keyboard focus + shortcuts.

---

## 10. المخرجات المطلوبة | Deliverables
1. **Design tokens / Style guide** — الألوان (Minimals)، الطباعة، المسافات، الظلال (فاتح + داكن). \| Tokens & style guide (light+dark).
2. **مكتبة مكوّنات** — أزرار، حقول، جداول (Stripe)، بطاقات (Notion)، فلاتر (ClickUp)، تنقل (Linear)، شارات، حالات. \| Component library.
3. **قالب عام (App Shell)** — شريط جانبي + علوي + محتوى، متجاوب RTL/LTR. \| Responsive shell.
4. **الشاشات الـ 18** بحالاتها (تحميل/فارغة/خطأ) + نسخة موبايل لـ POS ولوحة التحكم على الأقل. \| 18 screens with states + mobile POS & Dashboard.
5. **خريطة تدفّق** بين الشاشات (Login → حسب الدور). \| Flow map.

**ترتيب مقترح للتنفيذ | Suggested order:** (1) Tokens + Shell + Login/توجيه → (2) POS → (3) Dashboard + الأصناف + المخزون → (4) بقية الوحدات → (5) التقارير + التصدير.

---

## المصادر | Sources
- Minimals UI Kit — Colors foundation (القيم اللونية الرسمية): https://docs.minimals.cc/colors/ · https://minimals.cc/components/foundation/colors
- أنماط مرجعية (patterns referenced): Linear (navigation), Stripe (tables), Notion (cards), ClickUp (filters).
- الشاشات مستمدة من وثائق مشروع "تاج": `TAJ-Flutter-Frontend-Prompt.md` و`متطلبات-منظومة-ERP-بأسلوب-Odoo.md`.
