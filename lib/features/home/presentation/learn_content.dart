import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';
import '../../../core/theme/app_colors.dart';

/// A single quick-check question shown at the end of a lesson.
class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
}

/// A single learning article shown in the dashboard carousel, the learn
/// library, and its own detail screen.
class LearnItem {
  const LearnItem({
    required this.category,
    required this.title,
    required this.meta,
    required this.icon,
    required this.color,
    required this.deep,
    required this.summary,
    required this.body,
    required this.takeaways,
    required this.quiz,
  });

  final String category;
  final String title;
  final String meta;
  final IconData icon;
  final Color color;
  final Color deep;

  /// One-line teaser shown under the title on the detail screen.
  final String summary;

  /// Article paragraphs.
  final List<String> body;

  /// Short bullet list shown at the end of the article.
  final List<String> takeaways;

  /// Comprehension check that must be passed to mark this lesson complete.
  final List<QuizQuestion> quiz;
}

/// Tracks which lessons the user has passed the quiz for.
///
/// A Supabase-backed, per-account store. The notifier keeps lesson UI in sync
/// while the database makes progress survive an app restart.
class LearnProgress {
  LearnProgress._();

  static const _table = 'lesson_completions';
  static SupabaseClient get _db => SupabaseConfig.client;
  static final ValueNotifier<Set<String>> completedTitles =
      ValueNotifier<Set<String>>({});

  static String get _userId {
    final id = _db.auth.currentUser?.id;
    if (id == null) {
      throw StateError('You must be signed in to save lesson progress.');
    }
    return id;
  }

  static Future<void> fetch() async {
    final rows = await _db
        .from(_table)
        .select('lesson_title')
        .eq('user_id', _userId);
    completedTitles.value = rows
        .map((row) => row['lesson_title'] as String)
        .toSet();
  }

  static bool isCompleted(LearnItem item) =>
      completedTitles.value.contains(item.title);

  static Future<void> markCompleted(LearnItem item) async {
    completedTitles.value = {...completedTitles.value, item.title};
    try {
      await _db.from(_table).upsert({
        'user_id': _userId,
        'lesson_title': item.title,
      }, onConflict: 'user_id,lesson_title');
    } catch (_) {
      await fetch();
      rethrow;
    }
  }
}

