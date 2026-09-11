# خطة التطوير والإصلاح الجديدة — TAJ ERP (مدمجة مع المهارات)

> تدمج: إصلاح الألوان + مفتاح البسيط/الاحترافي + خارطة الطريق المستقبلية (تطبيق، أدمن، محاسب، تقارير).
> كل مرحلة مربوطة بالمهارة (المهارات) التي تُستدعى فيها فعليًا من الثلاثين المثبَّتة مسبقًا.

---

## المرحلة 0 — تثبيت المهارات (مرة واحدة، قبل أي شيء)

ثبّت الدفعة كاملة الآن (30 مهارة، التفاصيل والروابط في `TAJ-Skills-Roadmap.md`):

```bash
# تصميم وهوية
npx skills add anthropics/skills --skill frontend-design
npx skills add arvindrk/extract-design-system --skill extract-design-system
npx skills add leonxlnx/taste-skill --skill brandkit
npx skills add leonxlnx/taste-skill --skill redesign-existing-projects
npx skills add leonxlnx/taste-skill --skill minimalist-ui
npx skills add mattpocock/skills --skill design-an-interface
npx skills add vercel-labs/agent-skills --skill web-design-guidelines

# واجهات ويب (أدمن/محاسب مستقبلًا)
npx skills add shadcn/ui --skill shadcn
npx skills add vercel-labs/agent-skills --skill vercel-react-best-practices
npx skills add vercel-labs/agent-skills --skill vercel-composition-patterns
npx skills add vercel-labs/agent-skills --skill vercel-react-view-transitions
npx skills add vercel-labs/agent-skills --skill deploy-to-vercel

# باك اند وقاعدة بيانات
npx skills add supabase/agent-skills --skill supabase-postgres-best-practices
npx skills add mattpocock/skills --skill domain-modeling
npx skills add mattpocock/skills --skill codebase-design

# معمارية وتخطيط
npx skills add mattpocock/skills --skill improve-codebase-architecture
npx skills add mattpocock/skills --skill ubiquitous-language
npx skills add mattpocock/skills --skill to-prd
npx skills add mattpocock/skills --skill to-spec
npx skills add obra/superpowers --skill writing-plans

# مستندات وتقارير
npx skills add anthropics/skills --skill pdf
npx skills add anthropics/skills --skill xlsx
npx skills add anthropics/skills --skill docx
npx skills add anthropics/skills --skill pptx

# اختبار وجودة
npx skills add mattpocock/skills --skill tdd
npx skills add obra/superpowers --skill test-driven-development
npx skills add obra/superpowers --skill systematic-debugging
npx skills add anthropics/skills --skill webapp-testing

# Git وسير عمل
npx skills add mattpocock/skills --skill git-guardrails-claude-code
npx skills add obra/superpowers --skill verification-before-completion
```

---

## الجزء أ — الإصلاح الفوري (تطبيق الكاشير Flutter، جاهز الآن)

### المرحلة 1 — تشخيص الألوان الحالية
**المهارة:** `extract-design-system`
- تحليل لقطتي شاشة الدخول وPOS الحاليتين، استخراج كل الألوان الفعلية (Hex) وتوثيقها كجدول "قبل".

### المرحلة 2 — تثبيت نظام ألوان موحّد
**المهارة:** `brandkit`
- Primary = الأزرق المعتمد (بلا تغيير) · Neutral = رمادي داكن واحد لكل الأزرار المتساوية بالأهمية · 4 ألوان وظيفية فقط (نجاح/تحذير/خطر/معلومة) لمعنى مالي/حالة نظام حصرًا.
- المخرج: ملف Tokens واحد (`taj_colors.dart`) — المرجع الوحيد المعتمد.

### المرحلة 3 — تطبيق الإصلاح على الشاشتين
**المهارات:** `redesign-existing-projects` + `frontend-design`
1. شاشة الدخول: الأزرق للزر الرئيسي والشعار فقط.
2. شاشة POS: أزرار الدفع الستة بنفس لون Neutral (تمييز بالأيقونة فقط)، شارات الفئات تُزال عن بطاقات المنتج وتبقى فقط كنقطة صغيرة بالقائمة الجانبية.
- **معيار القبول:** أي لون في اللقطة النهائية غير موجود بجدول Tokens = مرفوض.

### المرحلة 4 — مفتاح التبديل (بسيط ↔ احترافي)
**المهارة:** `minimalist-ui` (لضبط الوضع البسيط تحديدًا)
- Toggle في شريط POS العلوي، الحالة محفوظة محليًا لكل مستخدم.
- الوضعان يشتركان بنفس الشاشة الأساسية — لا شاشة مضاعفة.
- الوضع البسيط يبقى كما هو اليوم بعد إصلاح الألوان فقط، بلا أي إضافة.

