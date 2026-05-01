class NutrientReference {
  const NutrientReference({
    required this.code,
    required this.name,
    required this.group,
    required this.dailyTarget,
    required this.unit,
    required this.summary,
    required this.benefits,
    required this.lowNote,
  });

  final String code;
  final String name;
  final String group;
  final double dailyTarget;
  final String unit;
  final String summary;
  final List<String> benefits;
  final String lowNote;

  String get targetLabel {
    final value = dailyTarget == dailyTarget.roundToDouble()
        ? dailyTarget.toStringAsFixed(0)
        : dailyTarget.toString();
    return '$value $unit';
  }
}

const nutrientCatalog = <NutrientReference>[
  NutrientReference(
    code: 'A',
    name: 'Vitamin A',
    group: 'vitamin',
    dailyTarget: 900,
    unit: 'mcg RAE',
    summary: 'Fat-soluble vitamin for vision, skin, immunity, and cell growth.',
    benefits: ['Vision support', 'Immune defense', 'Skin and cell growth'],
    lowNote:
        'Low intake can affect night vision, skin health, and immune resilience.',
  ),
  NutrientReference(
    code: 'B1',
    name: 'Vitamin B1',
    group: 'vitamin',
    dailyTarget: 1.2,
    unit: 'mg',
    summary:
        'Water-soluble B vitamin that helps turn carbohydrates into energy.',
    benefits: [
      'Energy metabolism',
      'Nerve signaling',
      'Heart and muscle function',
    ],
    lowNote:
        'Low intake may contribute to fatigue, nerve symptoms, and poor appetite.',
  ),
  NutrientReference(
    code: 'B2',
    name: 'Vitamin B2',
    group: 'vitamin',
    dailyTarget: 1.3,
    unit: 'mg',
    summary:
        'Water-soluble B vitamin involved in energy release and antioxidant systems.',
    benefits: ['Energy production', 'Skin and eye health', 'Cell protection'],
    lowNote:
        'Low intake may show up as mouth cracks, sore throat, or skin irritation.',
  ),
  NutrientReference(
    code: 'B3',
    name: 'Vitamin B3',
    group: 'vitamin',
    dailyTarget: 16,
    unit: 'mg NE',
    summary:
        'B vitamin used to make NAD and NADP, key molecules in metabolism.',
    benefits: [
      'Energy metabolism',
      'Nervous system support',
      'Digestive health',
    ],
    lowNote: 'Very low intake can affect skin, digestion, mood, and cognition.',
  ),
  NutrientReference(
    code: 'B5',
    name: 'Vitamin B5',
    group: 'vitamin',
    dailyTarget: 5,
    unit: 'mg',
    summary:
        'B vitamin needed to make coenzyme A for energy and fat metabolism.',
    benefits: ['Energy release', 'Fat metabolism', 'Hormone synthesis'],
    lowNote:
        'Deficiency is uncommon but may cause fatigue and nerve discomfort.',
  ),
  NutrientReference(
    code: 'B6',
    name: 'Vitamin B6',
    group: 'vitamin',
    dailyTarget: 1.7,
    unit: 'mg',
    summary:
        'B vitamin used in protein metabolism and neurotransmitter production.',
    benefits: ['Brain chemistry', 'Protein metabolism', 'Immune support'],
    lowNote:
        'Low intake may affect mood, immunity, skin, and red blood cell formation.',
  ),
  NutrientReference(
    code: 'B7',
    name: 'Vitamin B7',
    group: 'vitamin',
    dailyTarget: 30,
    unit: 'mcg',
    summary:
        'Biotin supports enzymes that process fats, carbohydrates, and proteins.',
    benefits: ['Macro metabolism', 'Hair and skin support', 'Enzyme function'],
    lowNote:
        'Low intake is rare but can affect skin, hair, and nervous system comfort.',
  ),
  NutrientReference(
    code: 'B9',
    name: 'Folate',
    group: 'vitamin',
    dailyTarget: 400,
    unit: 'mcg DFE',
    summary: 'B vitamin required for DNA synthesis and healthy cell division.',
    benefits: ['DNA synthesis', 'Red blood cells', 'Pregnancy support'],
    lowNote:
        'Low folate can contribute to anemia and is important before pregnancy.',
  ),
  NutrientReference(
    code: 'B12',
    name: 'Vitamin B12',
    group: 'vitamin',
    dailyTarget: 2.4,
    unit: 'mcg',
    summary: 'B vitamin needed for nerves, DNA synthesis, and red blood cells.',
    benefits: ['Nerve health', 'Red blood cells', 'DNA synthesis'],
    lowNote:
        'Low intake can cause anemia, numbness, fatigue, and neurologic symptoms.',
  ),
  NutrientReference(
    code: 'C',
    name: 'Vitamin C',
    group: 'vitamin',
    dailyTarget: 90,
    unit: 'mg',
    summary:
        'Water-soluble antioxidant needed for collagen and iron absorption.',
    benefits: ['Collagen formation', 'Antioxidant support', 'Iron absorption'],
    lowNote: 'Low intake can affect gums, wound healing, and overall fatigue.',
  ),
  NutrientReference(
    code: 'D',
    name: 'Vitamin D',
    group: 'vitamin',
    dailyTarget: 20,
    unit: 'mcg',
    summary:
        'Fat-soluble vitamin that helps absorb calcium and maintain bones.',
    benefits: ['Calcium absorption', 'Bone health', 'Immune support'],
    lowNote: 'Low levels can affect bone strength and muscle comfort.',
  ),
  NutrientReference(
    code: 'E',
    name: 'Vitamin E',
    group: 'vitamin',
    dailyTarget: 15,
    unit: 'mg',
    summary: 'Fat-soluble antioxidant that protects cell membranes.',
    benefits: ['Cell protection', 'Immune support', 'Skin barrier support'],
    lowNote:
        'Deficiency is uncommon but can affect nerves, muscles, and immunity.',
  ),
  NutrientReference(
    code: 'K',
    name: 'Vitamin K',
    group: 'vitamin',
    dailyTarget: 120,
    unit: 'mcg',
    summary:
        'Fat-soluble vitamin needed for normal blood clotting and bone proteins.',
    benefits: ['Blood clotting', 'Bone metabolism', 'Protein activation'],
    lowNote:
        'Low intake may affect clotting and bone-related protein activity.',
  ),
  NutrientReference(
    code: 'Fe',
    name: 'Iron',
    group: 'mineral',
    dailyTarget: 18,
    unit: 'mg',
    summary:
        'Mineral required for hemoglobin, oxygen transport, and energy metabolism.',
    benefits: ['Oxygen transport', 'Energy support', 'Red blood cells'],
    lowNote:
        'Low iron can cause fatigue, weakness, shortness of breath, and anemia.',
  ),
  NutrientReference(
    code: 'Ca',
    name: 'Calcium',
    group: 'mineral',
    dailyTarget: 1300,
    unit: 'mg',
    summary:
        'Major mineral for bones, teeth, muscles, nerves, and blood vessels.',
    benefits: ['Bone strength', 'Muscle contraction', 'Nerve signaling'],
    lowNote:
        'Long-term low intake can affect bone density and muscle function.',
  ),
  NutrientReference(
    code: 'Zn',
    name: 'Zinc',
    group: 'mineral',
    dailyTarget: 11,
    unit: 'mg',
    summary:
        'Trace mineral for immunity, wound healing, taste, and protein synthesis.',
    benefits: ['Immune support', 'Wound healing', 'Taste and smell'],
    lowNote:
        'Low intake can affect immunity, wound healing, appetite, and taste.',
  ),
  NutrientReference(
    code: 'Mg',
    name: 'Magnesium',
    group: 'mineral',
    dailyTarget: 420,
    unit: 'mg',
    summary:
        'Mineral used by hundreds of enzymes in muscle, nerve, and energy systems.',
    benefits: ['Muscle function', 'Nerve signaling', 'Energy production'],
    lowNote:
        'Low intake may contribute to cramps, weakness, or irregular heartbeat risk.',
  ),
  NutrientReference(
    code: 'Kp',
    name: 'Potassium',
    group: 'mineral',
    dailyTarget: 4700,
    unit: 'mg',
    summary:
        'Electrolyte that supports fluid balance, nerves, muscles, and blood pressure.',
    benefits: ['Fluid balance', 'Muscle contraction', 'Blood pressure support'],
    lowNote: 'Low potassium can affect muscles, energy, and heart rhythm.',
  ),
  NutrientReference(
    code: 'Na',
    name: 'Sodium',
    group: 'mineral',
    dailyTarget: 2300,
    unit: 'mg limit',
    summary:
        'Electrolyte needed for fluid balance and nerves, but often over-consumed.',
    benefits: ['Fluid balance', 'Nerve signaling', 'Muscle function'],
    lowNote:
        'Low sodium is usually medical or medication related; high intake is more common.',
  ),
  NutrientReference(
    code: 'P',
    name: 'Phosphorus',
    group: 'mineral',
    dailyTarget: 1250,
    unit: 'mg',
    summary: 'Mineral that works with calcium in bones and helps store energy.',
    benefits: ['Bone structure', 'Energy storage', 'Cell membranes'],
    lowNote:
        'Low intake is uncommon but can affect bones, appetite, and muscle strength.',
  ),
  NutrientReference(
    code: 'Se',
    name: 'Selenium',
    group: 'mineral',
    dailyTarget: 55,
    unit: 'mcg',
    summary:
        'Trace mineral used in antioxidant enzymes and thyroid hormone metabolism.',
    benefits: ['Antioxidant enzymes', 'Thyroid support', 'Immune function'],
    lowNote:
        'Low intake can affect thyroid and immune function in vulnerable groups.',
  ),
  NutrientReference(
    code: 'Mn',
    name: 'Manganese',
    group: 'mineral',
    dailyTarget: 2.3,
    unit: 'mg',
    summary:
        'Trace mineral involved in bone formation, metabolism, and antioxidant defense.',
    benefits: ['Bone formation', 'Metabolism', 'Antioxidant enzymes'],
    lowNote: 'Deficiency is rare but may affect growth, bones, or metabolism.',
  ),
  NutrientReference(
    code: 'S',
    name: 'Sulfur',
    group: 'mineral',
    dailyTarget: 0,
    unit: '% DV',
    summary:
        'A component of sulfur-containing amino acids and many body compounds.',
    benefits: [
      'Protein structure',
      'Connective tissue support',
      'Cell chemistry',
    ],
    lowNote:
        'There is no established adult Daily Value for sulfur in food labels.',
  ),
  NutrientReference(
    code: 'Protein',
    name: 'Protein',
    group: 'macro',
    dailyTarget: 50,
    unit: 'g',
    summary:
        'Macronutrient needed to build and repair tissues and make enzymes.',
    benefits: ['Muscle repair', 'Satiety', 'Enzyme and hormone production'],
    lowNote: 'Low intake can affect muscle, recovery, immunity, and fullness.',
  ),
  NutrientReference(
    code: 'Fiber',
    name: 'Fiber',
    group: 'macro',
    dailyTarget: 28,
    unit: 'g',
    summary:
        'Non-digestible carbohydrate that supports digestion and heart health.',
    benefits: [
      'Digestive regularity',
      'Cholesterol support',
      'Blood sugar steadiness',
    ],
    lowNote: 'Low intake can affect regularity and make meals less filling.',
  ),
  NutrientReference(
    code: 'Carbs',
    name: 'Carbohydrates',
    group: 'macro',
    dailyTarget: 275,
    unit: 'g',
    summary: 'Main fuel source for the brain, muscles, and daily activity.',
    benefits: ['Energy supply', 'Exercise fuel', 'Brain glucose'],
    lowNote:
        'Very low intake can affect training fuel, mood, and dietary variety.',
  ),
  NutrientReference(
    code: 'Fat',
    name: 'Fat',
    group: 'macro',
    dailyTarget: 78,
    unit: 'g',
    summary:
        'Macronutrient needed for cell membranes, hormones, and fat-soluble vitamins.',
    benefits: ['Vitamin absorption', 'Hormone support', 'Long-lasting energy'],
    lowNote:
        'Very low intake can affect vitamin absorption and dietary satisfaction.',
  ),
];

final nutrientReferencesByCode = {
  for (final nutrient in nutrientCatalog) nutrient.code: nutrient,
};