const allLearnItems = <LearnItem>[
  LearnItem(
    category: 'FERTILITY 101',
    title: 'Understanding Ovulation Signs',
    meta: '4 min read',
    icon: Icons.egg_alt_outlined,
    color: AppColors.primary,
    deep: AppColors.secondary,
    summary:
        'Your body sends clear signals around ovulation — here is what to look out for.',
    body: [
      'Ovulation is the moment your ovary releases an egg, and it is the single most fertile day of your cycle. For most people with a 28-day cycle, this happens around day 14, but it can shift earlier or later depending on your own rhythm.',
      'The most reliable signs are changes in cervical mucus (it becomes clear, stretchy, and slippery — often compared to raw egg white), a small rise in basal body temperature the day after ovulation, and for some, mild one-sided pelvic twinges known as mittelschmerz.',
      'Tracking these signs over a few cycles helps BabyBloom build a more accurate picture of your personal pattern, rather than relying on a generic 28-day average.',
    ],
    takeaways: [
      'Egg-white cervical mucus is one of the clearest fertility signs.',
      'Basal body temperature rises after ovulation, not before.',
      'Your pattern becomes more accurate the more cycles you log.',
    ],
    quiz: [
      QuizQuestion(
        question: 'Which of these is a classic sign of ovulation?',
        options: [
          'Clear, stretchy cervical mucus',
          'A drop in basal body temperature',
          'Heavier bleeding',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        question:
            'For a 28-day cycle, ovulation typically occurs around which day?',
        options: ['Day 1', 'Day 14', 'Day 28'],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'FERTILITY 101',
    title: 'Tracking Basal Body Temperature',
    meta: '5 min read',
    icon: Icons.device_thermostat_outlined,
    color: AppColors.primary,
    deep: AppColors.secondary,
    summary: 'A simple thermometer can confirm ovulation has already happened.',
    body: [
      'Basal body temperature (BBT) is your body\'s resting temperature, measured first thing in the morning before you get out of bed, talk, or even sit up. A tiny rise of about 0.5–1°F after ovulation is caused by a hormone called progesterone.',
      'Because the rise happens after the egg has already been released, BBT alone will not tell you ovulation is coming — it confirms it happened after the fact. That is why it works best combined with cervical mucus tracking, which does signal the fertile window in advance.',
      'For the most reliable readings, use the same thermometer at roughly the same time every morning, and try to get at least three to four consecutive hours of sleep beforehand.',
    ],
    takeaways: [
      'Take your temperature before you get out of bed each morning.',
      'A sustained rise confirms ovulation already happened.',
      'Pair BBT with cervical mucus tracking for the full picture.',
    ],
    quiz: [
      QuizQuestion(
        question: 'When should you take your basal body temperature?',
        options: [
          'Right before bed',
          'First thing in the morning, before getting up',
          'After exercising',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'A BBT rise confirms that ovulation…',
        options: [
          'Is about to happen',
          'Already happened',
          'Will not happen this cycle',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'NUTRITION',
    title: 'Foods That Support a Healthy Cycle',
    meta: '3 min read',
    icon: Icons.restaurant_outlined,
    color: AppColors.secondary,
    deep: AppColors.lavenderLight,
    summary:
        'What you eat can gently support hormone balance and energy through your cycle.',
    body: [
      'Leafy greens, lentils, and other iron-rich foods help replenish what is lost during your period, especially if your flow tends to run heavier. Pairing them with a source of vitamin C, like citrus or peppers, helps your body absorb that iron more easily.',
      'Healthy fats — think avocado, olive oil, nuts, and fatty fish — provide the building blocks your body uses to produce reproductive hormones. Steady blood sugar, supported by whole grains and protein at each meal, can also help ease mood swings and energy dips.',
      'None of this needs to be complicated or restrictive. Small, consistent choices across the month tend to matter more than any single "perfect" meal.',
    ],
    takeaways: [
      'Iron-rich foods help replenish what your period takes.',
      'Healthy fats support hormone production.',
      'Consistency matters more than any single meal.',
    ],
    quiz: [
      QuizQuestion(
        question: 'Pairing iron-rich foods with vitamin C helps because it…',
        options: [
          'Improves iron absorption',
          'Cancels out the iron',
          'Has no real effect',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        question:
            'Which food group helps your body produce reproductive hormones?',
        options: ['Refined sugar', 'Healthy fats', 'Artificial sweeteners'],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'NUTRITION',
    title: 'Hydration and Cervical Mucus',
    meta: '3 min read',
    icon: Icons.water_drop_outlined,
    color: AppColors.secondary,
    deep: AppColors.lavenderLight,
    summary:
        'Water plays a bigger role in your fertile window than you might expect.',
    body: [
      'Cervical mucus is mostly water, so how hydrated you are can directly affect its volume and texture — two things BabyBloom asks you to track because they help pinpoint your fertile window.',
      'Aiming for consistent water intake throughout the day, rather than large amounts all at once, tends to work best. Caffeine and alcohol both have a mild dehydrating effect, so balancing them with extra water can help if you enjoy your morning coffee.',
      'If you notice your mucus seems unusually dry even around ovulation, hydration is one of the simplest things to check before assuming something else is going on.',
    ],
    takeaways: [
      'Cervical mucus quality is closely tied to hydration.',
      'Spread water intake evenly through the day.',
      'Caffeine and alcohol can mildly dehydrate — balance with extra water.',
    ],
    quiz: [
      QuizQuestion(
        question: 'Cervical mucus is made up mostly of…',
        options: ['Water', 'Protein', 'Fat'],
        correctIndex: 0,
      ),
      QuizQuestion(
        question: 'Which of these has a mild dehydrating effect?',
        options: ['Water', 'Caffeine', 'Fruit'],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'MINDSET',
    title: 'Managing Stress on Your TTC Journey',
    meta: '5 min read',
    icon: Icons.self_improvement_outlined,
    color: AppColors.lavenderLight,
    deep: AppColors.lavender,
    summary:
        'Trying to conceive can be emotionally heavy — small rituals can help you carry it.',
    body: [
      'It is completely normal for trying to conceive to feel consuming at times. The waiting, the tracking, the hope that resets every month — all of it takes a real emotional toll, even when things are going "normally."',
      'Grounding rituals that are not about fertility at all can help create breathing room: a short walk, journaling, five minutes of quiet breathing, or simply talking to someone who is not also trying to conceive. Protecting a little bit of your day that has nothing to do with your cycle can make the rest of it easier to hold.',
      'If the weight of it starts to feel like more than you can carry alone, that is worth taking seriously — not as a sign of weakness, but as information. Support is available, and reaching for it is a strength.',
    ],
    takeaways: [
      'It is normal for TTC to feel emotionally heavy.',
      'Small daily rituals unrelated to fertility can help.',
      'Reaching out for support is a strength, not a setback.',
    ],
    quiz: [
      QuizQuestion(
        question: 'Which is a grounding ritual mentioned in the lesson?',
        options: [
          'Checking fertility forums more often',
          'A short walk or journaling',
          'Avoiding all conversation about it',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'According to the lesson, reaching out for support is…',
        options: [
          'A sign of weakness',
          'A strength',
          'Only necessary in extreme cases',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'MINDSET',
    title: 'Coping with the Two-Week Wait',
    meta: '4 min read',
    icon: Icons.hourglass_empty_outlined,
    color: AppColors.lavenderLight,
    deep: AppColors.lavender,
    summary:
        'The days between ovulation and your next period can feel like the longest of the month.',
    body: [
      'The "two-week wait" — the stretch between ovulation and when your period is due — is often described as the hardest part of the cycle. Symptom-spotting is common, but very early pregnancy symptoms and normal premenstrual symptoms overlap so much that they usually cannot be told apart by feel alone.',
      'Planning something to look forward to during this window, even something small, can help shift the day-to-day focus away from constant symptom-checking. Some people find it helps to limit how often they search or test; others prefer having a plan for exactly when they will test, so the decision is already made.',
      'Whatever helps you feel steadiest is the right approach — there is no single correct way to get through the wait.',
    ],
    takeaways: [
      'Early pregnancy and PMS symptoms often feel identical.',
      'Planning small distractions can ease the mental load.',
      'There is no single "right" way to get through the wait.',
    ],
    quiz: [
      QuizQuestion(
        question:
            'Why is symptom-spotting during the two-week wait unreliable?',
        options: [
          "Symptoms don't exist that early",
          'Early pregnancy and PMS symptoms often overlap',
          'It only works for some people',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'When does testing give the most accurate result?',
        options: [
          'A week before your period is due',
          'On or after the day your period is due',
          'Right after ovulation',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'EXPERT Q&A',
    title: 'When to See a Fertility Specialist',
    meta: '6 min read',
    icon: Icons.forum_outlined,
    color: AppColors.primaryContainer,
    deep: AppColors.primary,
    summary:
        'General guidance on timing — always paired with your own doctor\'s advice.',
    body: [
      'Common general guidance suggests speaking with a specialist after 12 months of trying if you are under 35, or after 6 months if you are 35 or older, since fertility naturally declines with age. These are general starting points, not hard rules.',
      'Some situations are worth raising sooner — very irregular or absent periods, a known condition like PCOS or endometriosis, previous pelvic surgery, or a partner with a known fertility factor. In these cases, an earlier conversation is often recommended.',
      'A first appointment is usually just information-gathering: cycle history, general health, and sometimes baseline bloodwork. It is a conversation, not a commitment to any particular treatment path.',
    ],
    takeaways: [
      '12 months (under 35) or 6 months (35+) are common general guidelines.',
      'Irregular cycles or known conditions may warrant seeing someone sooner.',
      'A first visit is exploratory, not a commitment to treatment.',
    ],
    quiz: [
      QuizQuestion(
        question:
            'General guidance suggests seeing a specialist after how many months if you are under 35?',
        options: ['3 months', '12 months', '24 months'],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'A first fertility appointment is usually…',
        options: [
          'A commitment to treatment',
          'Exploratory information-gathering',
          'Only for surgery planning',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'EXPERT Q&A',
    title: 'Common Early Pregnancy Signs Explained',
    meta: '5 min read',
    icon: Icons.health_and_safety_outlined,
    color: AppColors.primaryContainer,
    deep: AppColors.primary,
    summary:
        'What is actually early pregnancy, and what is just your regular cycle?',
    body: [
      'Fatigue, tender breasts, mild cramping, and mood shifts are commonly associated with early pregnancy — but every one of them can also show up in a completely ordinary premenstrual week, which is exactly why symptom-spotting is so unreliable on its own.',
      'A missed period is the most useful signal, followed by a home pregnancy test taken on or after the day your period was due for the most accurate result. Testing earlier than that increases the chance of a false negative, even if you are pregnant.',
      'If your test is positive, or if your period is late and a test is negative, reaching out to a healthcare provider is the most reliable next step.',
    ],
    takeaways: [
      'Early pregnancy symptoms overlap heavily with PMS symptoms.',
      'Testing on or after your missed period gives the most accurate result.',
      'A late period with a negative test is worth discussing with a provider.',
    ],
    quiz: [
      QuizQuestion(
        question:
            'Why is symptom-spotting alone an unreliable way to detect pregnancy?',
        options: [
          'Fatigue and tender breasts also happen with regular PMS',
          'Symptoms never occur in early pregnancy',
          'Only a doctor can feel symptoms',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        question:
            'What should you do if your period is late and a test is negative?',
        options: [
          'Wait another month and ignore it',
          'Reach out to a healthcare provider',
          'Test again after 1 hour',
        ],
        correctIndex: 1,
      ),
    ],
  ),
];
