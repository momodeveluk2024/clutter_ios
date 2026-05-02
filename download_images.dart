import 'dart:io';

Future<void> main() async {
  final foods = [
    'Orange sample', 'Sweet potato, baked', 'Tempeh',
    'Black beans, cooked', 'Spinach', 'Swiss Chard', 'Collard Greens',
    'Turnip Greens', 'Brussels Sprouts', 'Watercress',
  ];

  for (final food in foods) {
    final slug = food.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    final file = File('assets/foods/$slug.jpg');
    
    if (await file.exists()) {
      print('Skipping $food, already exists.');
      continue;
    }

    print('Downloading $food...');
    final prompt = Uri.encodeComponent('$food, beautiful high quality food photography, clean bright background');
    final url = 'https://image.pollinations.ai/prompt/$prompt?width=400&height=400&nologo=true';

    try {
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      await response.pipe(file.openWrite());
      print('Saved $slug.jpg');
    } catch (e) {
      print('Failed to download $food: $e');
    }

    // Wait to avoid rate limiting
    await Future.delayed(Duration(seconds: 2));
  }
}
