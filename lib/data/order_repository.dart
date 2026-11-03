import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../features/orders/domain/order.dart';

/// Local order store: one index JSON file + one folder per order
/// (photos / audio / video live inside the folder).
class OrderRepository {
  Directory? _root;
  File? _indexFile;

  Future<Directory> get root async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    _root = Directory(p.join(docs.path, 'orders'));
    if (!await _root!.exists()) await _root!.create(recursive: true);
    return _root!;
  }

  Future<File> get indexFile async {
    if (_indexFile != null) return _indexFile!;
    _indexFile = File(p.join((await root).path, 'orders.json'));
    if (!await _indexFile!.exists()) {
      await _indexFile!.writeAsString('[]');
    }
    return _indexFile!;
  }

  Future<String> orderDir(String id) async {
    final dir = Directory(p.join((await root).path, id));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<List<Order>> loadAll() async {
    try {
      final raw = await (await indexFile).readAsString();
      final list = (jsonDecode(raw) as List? ?? const [])
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<Order?> byId(String id) async {
    final all = await loadAll();
    for (final o in all) {
      if (o.id == id) return o;
    }
    return null;
  }

  Future<void> save(Order order) async {
    final all = await loadAll();
    final i = all.indexWhere((o) => o.id == order.id);
    if (i >= 0) {
      all[i] = order;
    } else {
      all.insert(0, order);
    }
    final json = jsonEncode(all.map((o) => o.toJson()).toList());
    await (await indexFile).writeAsString(json);
  }

  Future<void> delete(String id) async {
    final all = await loadAll()..removeWhere((o) => o.id == id);
    await (await indexFile)
        .writeAsString(jsonEncode(all.map((o) => o.toJson()).toList()));
    final dir = Directory(p.join((await root).path, id));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Copy a file into the order folder under [subDir]/[name]. Returns new path.
  Future<String> importAsset(String orderId, String sourcePath,
      {String subDir = '', required String name}) async {
    final dir = p.join(await orderDir(orderId), subDir);
    await Directory(dir).create(recursive: true);
    final dest = p.join(dir, name);
    await File(sourcePath).copy(dest);
    return dest;
  }
}
