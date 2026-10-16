/// Approximate average fetal size and development notes for one pregnancy
/// week. Figures are general published averages (the same kind shown across
/// most pregnancy trackers) meant to give a sense of scale — not a clinical
/// measurement. Every pregnancy varies; a provider's own measurements are
/// always the accurate ones.
class PregnancyWeekInfo {
  const PregnancyWeekInfo({
    required this.week,
    required this.sizeComparison,
    required this.emoji,
    required this.lengthCm,
    required this.weightG,
    required this.facts,
  });

  final int week;
  final String sizeComparison;
  final String emoji;
  final double lengthCm;

  /// Null for the earliest weeks, before there's a meaningful weight to show.
  final double? weightG;
  final List<String> facts;
}

/// Looks up content for [week], clamping into the 1–42 range the app stores
/// `pregnancy_current_week` in, so an out-of-range value never crashes.
PregnancyWeekInfo pregnancyWeekInfo(int week) =>
    pregnancyWeeklyContent[week.clamp(1, 42) - 1];

const List<PregnancyWeekInfo> pregnancyWeeklyContent = [
  PregnancyWeekInfo(
    week: 1,
    sizeComparison: 'a poppy seed',
    emoji: '🌱',
    lengthCm: 0.1,
    weightG: null,
    facts: [
      'Pregnancy is dated from the first day of your last period, so conception hasn\'t happened yet.',
      'This week is mostly about your body preparing to ovulate.',
    ],
  ),
  PregnancyWeekInfo(
    week: 2,
    sizeComparison: 'a poppy seed',
    emoji: '🌱',
    lengthCm: 0.1,
    weightG: null,
    facts: [
      'Ovulation typically happens around now, and conception may occur if sperm meets egg.',
      'If fertilized, the egg begins its journey toward the uterus.',
    ],
  ),
  PregnancyWeekInfo(
    week: 3,
    sizeComparison: 'a chia seed',
    emoji: '🌱',
    lengthCm: 0.1,
    weightG: null,
    facts: [
      'A fertilized egg is now a rapidly dividing ball of cells called a blastocyst.',
      'It is traveling toward the uterus to implant over the next few days.',
    ],
  ),
  PregnancyWeekInfo(
    week: 4,
    sizeComparison: 'a poppy seed',
    emoji: '🌱',
    lengthCm: 0.1,
    weightG: null,
    facts: [
      'Implantation in the uterine lining is happening or just finished.',
      'The cells that will become the placenta and embryo are starting to separate.',
    ],
  ),
  PregnancyWeekInfo(
    week: 5,
    sizeComparison: 'a sesame seed',
    emoji: '🌱',
    lengthCm: 0.13,
    weightG: null,
    facts: [
      'The neural tube, which becomes the brain and spinal cord, begins forming.',
      'The heart starts as a simple tube that will soon begin to beat.',
    ],
  ),
  PregnancyWeekInfo(
    week: 6,
    sizeComparison: 'a lentil',
    emoji: '🫘',
    lengthCm: 0.5,
    weightG: null,
    facts: [
      'A heartbeat may become detectable on an early ultrasound around now.',
      'Tiny buds that will become arms and legs are appearing.',
    ],
  ),
  PregnancyWeekInfo(
    week: 7,
    sizeComparison: 'a blueberry',
    emoji: '🫐',
    lengthCm: 1.3,
    weightG: 1,
    facts: [
      'The brain is producing about 100 new cells every minute.',
      'Tiny hand and foot paddles are starting to form on the limb buds.',
    ],
  ),
  PregnancyWeekInfo(
    week: 8,
    sizeComparison: 'a raspberry',
    emoji: '🍓',
    lengthCm: 1.6,
    weightG: 1,
    facts: [
      'All essential organs have begun to form, though they still have a lot of developing to do.',
      'Fingers and toes are starting to separate from webbed hand and foot shapes.',
    ],
  ),
  PregnancyWeekInfo(
    week: 9,
    sizeComparison: 'a grape',
    emoji: '🍇',
    lengthCm: 2.3,
    weightG: 2,
    facts: [
      'The embryo is now officially referred to as a fetus.',
      'Tiny tooth buds are forming beneath the gums.',
    ],
  ),
  PregnancyWeekInfo(
    week: 10,
    sizeComparison: 'a strawberry',
    emoji: '🍓',
    lengthCm: 3.1,
    weightG: 4,
    facts: [
      'Vital organs — kidneys, intestines, brain, and liver — are functioning in a basic way.',
      'Fingernails are beginning to form.',
    ],
  ),
  PregnancyWeekInfo(
    week: 11,
    sizeComparison: 'a fig',
    emoji: '🍈',
    lengthCm: 4.1,
    weightG: 7,
    facts: [
      'Tiny tooth buds and bone start to replace cartilage.',
      'The head still makes up about half of total body length.',
    ],
  ),
  PregnancyWeekInfo(
    week: 12,
    sizeComparison: 'a lime',
    emoji: '🍋',
    lengthCm: 5.4,
    weightG: 14,
    facts: [
      'Reflexes are developing — tiny movements may be starting, though you likely can\'t feel them yet.',
      'Vocal cords are beginning to develop this week.',
    ],
  ),
  PregnancyWeekInfo(
    week: 13,
    sizeComparison: 'a lemon',
    emoji: '🍋',
    lengthCm: 7.4,
    weightG: 23,
    facts: [
      'This marks the end of the first trimester for most pregnancies.',
      'Unique fingerprints are forming on tiny fingertips.',
    ],
  ),
  PregnancyWeekInfo(
    week: 14,
    sizeComparison: 'a peach',
    emoji: '🍑',
    lengthCm: 8.7,
    weightG: 43,
    facts: [
      'Facial muscles are developed enough for small expressions like squinting or frowning.',
      'The kidneys are producing urine, released into the surrounding amniotic fluid.',
    ],
  ),
  PregnancyWeekInfo(
    week: 15,
    sizeComparison: 'an apple',
    emoji: '🍎',
    lengthCm: 10.1,
    weightG: 70,
    facts: [
      'Bones are hardening, especially in the legs and arms.',
      'Taste buds are starting to form.',
    ],
  ),
  PregnancyWeekInfo(
    week: 16,
    sizeComparison: 'an avocado',
    emoji: '🥑',
    lengthCm: 11.6,
    weightG: 100,
    facts: [
      'Some parents begin to feel the first faint flutters of movement around now.',
      'The circulatory system and urinary tract are fully functioning.',
    ],
  ),
  PregnancyWeekInfo(
    week: 17,
    sizeComparison: 'a turnip',
    emoji: '🥔',
    lengthCm: 13.0,
    weightG: 140,
    facts: [
      'A protective, waxy coating called vernix caseosa is starting to form on the skin.',
      'The skeleton is shifting from soft cartilage to firmer bone.',
    ],
  ),
  PregnancyWeekInfo(
    week: 18,
    sizeComparison: 'a bell pepper',
    emoji: '🫑',
    lengthCm: 14.2,
    weightG: 190,
    facts: [
      'The ears are now in their final position, and hearing is beginning to develop.',
      'Movements may be strong enough for you to notice them regularly now.',
    ],
  ),
  PregnancyWeekInfo(
    week: 19,
    sizeComparison: 'a mango',
    emoji: '🥭',
    lengthCm: 15.3,
    weightG: 240,
    facts: [
      'A fine, downy hair called lanugo may cover the body for warmth.',
      'Sensory development is speeding up — touch, taste, and hearing are all progressing.',
    ],
  ),
  PregnancyWeekInfo(
    week: 20,
    sizeComparison: 'a banana',
    emoji: '🍌',
    lengthCm: 16.4,
    weightG: 300,
    facts: [
      'You have likely reached the halfway point of your pregnancy.',
      'An anatomy ultrasound around this week checks growth and development in detail.',
    ],
  ),
  PregnancyWeekInfo(
    week: 21,
    sizeComparison: 'a carrot',
    emoji: '🥕',
    lengthCm: 26.7,
    weightG: 360,
    facts: [
      'Measurements now switch from crown-to-rump to full head-to-heel length.',
      'Eyebrows and eyelids are fully formed.',
    ],
  ),
  PregnancyWeekInfo(
    week: 22,
    sizeComparison: 'a papaya',
    emoji: '🥭',
    lengthCm: 27.8,
    weightG: 430,
    facts: [
      'Lips, eyelids, and tiny tooth buds are all clearly formed.',
      'The sense of touch continues to develop as movements become more coordinated.',
    ],
  ),
  PregnancyWeekInfo(
    week: 23,
    sizeComparison: 'a large mango',
    emoji: '🥭',
    lengthCm: 28.9,
    weightG: 501,
    facts: [
      'Blood vessels in the lungs are developing to prepare for breathing air one day.',
      'Hearing is sharpening — loud noises may cause a startle response.',
    ],
  ),
  PregnancyWeekInfo(
    week: 24,
    sizeComparison: 'an ear of corn',
    emoji: '🌽',
    lengthCm: 30.0,
    weightG: 600,
    facts: [
      'This week is often considered a milestone for viability with intensive medical care, should birth happen early.',
      'Taste buds are developed enough to respond to flavors in amniotic fluid.',
    ],
  ),
  PregnancyWeekInfo(
    week: 25,
    sizeComparison: 'a rutabaga',
    emoji: '🥔',
    lengthCm: 34.6,
    weightG: 660,
    facts: [
      'Capillaries are forming, and skin is starting to look less translucent.',
      'Hands are fully developed and may explore by grasping the umbilical cord.',
    ],
  ),
  PregnancyWeekInfo(
    week: 26,
    sizeComparison: 'a head of lettuce',
    emoji: '🥬',
    lengthCm: 35.6,
    weightG: 760,
    facts: [
      'Eyes are beginning to open after being fused shut for months.',
      'Footprints and fingerprints are now fully formed.',
    ],
  ),
  PregnancyWeekInfo(
    week: 27,
    sizeComparison: 'a head of broccoli',
    emoji: '🥦',
    lengthCm: 36.6,
    weightG: 875,
    facts: [
      'This marks the start of the third trimester for most pregnancies.',
      'Sleep and wake cycles are becoming more regular.',
    ],
  ),
  PregnancyWeekInfo(
    week: 28,
    sizeComparison: 'an eggplant',
    emoji: '🍆',
    lengthCm: 37.6,
    weightG: 1005,
    facts: [
      'Eyes can now open and close, and may respond to light from outside the womb.',
      'Rapid brain development continues, with the brain\'s surface starting to develop its folds.',
    ],
  ),
  PregnancyWeekInfo(
    week: 29,
    sizeComparison: 'a butternut squash',
    emoji: '🎃',
    lengthCm: 38.6,
    weightG: 1153,
    facts: [
      'Muscles and lungs continue maturing quickly this trimester.',
      'Head growth is accelerating to make room for a rapidly developing brain.',
    ],
  ),
  PregnancyWeekInfo(
    week: 30,
    sizeComparison: 'a cabbage',
    emoji: '🥬',
    lengthCm: 39.9,
    weightG: 1319,
    facts: [
      'Bone marrow has fully taken over red blood cell production.',
      'Amniotic fluid volume is at its peak, giving plenty of room to move.',
    ],
  ),
  PregnancyWeekInfo(
    week: 31,
    sizeComparison: 'a coconut',
    emoji: '🥥',
    lengthCm: 41.1,
    weightG: 1502,
    facts: [
      'Most major organs are maturing well, though the lungs still have growing to do.',
      'Movements may feel less like flutters and more like distinct kicks and rolls.',
    ],
  ),
  PregnancyWeekInfo(
    week: 32,
    sizeComparison: 'a jicama',
    emoji: '🥔',
    lengthCm: 42.4,
    weightG: 1702,
    facts: [
      'Toenails and fingernails have grown in fully.',
      'Practice breathing movements are becoming more frequent.',
    ],
  ),
  PregnancyWeekInfo(
    week: 33,
    sizeComparison: 'a pineapple',
    emoji: '🍍',
    lengthCm: 43.7,
    weightG: 1918,
    facts: [
      'The skull bones stay soft and separate to make passage through the birth canal easier.',
      'The immune system is strengthening with antibodies passed from you.',
    ],
  ),
  PregnancyWeekInfo(
    week: 34,
    sizeComparison: 'a cantaloupe',
    emoji: '🍈',
    lengthCm: 45.0,
    weightG: 2146,
    facts: [
      'Central nervous system and lungs continue to mature rapidly.',
      'Most babies settle into a head-down position around now, though there is still time to shift.',
    ],
  ),
  PregnancyWeekInfo(
    week: 35,
    sizeComparison: 'a honeydew melon',
    emoji: '🍈',
    lengthCm: 46.2,
    weightG: 2383,
    facts: [
      'Kidneys are fully developed, and the liver can process some waste products.',
      'Growth is focusing on gaining weight and body fat in preparation for birth.',
    ],
  ),
  PregnancyWeekInfo(
    week: 36,
    sizeComparison: 'a head of romaine lettuce',
    emoji: '🥬',
    lengthCm: 47.4,
    weightG: 2622,
    facts: [
      'Most babies are considered "early term" starting next week.',
      'The protective vernix coating and downy lanugo hair are largely shed.',
    ],
  ),
  PregnancyWeekInfo(
    week: 37,
    sizeComparison: 'a bunch of swiss chard',
    emoji: '🥬',
    lengthCm: 48.6,
    weightG: 2859,
    facts: [
      'Your baby is now considered early term — the lungs and brain are still finishing up important development.',
      'A strong grip reflex is well established by this point.',
    ],
  ),
  PregnancyWeekInfo(
    week: 38,
    sizeComparison: 'a leek',
    emoji: '🥬',
    lengthCm: 49.8,
    weightG: 3083,
    facts: [
      'Your baby is considered full term starting this week.',
      'The digestive system has produced meconium, the first stool after birth.',
    ],
  ),
  PregnancyWeekInfo(
    week: 39,
    sizeComparison: 'a mini watermelon',
    emoji: '🍉',
    lengthCm: 50.7,
    weightG: 3288,
    facts: [
      'The brain and lungs continue maturing right up until birth.',
      'Fat continues to accumulate, helping with temperature regulation after birth.',
    ],
  ),
  PregnancyWeekInfo(
    week: 40,
    sizeComparison: 'a small watermelon',
    emoji: '🍉',
    lengthCm: 51.2,
    weightG: 3462,
    facts: [
      'This is your official due date — though only a small share of babies actually arrive exactly on it.',
      'Your baby is ready for life outside the womb.',
    ],
  ),
  PregnancyWeekInfo(
    week: 41,
    sizeComparison: 'a jackfruit',
    emoji: '🍈',
    lengthCm: 51.5,
    weightG: 3600,
    facts: [
      'Going past your due date is common and usually not a cause for concern on its own.',
      'Your provider will likely monitor you and your baby more closely from here.',
    ],
  ),
  PregnancyWeekInfo(
    week: 42,
    sizeComparison: 'a large pumpkin',
    emoji: '🎃',
    lengthCm: 51.7,
    weightG: 3700,
    facts: [
      'Most providers discuss inducing labor around this point if it hasn\'t started on its own.',
      'Your baby is fully developed and ready to meet you.',
    ],
  ),
];
