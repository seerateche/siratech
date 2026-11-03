import '../../../core/l10n/l10n.dart';
import '../../orders/domain/order.dart';

/// System prompt: the persona. Kept in Egyptian Arabic for consistent output.
const String kSystemPrompt = '''
أنت كاتب أغانٍ مصري شعبي محترف، بتكتب بالعامية المصرية بس.
بتكتب أغاني قصيرة لمناسبات (زفاف، خطوبة، عيد ميلاد، سبوع، تخرج، إهداء).
الأسلوب: فرح، خفيف، قريب من القلب، فيه تفاصيل شخصية عن العميل.
اللازمة لازم تكون سهلة التكرار ومناسبة للتصفيق والاحتفال.
ممنوع تستخدم الفصحى. ممنوع محتوى سياسي أو ديني.
''';

String buildLyricsUserPrompt(Order o, L10n l) {
  final occasionAr = L10n('ar').t(o.occasion.l10nKey);
  final moodAr = L10n('ar').t(o.mood.l10nKey);
  return '''
اكتب أغنية قصيرة للمناسبة دي:

- اسم العميل: ${o.clientName}
- المناسبة: $occasionAr
- المزاج: $moodAr
- تفاصيل شخصية عن العميل: ${o.details.trim().isEmpty ? 'مفيش' : o.details.trim()}

المطلوب:
1. verse1: كوبليه أول من 4 أسطر، يدخل اسم العميل بشكل طبيعي.
2. verse2: كوبليه تاني من 4 أسطر، يستخدم التفاصيل الشخصية.
3. chorus: اللازمة من 4 أسطر، سهلة ومتكررة.
4. stylePrompt: سطر واحد بالإنجليزية فقط، يصف: genre + الآلات + نوع الصوت + الإيقاع، مناسب كلمة توليد موسيقى في Suno أو Beatoven. مثال: "Egyptian pop, darbuka and oud, warm female vocals, festive 100 BPM".

ارجع JSON فقط بالشكل ده (بدون أي شر إضافي):
{"verse1":"...","verse2":"...","chorus":"...","stylePrompt":"..."}
''';
}