### المرحلة 5 — عناصر الوضع الاحترافي (عنصر بالمرة، بالترتيب)
**المهارات:** `frontend-design` (مقيّدة بجدول Tokens) + `tdd` (للمنطق الحسّاس كالدفع المقسّم والوردية)
1. تعليق الفاتورة (Hold/Park Sale)
2. تعديل مباشر داخل سطر السلة (+/−، حذف، ملاحظة)
3. تأكيد قبل الدفع النهائي (Bottom Sheet ملخّص)
4. دفع مقسّم (Split Payment)
5. إدارة الوردية (فتح/إغلاق بمبلغ افتتاحي)
6. مؤشر مخزون هادئ على بطاقة المنتج (نص رمادي فقط)
7. ربط زبون بالفاتورة (اختياري)

### المرحلة 6 — مراجعة نهائية
**المهارات:** `webapp-testing` (إن كانت هناك واجهة ويب مرتبطة) + `verification-before-completion` + `systematic-debugging` عند ظهور أي عطل
- لقطة شاشة لكل شاشة معدَّلة + تدقيق تباين WCAG AA + تأكيد عدم وجود أي Hex خارج جدول Tokens.

**قيود صارمة تسري على الجزء أ بالكامل:**
- حقل السعر في POS لا يظهر أصلًا لمن لا يملك صلاحية `sales.change_price`، في كلا الوضعين.
- كل عنصر جديد RTL بالكامل (`EdgeInsetsDirectional` فقط).
- ممنوع أي لون Hardcoded خارج ملف Tokens.

---

## الجزء ب — التوسّع المستقبلي (أدمن، محاسب، تقارير)

### المرحلة 7 — تخطيط كل واجهة جديدة قبل بنائها
**المهارات:** `to-prd` → `to-spec` → `writing-plans` → `ubiquitous-language`
- لكل واجهة جديدة (أدمن، محاسب، إلخ): وثيقة متطلبات مختصرة → مواصفات تقنية → خطة تنفيذ → توحيد المصطلحات المحاسبية بين الفرونت والباك اند قبل الكود.

### المرحلة 8 — بناء لوحات الويب (أدمن/محاسب) إن قُرِّر Next.js/React
**المهارات:** `design-an-interface` → `web-design-guidelines` → `shadcn` → `vercel-react-best-practices` + `vercel-composition-patterns` → `vercel-react-view-transitions` → `deploy-to-vercel`
- تصميم الواجهة أولًا، ثم البناء بمكوّنات shadcn الملتزمة بنفس Tokens الألوان من المرحلة 2 (لا نظام ألوان منفصل عن التطبيق).

### المرحلة 9 — دعم وحدة المحاسبة والتقارير
**المهارات:** `pdf` (فواتير) · `xlsx` (كشوف/تقارير) · `docx` (مستندات رسمية) · `pptx` (عروض على عملاء محتملين)
- تُستدعى مباشرة عند بناء أي شاشة تصدير في §8.6-ك من الوثيقة المعمارية (مركز التقارير).

### المرحلة 10 — الباك اند وقاعدة البيانات (استمرار المعمارية الموثّقة)
**المهارات:** `supabase-postgres-best-practices` (فهارس/أداء الاستعلامات) · `domain-modeling` · `codebase-design` · `improve-codebase-architecture` (مراجعة دورية)

### المرحلة 11 — جودة مستمرة عبر كل المراحل (دائمة، لا مرة واحدة)
**المهارات:** `tdd` / `test-driven-development` (منطق مالي حسّاس) · `systematic-debugging` (أخطاء مزامنة صعبة) · `git-guardrails-claude-code` · `verification-before-completion`

---

## ملخص تسلسل الاستدعاء

| المرحلة | متى | المهارات المستدعاة |
|---|---|---|
| 1-6 | الآن — POS الحالي | extract-design-system → brandkit → redesign-existing-projects/frontend-design → minimalist-ui → frontend-design/tdd → verification-before-completion |
| 7 | قبل أي واجهة جديدة | to-prd → to-spec → writing-plans → ubiquitous-language |
| 8 | عند بناء الأدمن/المحاسب | design-an-interface → web-design-guidelines → shadcn → vercel-* → deploy-to-vercel |
| 9 | عند بناء التقارير | pdf، xlsx، docx، pptx |
| 10 | مستمر مع الباك اند | supabase-postgres-best-practices، domain-modeling، codebase-design، improve-codebase-architecture |
| 11 | دائم عبر كل شيء | tdd، systematic-debugging، git-guardrails-claude-code، verification-before-completion |
