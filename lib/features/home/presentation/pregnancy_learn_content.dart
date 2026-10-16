import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'learn_content.dart';

/// Pregnancy-track lessons, shown on the pregnancy dashboard's "Learn & grow"
/// section and its learn library. Uses the same [LearnItem]/[QuizQuestion]
/// model and [LearnProgress] completion tracker as the family-planning
/// lessons, so quiz-gated completion works identically for both tracks.
const allPregnancyLearnItems = <LearnItem>[
  LearnItem(
    category: 'NUTRITION',
    title: 'Eating Well During Pregnancy',
    meta: '4 min read',
    icon: Icons.restaurant_outlined,
    color: AppColors.primary,
    deep: AppColors.secondary,
    summary:
        'A handful of nutrients matter more than usual right now — here is what to focus on.',
    body: [
      'Folate (or folic acid) supports your baby\'s early neural development, iron helps your body make extra blood for both of you, and calcium and vitamin D support bone development. Most prenatal vitamins are built around covering these specific gaps.',
      'Protein needs also rise during pregnancy — eggs, beans, lean meat, fish (in safe amounts), and dairy are all good everyday sources. There is no need to "eat for two" in terms of quantity; your calorie needs only increase modestly, especially in the first trimester.',
      'If nausea makes bigger meals hard, smaller and more frequent meals throughout the day are a perfectly good substitute — consistency matters more than any single perfect plate.',
    ],
    takeaways: [
      'Folate, iron, calcium, and vitamin D are priority nutrients.',
      'Protein needs increase, but overall calorie needs rise only modestly.',
      'Small, frequent meals are a fine substitute for three big ones.',
    ],
    quiz: [
      QuizQuestion(
        question:
            'Which nutrient is especially important for early neural development?',
        options: ['Folate', 'Vitamin C', 'Fiber'],
        correctIndex: 0,
      ),
      QuizQuestion(
        question:
            'How much do overall calorie needs typically change during pregnancy?',
        options: ['They double', 'They rise only modestly', 'They decrease'],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'NUTRITION',
    title: 'Foods and Drinks to Limit',
    meta: '3 min read',
    icon: Icons.no_food_outlined,
    color: AppColors.primary,
    deep: AppColors.secondary,
    summary:
        'A short, practical list of what to be cautious with while pregnant.',
    body: [
      'Raw or undercooked meat, fish, and eggs, along with unpasteurized dairy and soft cheeses, carry a higher risk of foodborne illness during pregnancy. High-mercury fish like swordfish and king mackerel are best avoided, while lower-mercury options like salmon are generally fine in moderation.',
      'Alcohol has no known safe amount during pregnancy, so most guidance is to avoid it entirely. Caffeine is generally considered fine in moderation — most providers suggest keeping it under about 200mg a day, roughly one 12oz cup of coffee.',
      'None of this needs to feel overwhelming — a slip-up here and there is common and rarely a cause for concern. Consistency over the weeks and months is what matters most.',
    ],
    takeaways: [
      'Avoid raw/undercooked proteins, unpasteurized dairy, and high-mercury fish.',
      'Alcohol is best avoided entirely; caffeine in moderation is generally fine.',
      'An occasional slip-up is common and rarely something to worry about.',
    ],
    quiz: [
      QuizQuestion(
        question:
            'Which of these is generally recommended to avoid entirely during pregnancy?',
        options: ['Alcohol', 'Pasteurized dairy', 'Cooked salmon'],
        correctIndex: 0,
      ),
      QuizQuestion(
        question: 'What is a common caffeine guideline during pregnancy?',
        options: [
          'No limit at all',
          'About 200mg a day (~1 cup of coffee)',
          'Zero caffeine allowed',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'SYMPTOMS',
    title: 'Understanding Morning Sickness',
    meta: '4 min read',
    icon: Icons.sick_outlined,
    color: AppColors.secondary,
    deep: AppColors.lavenderLight,
    summary:
        'Despite the name, it can happen any time of day — here is why, and what helps.',
    body: [
      'Morning sickness is thought to be linked to rising pregnancy hormones, and it typically peaks between weeks 6 and 12 before easing for most people by the second trimester. Despite the name, it can strike at any time of day.',
      'Small, frequent meals, ginger (in tea, candies, or capsules), staying hydrated, and avoiding strong smells or an empty stomach can all help. Some people find bland, carb-heavy foods like crackers easiest to tolerate, especially first thing in the morning.',
      'If you cannot keep fluids down for more than a day, are losing weight, or symptoms feel severe, reach out to your provider — this can be a sign of hyperemesis gravidarum, which is manageable with the right care.',
    ],
    takeaways: [
      'Morning sickness usually peaks around weeks 6–12.',
      'Small meals, ginger, and hydration are common first-line remedies.',
      'Severe or persistent vomiting is worth calling your provider about.',
    ],
    quiz: [
      QuizQuestion(
        question: 'When does morning sickness typically peak?',
        options: ['Weeks 6–12', 'Weeks 20–24', 'Only in the third trimester'],
        correctIndex: 0,
      ),
      QuizQuestion(
        question: 'When should you contact your provider about nausea?',
        options: [
          'Anytime you feel slightly queasy',
          'If you cannot keep fluids down for more than a day',
          'Only after week 30',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'SYMPTOMS',
    title: 'Managing Back and Ligament Pain',
    meta: '3 min read',
    icon: Icons.accessibility_new_outlined,
    color: AppColors.secondary,
    deep: AppColors.lavenderLight,
    summary:
        'Your changing shape and stretching ligaments can bring new aches — here is why, and how to ease them.',
    body: [
      'As your uterus grows, your center of gravity shifts and your posture adjusts to compensate, which can strain your lower back. Round ligament pain — a sharp or achy pull, usually on one or both sides of the lower belly — comes from the ligaments supporting your uterus stretching as it grows.',
      'Gentle movement like walking or prenatal yoga, supportive shoes, sleeping with a pillow between your knees, and applying warmth to sore areas can all help. A maternity support belt can also relieve pressure for some people.',
      'Sudden, severe pain, pain with fever, or pain accompanied by bleeding is different from typical stretching discomfort and is worth calling your provider about.',
    ],
    takeaways: [
      'Back pain often comes from postural shifts as your body changes.',
      'Round ligament pain is a normal stretching sensation, usually one-sided.',
      'Severe, sudden pain — especially with fever or bleeding — needs a call to your provider.',
    ],
    quiz: [
      QuizQuestion(
        question: 'What typically causes round ligament pain?',
        options: [
          'Ligaments stretching as the uterus grows',
          'A pulled muscle from exercise',
          'Low iron levels',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        question:
            'Which symptom combination is worth calling your provider about?',
        options: [
          'Mild one-sided ache after a long walk',
          'Severe pain with fever or bleeding',
          'Slight backache in the evening',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'PREPARATION',
    title: 'Building Your Hospital Bag',
    meta: '4 min read',
    icon: Icons.luggage_outlined,
    color: AppColors.lavenderLight,
    deep: AppColors.lavender,
    summary:
        'Most providers suggest having your bag ready by around week 35–36.',
    body: [
      'For yourself: comfortable clothes, a phone charger (with a long cord), toiletries, your ID and insurance information, and something comfortable to wear home — your body won\'t look "pre-pregnancy" right away, so looser clothing helps.',
      'For your baby: an outfit for the ride home appropriate for the season, a couple of swaddles or blankets, and a properly installed car seat (many hospitals check this before discharge).',
      'For your support person: snacks, a change of clothes, and entertainment for what can be a long wait. Packing a little early — around week 35–36 — means one less thing to think about if baby decides to arrive ahead of schedule.',
    ],
    takeaways: [
      'Aim to have your bag packed by around week 35–36.',
      'Pack for yourself, your baby, and your support person separately.',
      'A properly installed car seat is often checked before hospital discharge.',
    ],
    quiz: [
      QuizQuestion(
        question:
            'By around what week do most providers suggest having your hospital bag ready?',
        options: ['Week 20', 'Week 35–36', 'Week 42'],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'What do many hospitals check before discharge?',
        options: [
          'Your car\'s fuel level',
          'That the car seat is properly installed',
          'Your home Wi-Fi',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'PREPARATION',
    title: 'Understanding Your Birth Plan Options',
    meta: '5 min read',
    icon: Icons.assignment_outlined,
    color: AppColors.lavenderLight,
    deep: AppColors.lavender,
    summary:
        'A birth plan is a conversation starter with your care team, not a fixed contract.',
    body: [
      'A birth plan typically covers things like your preferred pain-management approach, who you want in the room, positions you would like to try during labor, and preferences around skin-to-skin contact and feeding right after birth.',
      'It is worth writing down what matters most to you and discussing it with your provider well before your due date, so everyone understands your preferences going in. That said, birth is unpredictable, and plans sometimes need to change for your safety or your baby\'s — flexibility is part of the process, not a failure of planning.',
      'Many providers suggest keeping your plan to one page and focusing on your top priorities rather than every possible detail, so it is easy for a busy labor and delivery team to reference quickly.',
    ],
    takeaways: [
      'A birth plan covers pain management, support people, positions, and postpartum preferences.',
      'Discuss it with your provider well ahead of your due date.',
      'Flexibility matters — plans may need to adapt for safety.',
    ],
    quiz: [
      QuizQuestion(
        question: 'What is a birth plan best thought of as?',
        options: [
          'A fixed contract that cannot change',
          'A conversation starter with your care team',
          'A legal document',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'Why might a birth plan need to change during labor?',
        options: [
          'It is required to change',
          'For your or your baby\'s safety',
          'Hospitals discourage having one',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  LearnItem(
    category: 'WELLNESS',
    title: 'Safe Exercise During Pregnancy',
    meta: '4 min read',
    icon: Icons.self_improvement_outlined,
    color: AppColors.primaryContainer,
    deep: AppColors.primary,
    summary:
        'Staying active can ease many common pregnancy discomforts — here is how to do it safely.',
    body: [
      'For most low-risk pregnancies, staying active is encouraged. Walking, swimming, stationary cycling, and prenatal yoga are all generally considered safe and can help with energy, sleep, mood, and some of the aches that come with pregnancy.',
      'A few things to avoid: contact sports, activities with a high fall risk, exercises lying flat on your back after the first trimester (this can reduce blood flow), and anything that leaves you overheated or unable to hold a conversation.',
      'If you were active before pregnancy, you can generally continue at a similar intensity with your provider\'s okay. If you are starting fresh, easing in gently is the better approach — this is a good one to discuss at a prenatal visit.',
    ],
    takeaways: [
      'Walking, swimming, and prenatal yoga are generally safe activities.',
      'Avoid contact sports, high fall-risk activities, and flat-on-back exercises after the first trimester.',
      'Check with your provider, especially if you are new to exercise.',
    ],
    quiz: [
      QuizQuestion(
        question:
            'Which of these is generally considered a safe pregnancy exercise?',
        options: ['Contact sports', 'Swimming', 'High-fall-risk activities'],
        correctIndex: 1,
      ),
      QuizQuestion(
        question:
            'Why is exercising flat on your back discouraged after the first trimester?',
        options: [
          'It can reduce blood flow',
          'It burns too many calories',
          'It is against hospital policy',
        ],
        correctIndex: 0,
      ),
    ],
  ),
  LearnItem(
    category: 'EXPERT Q&A',
    title: 'When to Call Your Provider',
    meta: '5 min read',
    icon: Icons.local_hospital_outlined,
    color: AppColors.primaryContainer,
    deep: AppColors.primary,
    summary:
        'Most pregnancy symptoms are ordinary, but a few warning signs deserve a prompt call.',
    body: [
      'Vaginal bleeding, severe or persistent headaches, sudden swelling in your face or hands, vision changes, and a fever above 100.4°F (38°C) are all reasons to call your provider promptly rather than waiting for your next scheduled visit.',
      'A noticeable decrease in your baby\'s movement — especially from the third trimester onward, once movement patterns are established — is also worth calling about. Providers would always rather hear from you and rule something out than have you wait.',
      'Most day-to-day discomforts (mild swelling, occasional headaches, fatigue) are a normal part of pregnancy. The distinction is usually about severity and suddenness — a gradual, mild symptom is different from something sudden or severe.',
    ],
    takeaways: [
      'Bleeding, severe headaches, sudden swelling, vision changes, and fever are prompt-call symptoms.',
      'A noticeable drop in fetal movement is worth calling about.',
      'When in doubt, providers would rather you call than wait it out.',
    ],
    quiz: [
      QuizQuestion(
        question: 'Which of these is a reason to call your provider promptly?',
        options: [
          'Mild fatigue in the afternoon',
          'Sudden swelling in your face or hands',
          'Occasional mild headache',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question:
            'What should you do if your baby\'s movement noticeably decreases?',
        options: [
          'Wait until your next scheduled visit',
          'Call your provider',
          'Assume it is nothing',
        ],
        correctIndex: 1,
      ),
    ],
  ),
];
