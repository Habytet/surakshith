class FssaiAuditPoint {
  final int serialNo;
  final String description;
  final int maxScore;

  const FssaiAuditPoint({
    required this.serialNo,
    required this.description,
    required this.maxScore,
  });
}

class FssaiAuditPoints {
  static const List<FssaiAuditPoint> allPoints = [
    FssaiAuditPoint(
      serialNo: 1,
      description: 'FSSAI license and Food Safety Display Board (FSDB) are displayed at a prominent location.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 2,
      description: 'The food premise is located in a hygienic environment with adequate working space, allowing maintenance and cleaning.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 3,
      description: 'Internal structures & fittings are made of non-toxic and impermeable material.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 4,
      description: 'Walls, ceilings & doors are free from flaking paint or plaster, condensation & shedding particles.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 5,
      description: 'Floors are non-absorbent, non-slippery & sloped appropriately.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 6,
      description: 'Windows are kept closed & fitted with insect-proof screens when opening to an external environment.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 7,
      description: 'Doors are smooth and non-absorbent. Suitable precautions have been taken to prevent the entry of pests.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 8,
      description: 'Potable water (meeting IS:10500 standards & tested semi-annually) is used as a product ingredient or in contact with food surfaces.',
      maxScore: 4,
    ),
    FssaiAuditPoint(
      serialNo: 9,
      description: 'Equipment and containers are made of non-toxic, impervious, non-corrosive material, which is easy to clean & disinfect.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 10,
      description: 'Adequate facilities for heating, cooling, refrigeration, and freezing food, with temperature monitoring.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 11,
      description: 'The premise has sufficient lighting. Lighting fixtures are protected to prevent contamination upon breakage.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 12,
      description: 'Adequate ventilation is provided within the premise.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 13,
      description: 'An adequate storage facility for food, packaging materials, chemicals, and personal items is available.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 14,
      description: 'Personnel hygiene facilities are available, including handwashing facilities, toilets, and changing rooms for employees.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 15,
      description: 'Food material is tested either through an internal laboratory or an accredited lab. Check for records.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 16,
      description: 'Incoming material is procured as per internally laid down specifications from approved vendors.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 17,
      description: 'Raw materials are inspected upon receiving for food safety hazards.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 18,
      description: 'Incoming material, semi-processed, or final products are stored as per temperature requirements. FIFO & FEFO are practiced.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 19,
      description: 'Foods of animal origin are stored at a temperature ≤4°C.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 20,
      description: 'All raw materials are cleaned thoroughly before food preparation.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 21,
      description: 'Proper segregation of raw, semi-processed, cooked, vegetarian, and non-vegetarian food is done.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 22,
      description: 'All equipment is adequately sanitized before and after food preparation.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 23,
      description: 'Frozen food is thawed hygienically. No thawed food is stored for later use.',
      maxScore: 4,
    ),
    FssaiAuditPoint(
      serialNo: 24,
      description: 'Vegetarian items are cooked to a minimum of 60°C for 10 minutes or 65°C for 2 minutes. Non-vegetarian items are cooked to 65°C for 10 minutes, 70°C for 2 minutes, or 75°C for 15 seconds.',
      maxScore: 4,
    ),
    FssaiAuditPoint(
      serialNo: 25,
      description: 'Cooked food intended for refrigeration is cooled appropriately.',
      maxScore: 4,
    ),
    FssaiAuditPoint(
      serialNo: 26,
      description: 'Food portioning is done in hygienic conditions. High-risk food is portioned in a refrigerated area or refrigerated within 30 minutes.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 27,
      description: 'Hot food intended for consumption is held at 65°C; non-vegetarian food at 70°C. Cold foods are maintained at 5°C or below; frozen products at -18°C.',
      maxScore: 4,
    ),
    FssaiAuditPoint(
      serialNo: 28,
      description: 'Reheating is done appropriately. No indirect reheating methods (hot water addition, bain-marie, lamps) are used.',
      maxScore: 4,
    ),
    FssaiAuditPoint(
      serialNo: 29,
      description: 'Oil being used is suitable for cooking purposes. Periodic verification of fat and oil is conducted.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 30,
      description: 'Unused/fresh vegetable oil has ≤15% Total Polar Compounds (TPC), and used oil has ≤25% TPC.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 31,
      description: 'Appropriate records are maintained if oil consumption exceeds 50 L/day.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 32,
      description: 'Vehicles intended for food transportation are clean, well-maintained, and maintain required temperatures.',
      maxScore: 4,
    ),
    FssaiAuditPoint(
      serialNo: 33,
      description: 'Food and non-food products transported together are adequately separated to avoid contamination.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 34,
      description: 'Cutlery, crockery used for serving and dinner accompaniments are clean, sanitized, and free from unhygienic matters.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 35,
      description: 'Packaging and wrapping materials in contact with food are clean and food-grade quality. Newspapers are not used.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 36,
      description: 'Food items are labeled as per FSSAI norms, and shelf life is properly indicated.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 37,
      description: 'Cleaning of equipment and food premises is done as per a cleaning schedule. There is no water stagnation in food zones.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 38,
      description: 'Preventive maintenance of equipment and machinery is conducted regularly as per the manufacturer\'s instructions.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 39,
      description: 'Measuring and monitoring devices are calibrated periodically.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 40,
      description: 'Pest control measures are implemented to prevent infestation.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 41,
      description: 'No signs of pest activity or infestation in premises (eggs, larvae, feces etc.).',
      maxScore: 4,
    ),
    FssaiAuditPoint(
      serialNo: 42,
      description: 'Drains are designed to meet expected flow loads and equipped with grease and cockroach traps to capture contaminants and pests.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 43,
      description: 'Food waste and other refuse are removed periodically from food handling areas to avoid accumulation.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 44,
      description: 'Annual medical examination & inoculation of food handlers against the enteric group of diseases as per recommended schedule of the vaccine is done. Check for records.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 45,
      description: 'No person suffering from a disease or illness or with open wounds or burns is involved in handling of food or materials which come in contact with food.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 46,
      description: 'Food handlers maintain personal cleanliness (clean clothes, trimmed nails & water proof bandage etc.) and personal behavior (hand washing, no loose jewellery, no smoking, nospitting etc.).',
      maxScore: 4,
    ),
    FssaiAuditPoint(
      serialNo: 47,
      description: 'Food handlers are equipped with suitable aprons, gloves, headgear, etc.; wherever necessary.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 48,
      description: 'Internal / External audit of the system is done periodically. Check for records.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 49,
      description: 'Food Business has an effective consumer complaints redressal mechanism.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 50,
      description: 'Food handlers have the necessary knowledge and skills & trained to handle food safely. Check for training records.',
      maxScore: 2,
    ),
    FssaiAuditPoint(
      serialNo: 51,
      description: 'Appropriate documentation & records are available and retained for a period of one year, whichever is more.',
      maxScore: 2,
    ),
  ];

  static int get totalMaxScore {
    return allPoints.fold(0, (sum, point) => sum + point.maxScore);
  }

  static FssaiAuditPoint? getPointBySerialNo(int serialNo) {
    try {
      return allPoints.firstWhere((point) => point.serialNo == serialNo);
    } catch (e) {
      return null;
    }
  }
}
