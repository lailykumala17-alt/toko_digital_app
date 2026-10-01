import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class DBHelper {
  static Database? _database;

  // Daftar 6 Produk Laily's Digital Caffe
  static final List<Product> _webProducts = [
    Product(
      id: 1,
      name: 'Sago Mango',
      price: 18000.0,
      imageUrl: 'https://www.eatwithcarmen.com/wp-content/uploads/2024/05/Mango-sago-filipino-recipe.jpg',
    ),
    Product(
      id: 2,
      name: 'Cheese Cake',
      price: 25000.0,
      imageUrl: 'https://sugargeekshow.com/wp-content/uploads/2025/01/strawberry_cheesecake_featured.jpg',
    ),
    Product(
      id: 3,
      name: 'Strawberry Matcha',
      price: 22000.0,
      imageUrl: 'https://moribyan.com/wp-content/uploads/2022/07/strawberry-matcha-latte-1-scaled.jpg',
    ),
    Product(
      id: 4,
      name: 'Fudgy Brownies',
      price: 20000.0,
      imageUrl: 'https://houseofnasheats.com/wp-content/uploads/2025/02/Chocolate-Covered-Strawberry-Brownies-14.jpg',
    ),
    Product(
      id: 5,
      name: 'Cherry Sparkling',
      price: 15000.0,
      imageUrl: 'https://www.redwinedragons.com/wp-content/uploads/2020/06/cherry-white-wine-spritzer-cocktail_1.webp',
    ),
    Product(
      id: 6,
      name: 'Beef Burger',
      price: 25000.0,
      imageUrl: 'https://www.dapurkobe.co.id/wp-content/uploads/beef-burger-special.jpg',
    ),
  ];
  static final List<CartItem> _webCart = [];

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'toko_digital.db');
    return await openDatabase(
      path,
      version: 4, // Versi dinaikkan ke 4 untuk pembaruan 6 produk
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE master_products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            price REAL,
            image_url TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE local_cart (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER,
            name TEXT,
            price REAL,
            image_url TEXT,
            quantity INTEGER
          )
        ''');

        for (var p in _webProducts) {
          await db.insert('master_products', p.toMap());
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('DROP TABLE IF EXISTS master_products');
          await db.execute('''
            CREATE TABLE master_products (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              price REAL,
              image_url TEXT
            )
          ''');
          for (var p in _webProducts) {
            await db.insert('master_products', p.toMap());
          }
        }
      },
    );
  }

  static Future<List<Product>> getProducts() async {
    if (kIsWeb) return _webProducts;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('master_products');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  static Future<List<CartItem>> getCartItems() async {
    if (kIsWeb) return _webCart;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('local_cart');
    return maps.map((map) => CartItem.fromMap(map)).toList();
  }

  static Future<int> addToCart(CartItem item) async {
    if (kIsWeb) {
      int index = _webCart.indexWhere((element) => element.productId == item.productId);
      if (index != -1) {
        _webCart[index].quantity += item.quantity;
      } else {
        _webCart.add(CartItem(
          id: _webCart.length + 1,
          productId: item.productId,
          name: item.name,
          price: item.price,
          imageUrl: item.imageUrl,
          quantity: item.quantity,
        ));
      }
      return 1;
    }
    final db = await database;
    final List<Map<String, dynamic>> existing = await db.query(
      'local_cart',
      where: 'product_id = ?',
      whereArgs: [item.productId],
    );

    if (existing.isNotEmpty) {
      int currentQty = existing.first['quantity'];
      int newQty = currentQty + item.quantity;
      return await db.update(
        'local_cart',
        {'quantity': newQty},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      return await db.insert('local_cart', item.toMap());
    }
  }

  static Future<int> updateCartQuantity(int id, int quantity) async {
    if (kIsWeb) {
      if (quantity <= 0) {
        _webCart.removeWhere((item) => item.id == id);
      } else {
        int index = _webCart.indexWhere((item) => item.id == id);
        if (index != -1) _webCart[index].quantity = quantity;
      }
      return 1;
    }
    final db = await database;
    if (quantity <= 0) {
      return await db.delete('local_cart', where: 'id = ?', whereArgs: [id]);
    }
    return await db.update(
      'local_cart',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteCartItem(int id) async {
    if (kIsWeb) {
      _webCart.removeWhere((item) => item.id == id);
      return 1;
    }
    final db = await database;
    return await db.delete('local_cart', where: 'id = ?', whereArgs: [id]);
  }
}