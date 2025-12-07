class RemedyService {

  static final Map<String, List<String>> traditionalRemedies = {
    'Sun': ['Aditya Hridayam Stotram', 'Donate Wheat', 'Wear Ruby (Manik)'],
    'Moon': ['Shiva Abhishek', 'Wear Pearl (Moti)', 'Offer water to Shivling'],
    'Mars': ['Hanuman Chalisa', 'Wear Red Coral (Moonga)', 'Donate Masoor Dal'],
    'Mercury': ['Tulsi Puja', 'Wear Emerald (Panna)', 'Chant Budh Mantra'],
    'Jupiter': ['Chant Brihaspati Mantra', 'Wear Yellow Sapphire (Pukhraj)', 'Donate Chana Dal'],
    'Venus': ['Durga Puja', 'Wear Diamond or Opal', 'Respect women'],
    'Saturn': ['Light Oil Lamp under Peepal tree', 'Wear Blue Sapphire (Neelam)', 'Chant Shani Mantra'],
    'Rahu': ['Float Coconut in flowing water', 'Wear Hessonite (Gomed)', 'Feed birds'],
    'Ketu': ['Chant Om Ketave Namaha', 'Wear Cat\'s Eye (Lehsunia)', 'Feed street dogs'],
  };

  static List<String> getTraditionalRemedies(Map<String, dynamic> chart) {
    List<String> remedies = [];
    // Basic logic: Suggest remedies for weak planets or current Dasha lord.
    // For MVP, suggest for current day ruler or random beneficial.
    // Let's return generic list based on chart planets for now.

    // Example: If Sun is weak (placeholder logic), add Sun remedies.
    remedies.addAll(traditionalRemedies['Sun']!);
    remedies.addAll(traditionalRemedies['Mars']!);

    return remedies;
  }
}
