import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'store_management.db');

    print('DatabaseService: Initializing database at $path');

    // Open the database. Create it if it doesn't exist
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        print('DatabaseService: Creating database tables');
        await _createTables(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        print('DatabaseService: Upgrading database from $oldVersion to $newVersion');
        // Add upgrade logic here when needed
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Create products table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT UNIQUE,
        category TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL
      )
    ''');

    // Create sales table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        totalAmount REAL NOT NULL,
        dateTime TEXT NOT NULL
      )
    ''');

    // Create sale_items table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (saleId) REFERENCES sales(id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');

    print('DatabaseService: Tables created successfully');
  }

  Future<int> addProduct(Product product) async {
    final db = await database;
    try {
      final id = await db.insert(
        'products',
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      print('DatabaseService: Product added successfully with id: $id');
      return id;
    } catch (e) {
      print('DatabaseService: Error adding product: $e');
      if (e is DatabaseException && e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('A product with this SKU already exists');
      }
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    try {
      await db.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      print('DatabaseService: Product ${product.id} updated successfully');
    } catch (e) {
      print('DatabaseService: Error updating product: $e');
      if (e is DatabaseException && e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('A product with this SKU already exists');
      }
      throw Exception('Failed to update product: $e');
    }
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('products');
      print('DatabaseService: Found ${maps.length} products');
      return List.generate(maps.length, (i) {
        return Product.fromMap(maps[i]);
      });
    } catch (e) {
      print('DatabaseService: Error getting products: $e');
      throw Exception('Failed to get products: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    try {
      await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DatabaseService: Product $id deleted successfully');
    } catch (e) {
      print('DatabaseService: Error deleting product: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<int> addSale(Sale sale) async {
    final db = await database;
    try {
      // Start a transaction
      return await db.transaction((txn) async {
        // Insert the sale first
        final saleId = await txn.insert(
          'sales',
          sale.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        // Insert each sale item
        for (var item in sale.saleItems) {
          await txn.insert(
            'sale_items',
            {
              'saleId': saleId,
              'productId': item.product.id,
              'productName': item.product.name,
              'quantity': item.quantity,
              'price': item.product.price,
            },
            conflictAlgorithm: ConflictAlgorithm.abort,
          );

          // Update product stock
          await txn.update(
            'products',
            {'stock': item.product.stock - item.quantity},
            where: 'id = ?',
            whereArgs: [item.product.id],
          );
        }

        print('DatabaseService: Sale added successfully with id: $saleId');
        return saleId;
      });
    } catch (e) {
      print('DatabaseService: Error adding sale: $e');
      throw Exception('Failed to add sale: $e');
    }
  }

  Future<List<Sale>> getAllSales() async {
    print('DatabaseService: Getting all sales');
    final db = await database;
    
    try {
      // Get all sales
      final List<Map<String, dynamic>> salesMaps = await db.query('sales');
      print('DatabaseService: Found ${salesMaps.length} sales');

      // Convert each sale map to a Sale object with its items
      final List<Sale> sales = [];
      for (final saleMap in salesMaps) {
        try {
          // Get items for this sale
          final List<Map<String, dynamic>> itemMaps = await db.query(
            'sale_items',
            where: 'saleId = ?',
            whereArgs: [saleMap['id']],
          );
          print('DatabaseService: Found ${itemMaps.length} items for sale ${saleMap['id']}');

          if (itemMaps.isEmpty) {
            print('DatabaseService: Skipping sale ${saleMap['id']} - no items found');
            continue; // Skip sales with no items
          }

          // Convert item maps to SaleItem objects
          final List<SaleItem> saleItems = itemMaps.map((itemMap) => 
            SaleItem.fromMap(itemMap)
          ).toList();

          // Create the Sale object with its items
          final sale = Sale(
            id: saleMap['id'] as int,
            saleItems: saleItems,
            totalAmount: saleMap['totalAmount'] as double,
            dateTime: DateTime.parse(saleMap['dateTime'] as String),
          );
          
          sales.add(sale);
          print('DatabaseService: Successfully loaded sale ${sale.id}');
        } catch (e) {
          print('DatabaseService: Error loading sale ${saleMap['id']}: $e');
          // Continue to next sale if there's an error with this one
          continue;
        }
      }

      print('DatabaseService: Successfully loaded ${sales.length} valid sales');
      return sales;
    } catch (e) {
      print('DatabaseService: Error loading sales: $e');
      throw Exception('Failed to load sales: $e');
    }
  }

  Future<Sale?> getSaleById(int id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> saleMaps = await db.query(
        'sales',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (saleMaps.isEmpty) {
        return null;
      }

      final List<Map<String, dynamic>> itemMaps = await db.query(
        'sale_items',
        where: 'saleId = ?',
        whereArgs: [id],
      );

      if (itemMaps.isEmpty) {
        return null;
      }

      final List<SaleItem> saleItems = itemMaps.map((itemMap) => 
        SaleItem.fromMap(itemMap)
      ).toList();

      return Sale(
        id: saleMaps.first['id'] as int,
        saleItems: saleItems,
        totalAmount: saleMaps.first['totalAmount'] as double,
        dateTime: DateTime.parse(saleMaps.first['dateTime'] as String),
      );
    } catch (e) {
      print('Error getting sale by ID: $e');
      return null;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'name LIKE ? OR sku LIKE ? OR category LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
      );
      
      print('DatabaseService: Found ${maps.length} products matching query: $query');
      return List.generate(maps.length, (i) {
        return Product.fromMap(maps[i]);
      });
    } catch (e) {
      print('DatabaseService: Error searching products: $e');
      throw Exception('Failed to search products: $e');
    }
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        print('DatabaseService: No product found with id: $id');
        return null;
      }

      print('DatabaseService: Found product with id: $id');
      return Product.fromMap(maps.first);
    } catch (e) {
      print('DatabaseService: Error getting product: $e');
      throw Exception('Failed to get product: $e');
    }
  }
}
