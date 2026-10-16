import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/presentation/learn_content.dart';

/// Mandatory, multi-lesson "force learning" curricula shown at the end of
/// onboarding, one per journey. The user must read each lesson and pass its
/// quiz, in order, before they can reach their dashboard. Content is about
/// the journey itself (conceiving / pregnancy / baby care) — not the app.

const _fpFertileWindow = LearnItem(
  category: 'Conceiving',
  title: 'Understanding Your Fertile Window',
  meta: '3 min read',
  icon: Icons.calendar_month_outlined,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      "Knowing when you're most fertile is the single biggest lever for conceiving faster.",
  body: [
    'Ovulation usually happens around the middle of your cycle — typically day 14 in a 28-day cycle, though this varies a lot from person to person.',
    'Your fertile window is the 5–6 days leading up to and including ovulation, since sperm can survive in the body for several days while the egg is only viable for about 24 hours after release.',
    'Signs like changes in cervical mucus, a slight rise in basal body temperature, or mild ovulation pain can help you recognize where you are in your cycle — tracking them over a few cycles reveals your personal pattern.',
  ],
  takeaways: [
    'The fertile window is about 6 days long, ending on ovulation day.',
    'Cervical mucus and basal body temperature are two of the most accessible ways to spot ovulation.',
    'Tracking for 2–3 cycles gives far more reliable predictions than guessing from a single month.',
  ],
  quiz: [
    QuizQuestion(
      question: 'Roughly how long is the fertile window?',
      options: ['About 6 days', 'About 1 day', 'About 2 weeks'],
      correctIndex: 0,
    ),
    QuizQuestion(
      question: 'Why does tracking multiple cycles improve predictions?',
      options: [
        "It doesn't — one cycle is enough",
        'It reveals your personal pattern, since cycles vary',
        'It changes when ovulation happens',
      ],
      correctIndex: 1,
    ),
  ],
);

