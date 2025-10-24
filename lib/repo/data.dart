import 'dart:math';

class Data {
  List<Map<String, dynamic>> generate() {
    final random = Random();
    final List<Map<String, dynamic>> dummyItems = [];

    // Sample lists for generating random words
    const itemNames = [
      'Laptop',
      'Phone',
      'Tablet',
      'Camera',
      'Headphones',
      'Monitor',
      'Keyboard',
      'Mouse',
      'Printer',
      'Speaker',
    ];
    const categories = ['Electronics', 'Gadget', 'Office', 'Home', 'Outdoor'];
    const brands = ['Samsung', 'Apple', 'Xiaomi', 'Sony', 'HP', 'Dell', 'Asus'];
    const conditions = ['New', 'Used', 'Refurbished'];
    const colors = ['Black', 'White', 'Silver', 'Gray', 'Blue', 'Red'];

    dummyItems.addAll(generateValidData());
    for (int i = 1; i <= 30000; i++) {
      final itemName = '${itemNames[random.nextInt(itemNames.length)]} $i';
      final sku = 'SKU-${100000 + i}';
      final category = categories[random.nextInt(categories.length)];
      final brand = brands[random.nextInt(brands.length)];
      final condition = conditions[random.nextInt(conditions.length)];
      final color = colors[random.nextInt(colors.length)];
      final price = double.parse((random.nextDouble() * 2000 + 100).toStringAsFixed(2));
      final stock = random.nextInt(500);
      final rating = double.parse((random.nextDouble() * 5).toStringAsFixed(1));
      final discount = random.nextInt(50);
      final sold = random.nextInt(10000);
      final weight = double.parse((0.5 + random.nextDouble() * 5).toStringAsFixed(2));
      final width = random.nextInt(50);
      final height = random.nextInt(50);
      final depth = random.nextInt(50);
      final barcode = 'BC${100000 + i}';
      final dateAdded = DateTime(2020 + random.nextInt(5), 1 + random.nextInt(12), 1 + random.nextInt(28));
      final lastUpdated = dateAdded.add(Duration(days: random.nextInt(365)));
      final isAvailable = stock > 0;
      final supplier = 'Supplier ${random.nextInt(200) + 1}';

      dummyItems.add({
        'id': i,
        'name': itemName,
        'sku': sku,
        'category': category,
        'brand': brand,
        'condition': condition,
        'color': color,
        'price': price,
        'stock': stock,
        'rating': rating,
        'discount': discount,
        'sold': sold,
        'weight': weight,
        'width': width,
        'height': height,
        'depth': depth,
        'barcode': barcode,
        'dateAdded': dateAdded.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'isAvailable': isAvailable,
        'supplier': supplier,
      });
    }

    return dummyItems;
  }

  List<Map<String, dynamic>> generateValidData() {
    return [
      {
        'id': 40000,
        'name': 'Coca Cola',
        'sku': 'SKU-100000',
        'category': 'Sample',
        'brand': 'TestBrand',
        'condition': 'New',
        'color': 'Black',
        'price': 10000.00,
        'stock': 10,
        'rating': 5.0,
        'discount': 0,
        'sold': 0,
        'weight': 1.5,
        'width': 30,
        'height': 20,
        'depth': 10,
        'barcode': 'BC00',
        'dateAdded': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'isAvailable': true,
        'supplier': 'Supplier 0',
      },
      {
        'id': 40001,
        'name': 'Fanta',
        'sku': 'SKU-100001',
        'category': 'Sample',
        'brand': 'TestBrand',
        'condition': 'New',
        'color': 'Black',
        'price': 15000.00,
        'stock': 10,
        'rating': 5.0,
        'discount': 0,
        'sold': 0,
        'weight': 1.5,
        'width': 30,
        'height': 20,
        'depth': 10,
        'barcode': 'BC01',
        'dateAdded': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'isAvailable': true,
        'supplier': 'Supplier 0',
      },
      {
        'id': 40002,
        'name': 'Sprite',
        'sku': 'SKU-100002',
        'category': 'Sample',
        'brand': 'TestBrand',
        'condition': 'New',
        'color': 'Black',
        'price': 10000.00,
        'stock': 10,
        'rating': 5.0,
        'discount': 0,
        'sold': 0,
        'weight': 1.5,
        'width': 30,
        'height': 20,
        'depth': 10,
        'barcode': 'BC02',
        'dateAdded': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'isAvailable': true,
        'supplier': 'Supplier 0',
      },
      {
        'id': 40003,
        'name': 'Water',
        'sku': 'SKU-100003',
        'category': 'Sample',
        'brand': 'TestBrand',
        'condition': 'New',
        'color': 'Black',
        'price': 15000.00,
        'stock': 10,
        'rating': 5.0,
        'discount': 0,
        'sold': 0,
        'weight': 1.5,
        'width': 30,
        'height': 30,
        'depth': 10,
        'barcode': 'BC03',
        'dateAdded': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'isAvailable': true,
        'supplier': 'Supplier 0',
      },
      {
        'id': 40004,
        'name': 'Pocari',
        'sku': 'SKU-100004',
        'category': 'Sample',
        'brand': 'TestBrand',
        'condition': 'New',
        'color': 'Black',
        'price': 20000.00,
        'stock': 10,
        'rating': 5.0,
        'discount': 0,
        'sold': 0,
        'weight': 1.5,
        'width': 40,
        'height': 40,
        'depth': 10,
        'barcode': 'BC04',
        'dateAdded': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'isAvailable': true,
        'supplier': 'Supplier 0',
      },
      {
        'id': 40005,
        'name': 'Bomb',
        'sku': 'SKU-100005',
        'category': 'Sample',
        'brand': 'TestBrand',
        'condition': 'New',
        'color': 'Black',
        'price': 15000.00,
        'stock': 10,
        'rating': 5.0,
        'discount': 0,
        'sold': 0,
        'weight': 1.5,
        'width': 50,
        'height': 50,
        'depth': 10,
        'barcode': 'BC05',
        'dateAdded': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'isAvailable': true,
        'supplier': 'Supplier 0',
      },
    ];
  }
}