const _fpPreparingBody = LearnItem(
  category: 'Conceiving',
  title: 'Preparing Your Body for Conception',
  meta: '3 min read',
  icon: Icons.restaurant_outlined,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      "A few changes before you conceive can support a healthier pregnancy later.",
  body: [
    'Starting a prenatal vitamin with folic acid at least a month before trying to conceive is one of the most well-supported ways to help reduce the risk of certain birth defects.',
    'Reaching and maintaining a healthy weight, eating a balanced diet, and staying active all support fertility and a smoother pregnancy — but changes do not need to be drastic to help.',
    'Cutting back on alcohol, quitting smoking, and reducing caffeine are commonly recommended when trying to conceive. A preconception checkup with your doctor is a great way to get advice tailored to you.',
  ],
  takeaways: [
    'Folic acid is best started before conception, not after a positive test.',
    'Small, sustainable lifestyle changes matter more than drastic short-term ones.',
    'A preconception checkup can catch things worth addressing before you start trying.',
  ],
  quiz: [
    QuizQuestion(
      question: 'When is the best time to start taking folic acid?',
      options: [
        'After a positive pregnancy test',
        'At least a month before trying to conceive',
        'Only in the third trimester',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: "What's a good first step when planning to conceive?",
      options: [
        'Skip all doctor visits until pregnant',
        'A preconception checkup with your doctor',
        'Wait until 6 months pregnant to see a doctor',
      ],
      correctIndex: 1,
    ),
  ],
);

const _fpChartingCycle = LearnItem(
  category: 'Conceiving',
  title: 'Charting & Tracking Your Cycle',
  meta: '3 min read',
  icon: Icons.edit_note_rounded,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary: 'A few simple tracking methods turn guesswork into a clear pattern.',
  body: [
    'Basal body temperature (BBT) rises slightly — about 0.5°F — right after ovulation. Taking your temperature every morning before getting out of bed, at roughly the same time, can reveal this shift over a cycle or two.',
    'Cervical mucus naturally changes through your cycle: it becomes clear, stretchy, and slippery (like raw egg white) right before ovulation, which is often the easiest day-to-day sign to notice.',
    'Ovulation predictor kits (OPKs) test urine for a hormone surge that happens 24–36 hours before ovulation, giving a more direct signal than temperature or mucus alone — many people combine two or more methods for confidence.',
  ],
  takeaways: [
    'BBT confirms ovulation only after it has already happened.',
    'Egg-white-like cervical mucus is a strong sign ovulation is near.',
    'Combining methods (BBT, mucus, OPKs) gives a clearer picture than any one alone.',
  ],
  quiz: [
    QuizQuestion(
      question: 'What happens to basal body temperature after ovulation?',
      options: [
        'It drops sharply',
        'It rises slightly',
        'It stays exactly the same',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: 'What do ovulation predictor kits actually detect?',
      options: [
        'Basal body temperature',
        'A hormone surge before ovulation',
        'The exact day of conception',
      ],
      correctIndex: 1,
    ),
  ],
);

const _fpNutritionLifestyle = LearnItem(
  category: 'Conceiving',
  title: 'Nutrition & Lifestyle That Support Fertility',
  meta: '3 min read',
  icon: Icons.favorite_outline,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      'What you eat, how you move, and how you manage stress all play a role in fertility.',
  body: [
    'A balanced diet with plenty of whole grains, vegetables, healthy fats, and lean protein supports hormone balance for both partners — fertility is not a "just her" issue, and lifestyle changes help on both sides.',
    'Moderate, regular exercise supports a healthy weight and reduces stress, but very intense or excessive exercise can sometimes disrupt ovulation — balance tends to matter more than intensity.',
    'Chronic stress can affect hormone regulation and cycle regularity. Simple habits like consistent sleep, mindfulness, or just carving out downtime can meaningfully support your cycle over time.',
  ],
  takeaways: [
    'Fertility-supporting habits matter for both partners, not just one.',
    'Moderate exercise is generally better for fertility than very intense training.',
    'Managing stress and sleep is a real, practical part of preparing to conceive.',
  ],
  quiz: [
    QuizQuestion(
      question: 'Whose lifestyle habits matter for fertility?',
      options: [
        'Only the partner trying to carry the pregnancy',
        'Both partners',
        "It doesn't affect fertility either way",
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: 'What is true about exercise and fertility?',
      options: [
        'More intense is always better',
        'Moderate, regular exercise tends to be more supportive than very intense training',
        'Exercise has no connection to fertility',
      ],
      correctIndex: 1,
    ),
  ],
);

const _fpWhenToSeekHelp = LearnItem(
  category: 'Conceiving',
  title: 'Knowing When to Seek Expert Help',
  meta: '2 min read',
  icon: Icons.medical_services_outlined,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      "It's common to need more than a few tries — here's when a specialist visit is worth considering.",
  body: [
    'General guidance suggests seeing a fertility specialist after about 12 months of trying under age 35, or after about 6 months if you are 35 or older, since fertility naturally declines with age.',
    'Irregular or absent periods, known conditions like PCOS or endometriosis, or a history of pelvic surgery are reasons to consider seeing a specialist sooner rather than waiting out the full timeline.',
    'Seeking help early is not a sign that something is necessarily wrong — many people conceive with a little extra support, and specialists can often identify simple, addressable factors.',
  ],
  takeaways: [
    'The general guideline is 12 months of trying under 35, or 6 months at 35+.',
    'Irregular cycles or known conditions are reasons to check in sooner.',
    'Seeing a specialist early is proactive, not a last resort.',
  ],
  quiz: [
    QuizQuestion(
      question:
          'For someone under 35, when is it generally suggested to see a specialist?',
      options: [
        'After 1 month of trying',
        'After about 12 months of trying',
        'Only after 5 years',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question:
          'Which of these is a reason to consider seeing a specialist sooner?',
      options: [
        'Having a regular 28-day cycle',
        'A known condition like PCOS',
        'Eating a balanced diet',
      ],
      correctIndex: 1,
    ),
  ],
);

const familyPlanningOrientationLessons = <LearnItem>[
  _fpFertileWindow,
  _fpPreparingBody,
  _fpChartingCycle,
  _fpNutritionLifestyle,
  _fpWhenToSeekHelp,
];

const _pregDevelopment = LearnItem(
  category: 'Pregnancy Care',
  title: "Your Baby's Development, Trimester by Trimester",
  meta: '3 min read',
  icon: Icons.pregnant_woman_outlined,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      'Each trimester brings very different changes for your baby — here is the big picture.',
  body: [
    "The first trimester (weeks 1–13) is when your baby's major organs and body systems begin to form — this is why habits like avoiding alcohol and taking folic acid matter so much early on.",
    "The second trimester (weeks 14–27) is often called the 'golden period' — energy tends to improve, and you may start to feel your baby move for the first time.",
    'The third trimester (weeks 28–40+) is mainly about rapid weight gain and the final systems, like the lungs, maturing in preparation for birth.',
  ],
  takeaways: [
    'Major organs form in the first trimester, making early habits especially important.',
    'Feeling movement usually starts in the second trimester.',
    'The third trimester is about final growth and preparing for delivery.',
  ],
  quiz: [
    QuizQuestion(
      question: "When do a baby's major organs mainly form?",
      options: ['First trimester', 'Second trimester', 'Third trimester'],
      correctIndex: 0,
    ),
    QuizQuestion(
      question: 'What typically happens in the third trimester?',
      options: [
        'Organs first begin forming',
        'Rapid weight gain and final preparation for birth',
        'Nothing significant changes',
      ],
      correctIndex: 1,
    ),
  ],
);

const _pregSelfCare = LearnItem(
  category: 'Pregnancy Care',
  title: 'Taking Care of Yourself and Your Baby',
  meta: '3 min read',
  icon: Icons.restaurant_outlined,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      'Everyday choices during pregnancy add up — here is what matters most.',
  body: [
    "Eating a balanced diet with enough protein, iron, calcium, and folate supports your baby's growth — your prenatal vitamin fills in the gaps, it does not replace the meals.",
    'Alcohol, smoking, and certain raw or unpasteurized foods are best avoided during pregnancy, since they carry real risks to your baby\'s development.',
    'Staying gently active, prioritizing sleep, and managing stress all support a healthier pregnancy — and keeping up with your prenatal appointments lets your provider catch anything that needs attention early.',
  ],
  takeaways: [
    'Prenatal vitamins supplement a balanced diet — they do not replace it.',
    'Alcohol and smoking should be avoided throughout pregnancy.',
    'Regular prenatal visits are how your provider tracks both your and your baby\'s health.',
  ],
  quiz: [
    QuizQuestion(
      question: 'What is the role of a prenatal vitamin?',
      options: [
        'To replace regular meals',
        'To fill nutritional gaps alongside a balanced diet',
        'It has no real purpose',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: 'Which of these is recommended to avoid during pregnancy?',
      options: ['Prenatal appointments', 'Alcohol', 'Gentle exercise'],
      correctIndex: 1,
    ),
  ],
);

const _pregCheckups = LearnItem(
  category: 'Pregnancy Care',
  title: 'Prenatal Care & Checkups',
  meta: '3 min read',
  icon: Icons.medical_services_outlined,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      'Regular checkups are how you and your provider track a healthy pregnancy together.',
  body: [
    'Prenatal visits are typically monthly through week 28, every two weeks from 28–36 weeks, then weekly until delivery — your provider may adjust this based on your individual needs.',
    'A typical visit checks your blood pressure, weight, and urine, and measures fundal height (the size of your belly) to track your baby\'s growth alongside how you are feeling.',
    'Key screenings happen at specific points — like an early blood panel, a mid-pregnancy anatomy ultrasound around 18–20 weeks, and a glucose screening around 24–28 weeks to check for gestational diabetes.',
  ],
  takeaways: [
    'Visit frequency increases as your due date approaches.',
    'Blood pressure, weight, urine, and fundal height are checked at most visits.',
    'Certain screenings, like the anatomy scan and glucose test, happen at specific weeks.',
  ],
  quiz: [
    QuizQuestion(
      question:
          'How does prenatal visit frequency typically change over pregnancy?',
      options: [
        'It stays exactly the same throughout',
        'It increases as you get closer to your due date',
        'It decreases as you get closer to your due date',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question:
          'Around when does the glucose screening for gestational diabetes typically happen?',
      options: ['Weeks 4–6', 'Weeks 24–28', 'Only after delivery'],
      correctIndex: 1,
    ),
  ],
);

const _pregWarningSigns = LearnItem(
  category: 'Pregnancy Care',
  title: 'Warning Signs During Pregnancy',
  meta: '2 min read',
  icon: Icons.info_outline_rounded,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      'Most pregnancies go smoothly, but knowing what warrants a call helps you act quickly when it matters.',
  body: [
    'Vaginal bleeding, severe or persistent abdominal pain, and a sudden increase in swelling in the face or hands are all reasons to contact your provider promptly rather than waiting for your next visit.',
    'A noticeable decrease in your baby\'s movement, especially in the third trimester, is worth checking on — providers often suggest a simple kick-count check when this happens.',
    'Severe headaches, vision changes, or a fever are also signs to call about, since they can occasionally point to conditions like preeclampsia that are much easier to manage when caught early.',
  ],
  takeaways: [
    'Bleeding, severe pain, and sudden swelling all warrant a prompt call to your provider.',
    'A real drop in your baby\'s movement is worth checking, not ignoring.',
    'Severe headaches or vision changes can be early signs worth reporting quickly.',
  ],
  quiz: [
    QuizQuestion(
      question:
          'What should you do if you notice a real decrease in your baby\'s movement?',
      options: [
        'Wait until your next scheduled visit',
        'Check in with your provider',
        'Assume it is always normal',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question:
          'Which combination of symptoms is worth calling your provider about promptly?',
      options: [
        'Mild tiredness and hunger',
        'Severe headache and vision changes',
        'Occasional mild round ligament pain',
      ],
      correctIndex: 1,
    ),
  ],
);

const _pregLaborPrep = LearnItem(
  category: 'Pregnancy Care',
  title: 'Preparing for Labor & Delivery',
  meta: '3 min read',
  icon: Icons.event_note_outlined,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      'A little preparation ahead of time can make labor day feel far less overwhelming.',
  body: [
    'Signs that labor may be starting include regular, strengthening contractions, your water breaking, and losing the mucus plug — though every labor looks a little different, and timing contractions helps you know when to head in.',
    'A birth plan is simply a way to think through and communicate your preferences — pain management options, who you want in the room, and how you feel about interventions — while staying flexible, since plans often need to adapt.',
    'Pain management options range from breathing and movement techniques to an epidural or other medication — there is no single right choice, and it is worth learning about the options before you are in the moment.',
  ],
  takeaways: [
    'Regular, strengthening contractions are a key sign true labor has started.',
    'A birth plan is a communication tool, not a guarantee — flexibility matters.',
    'Learning about pain management options ahead of time makes decisions easier in the moment.',
  ],
  quiz: [
    QuizQuestion(
      question: 'What is a birth plan mainly useful for?',
      options: [
        'Guaranteeing exactly how delivery will go',
        'Communicating your preferences while staying flexible',
        'Replacing conversations with your provider',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: 'Which of these is a sign labor may be starting?',
      options: [
        'Regular, strengthening contractions',
        'Feeling your baby hiccup',
        'A single mild cramp',
      ],
      correctIndex: 0,
    ),
  ],
);

const pregnancyOrientationLessons = <LearnItem>[
  _pregDevelopment,
  _pregSelfCare,
  _pregCheckups,
  _pregWarningSigns,
  _pregLaborPrep,
];

const _babyNewbornBasics = LearnItem(
  category: 'Baby Care',
  title: 'Newborn Care Basics',
  meta: '3 min read',
  icon: Icons.child_care_outlined,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary: 'A few fundamentals cover most of what a newborn needs day to day.',
  body: [
    'Newborns typically feed 8–12 times a day, whether breast or bottle fed — feeding on cues like rooting or hand-to-mouth movements, rather than a strict clock, is generally recommended.',
    'Safe sleep guidance is consistent: always place babies on their back to sleep, on a firm flat surface, with no loose bedding, pillows, or soft toys in the crib.',
    'Frequent diaper changes, gentle bathing a few times a week (not daily), and keeping the umbilical cord area clean and dry are the basics of newborn hygiene.',
  ],
  takeaways: [
    'Feed on cues, not a strict schedule, especially in the early weeks.',
    'Back to sleep, on a firm surface, with nothing loose in the crib — every time.',
    'Newborns do not need a daily bath — a few times a week is usually enough.',
  ],
  quiz: [
    QuizQuestion(
      question: 'What position should a newborn be placed in to sleep?',
      options: ['On their stomach', 'On their back', 'On their side'],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: 'How often do newborns typically need to feed?',
      options: [
        'Once every 6 hours',
        '8–12 times a day',
        'Only when they cry loudly',
      ],
      correctIndex: 1,
    ),
  ],
);

const _babyGrowthExpectations = LearnItem(
  category: 'Baby Care',
  title: 'Growth, Milestones & What to Expect',
  meta: '2 min read',
  icon: Icons.emoji_events_outlined,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      'Every baby grows at their own pace — here is how to think about the ranges you will see.',
  body: [
    'Growth charts compare your baby\'s weight, height, and head circumference to general population reference ranges — they are a helpful signal, not a diagnosis or a race to hit a number.',
    'Milestones like smiling, rolling, sitting, and walking each have a typical age range rather than a fixed date, because development naturally varies from baby to baby.',
    'Consistent tracking helps you and your pediatrician spot meaningful patterns over time — a single measurement matters far less than the overall trend.',
  ],
  takeaways: [
    'Growth percentiles are a reference point, not a diagnosis.',
    'Milestones happen within a range, not on a fixed schedule.',
    'Trends over time matter more than any single logged entry.',
  ],
  quiz: [
    QuizQuestion(
      question: 'What do growth charts actually show?',
      options: [
        'A diagnosis of a health problem',
        'A general reference range, not a diagnosis',
        'The exact date of every milestone',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: 'Why do milestones have an age range instead of a single date?',
      options: [
        'Because development naturally varies between babies',
        "Because it can't be calculated precisely",
        'Milestones do not actually have typical ages',
      ],
      correctIndex: 0,
    ),
  ],
);

const _babyFeeding = LearnItem(
  category: 'Baby Care',
  title: 'Feeding Your Baby',
  meta: '3 min read',
  icon: Icons.restaurant_outlined,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      'Breast, bottle, or both — here is what tends to help feeding go smoothly.',
  body: [
    'A good latch is the foundation of comfortable breastfeeding: baby\'s mouth should cover a wide portion of the areola, not just the nipple, with lips flanged outward rather than tucked in.',
    'Bottle-fed babies do best with paced feeding — holding the bottle more horizontally and pausing occasionally — which helps prevent overfeeding and mimics the natural rhythm of breastfeeding.',
    'Burping halfway through and after a feed helps release swallowed air, which can otherwise cause fussiness or spit-up. Common positions include over the shoulder, sitting upright, or face-down across the lap.',
  ],
  takeaways: [
    'A wide, deep latch makes breastfeeding more comfortable and effective.',
    'Paced bottle feeding helps prevent overfeeding.',
    'Burping midway and after a feed reduces fussiness from swallowed air.',
  ],
  quiz: [
    QuizQuestion(
      question: 'What does a good breastfeeding latch generally look like?',
      options: [
        'Mouth covering only the nipple',
        'Mouth covering a wide portion of the areola',
        'Lips tucked tightly inward',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: 'What is the purpose of paced bottle feeding?',
      options: [
        'To feed as fast as possible',
        'To help prevent overfeeding',
        'To skip burping entirely',
      ],
      correctIndex: 1,
    ),
  ],
);

const _babySoothingBonding = LearnItem(
  category: 'Baby Care',
  title: 'Soothing & Bonding with Your Baby',
  meta: '2 min read',
  icon: Icons.favorite_outline,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      'Simple, consistent responses help your baby feel secure — and help you feel more confident.',
  body: [
    'Skin-to-skin contact helps regulate a newborn\'s heart rate, temperature, and breathing, while also supporting bonding — it is one of the simplest, most effective calming tools available at any age in the first months.',
    'Crying is a baby\'s main way of communicating, not a problem to fix instantly — working through a quick checklist (hungry, wet, tired, too hot or cold, wants to be held) covers most causes.',
    'Some fussiness, especially in the evenings, is common and often called colic when it is frequent and intense — it usually peaks around 6 weeks and improves by 3–4 months, and does not mean you are doing something wrong.',
  ],
  takeaways: [
    'Skin-to-skin contact is a genuinely effective, evidence-based soothing tool.',
    'A quick needs checklist covers most reasons a baby cries.',
    'Colic-type fussiness is common and typically improves by 3–4 months.',
  ],
  quiz: [
    QuizQuestion(
      question: 'What does skin-to-skin contact help regulate in a newborn?',
      options: [
        'Heart rate, temperature, and breathing',
        'Eye color',
        'Growth charts',
      ],
      correctIndex: 0,
    ),
    QuizQuestion(
      question: 'When does colic-type fussiness typically improve?',
      options: [
        'It never improves',
        'By about 3–4 months',
        'Immediately after birth',
      ],
      correctIndex: 1,
    ),
  ],
);

const _babySafety = LearnItem(
  category: 'Baby Care',
  title: 'Keeping Your Baby Safe',
  meta: '2 min read',
  icon: Icons.info_outline_rounded,
  color: AppColors.primary,
  deep: AppColors.secondary,
  summary:
      'A handful of safety habits prevent the vast majority of common accidents.',
  body: [
    'A rear-facing car seat, installed correctly and used on every single ride, is one of the most important safety habits from day one — many fire and police stations offer free installation checks.',
    'Small objects, cords, and plastic bags should be kept out of reach, since choking and strangulation are common hazards for curious babies as they start exploring with their hands and mouths.',
    'Never leave a baby unattended in or near water — even a few inches, like in a bath — since drowning can happen silently and in seconds.',
  ],
  takeaways: [
    'Correct, consistent car seat use is one of the highest-impact safety habits.',
    'Small objects and cords are common choking and strangulation hazards.',
    'Never leave a baby alone in or near any amount of water.',
  ],
  quiz: [
    QuizQuestion(
      question: 'How should a car seat be used for a newborn?',
      options: [
        'Forward-facing, used occasionally',
        'Rear-facing, installed correctly and used every ride',
        'Only required after 1 year old',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: 'What is true about babies and water?',
      options: [
        'They should never be left unattended in or near it',
        'A few inches of water is always safe to step away from',
        'Drowning risk only applies to pools',
      ],
      correctIndex: 0,
    ),
  ],
);

const babyCareOrientationLessons = <LearnItem>[
  _babyNewbornBasics,
  _babyGrowthExpectations,
  _babyFeeding,
  _babySoothingBonding,
  _babySafety,
];
