import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:scanner/data.dart';
import 'package:scanner/models/discount.dart';
import 'package:scanner/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HardwareScannerPage extends StatefulWidget {
  const HardwareScannerPage({super.key});

  @override
  State<HardwareScannerPage> createState() => _HardwareScannerPageState();
}

class _HardwareScannerPageState extends State<HardwareScannerPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  final List<Map<String, dynamic>> _dummyData = [];
  final List<Map<String, dynamic>> _cartData = [];
  final List<Map<String, dynamic>> _shownData = [];

  bool _visible = false;
  bool _isLoadingMore = false;
  bool _isSearching = false;

  static const int _batchSize = 30;
  int _currentIndex = 0;

  String _sortField = 'none';
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _dummyData.addAll(Data().generate());
    _loadNextBatch();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 100), _focusNode.requestFocus);
      }
    });
  }

  void _onSubmitted(String value) {
    final scannedData = _dummyData.firstWhere((e) => e["barcode"] == value, orElse: () => {});
    if (scannedData.isEmpty) return;

    final existingIndex = _cartData.indexWhere((item) => item['id'] == scannedData['id']);
    if (existingIndex != -1) {
      _cartData[existingIndex]['qty'] += 1;
    } else {
      _cartData.add({
        'name': scannedData["name"],
        'id': scannedData["id"],
        'price': scannedData["price"],
        'qty': 1,
        'discountApplied': 0.0,
      });
    }

    // Recalculate discounts after every scan
    final newCart = recalculateDiscounts(_cartData, DiscountRule.discountRules);

    _cartData
      ..clear()
      ..addAll(newCart);

    _controller.clear();
    setState(() {});
  }

  Future<void> _loadNextBatch() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final nextIndex = _currentIndex + _batchSize;
    final remaining = _dummyData.length - _currentIndex;
    if (remaining <= 0) {
      setState(() => _isLoadingMore = false);
      return;
    }

    final endIndex = nextIndex > _dummyData.length ? _dummyData.length : nextIndex;
    setState(() {
      _shownData.addAll(_dummyData.sublist(_currentIndex, endIndex));
      _currentIndex = endIndex;
      _isLoadingMore = false;
    });
  }

  void _filterData(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(seconds: 1), () {
      setState(() {
        if (query.isEmpty) {
          _isSearching = false;
          _shownData
            ..clear()
            ..addAll(_dummyData.take(_currentIndex));
        } else {
          _isSearching = true;
          _shownData
            ..clear()
            ..addAll(
              _dummyData.where(
                (e) =>
                    e["name"].toString().toLowerCase().contains(query.toLowerCase()) ||
                    e["barcode"].toString().toLowerCase().contains(query.toLowerCase()) ||
                    e["id"].toString().toLowerCase().contains(query.toLowerCase()) ||
                    e["price"].toString().toLowerCase().contains(query.toLowerCase()),
              ),
            );
        }
      });
    });
  }

  void _applySortingToDummy() {
    if (_sortField == 'none') return;

    _dummyData.sort((a, b) {
      final valA = a[_sortField];
      final valB = b[_sortField];

      if (valA is num && valB is num) {
        return _isAscending ? valA.compareTo(valB) : valB.compareTo(valA);
      } else if (valA is String && valB is String) {
        return _isAscending
            ? valA.toLowerCase().compareTo(valB.toLowerCase())
            : valB.toLowerCase().compareTo(valA.toLowerCase());
      }
      return 0;
    });
  }

  void _onSortChanged(String field) {
    setState(() {
      if (_sortField == field) {
        _isAscending = !_isAscending;
      } else {
        _sortField = field;
        _isAscending = true;
      }

      _applySortingToDummy();
      _shownData
        ..clear()
        ..addAll(_dummyData.take(_currentIndex));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !_isSearching
            ? const Text('Hardware Scanner')
            : TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Search item...', border: InputBorder.none),
                onChanged: _filterData,
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              if (_isSearching) {
                _controller.clear();
                _filterData('');
              } else {
                setState(() => _isSearching = true);
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _onSortChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'none', child: Text('Default')),
              const PopupMenuItem(value: 'name', child: Text('Name')),
              const PopupMenuItem(value: 'price', child: Text('Price')),
              const PopupMenuItem(value: 'sold', child: Text('Sold')),
              const PopupMenuItem(value: 'stock', child: Text('Stock')),
            ],
          ),
        ],
      ),
      body: VisibilityDetector(
        key: const Key('visible-detector-key'),
        onVisibilityChanged: (info) => _visible = info.visibleFraction > 0,
        child: BarcodeKeyboardListener(
          bufferDuration: const Duration(milliseconds: 200),
          onBarcodeScanned: (barcode) {
            if (!_visible) return;
            _onSubmitted(barcode);
          },
          useKeyDownEvent: Platform.isWindows,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 50 && !_isSearching) {
                _loadNextBatch();
              }
              return false;
            },
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _shownData.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _shownData.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      final item = _shownData[index];
                      return GestureDetector(
                        onTap: () {
                          _onSubmitted(item["barcode"]);
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 3,
                                color: Colors.black.withValues(alpha: 0.08),
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("No. $index"),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item["name"], overflow: TextOverflow.ellipsis),
                                  Text("${item["price"]}"),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Sold: ${item["sold"]}"),
                                  Text(item["stock"] != 0 ? "Available" : "Empty"),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Icon(Icons.qr_code), SizedBox(width: 10), Text("${item["barcode"]}")],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_cartData.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey.shade100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("CART", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _cartData.length,
                            itemBuilder: (context, index) {
                              final item = _cartData[index];
                              final total = (item['price'] * item['qty']) - item['discountApplied'];
                              return Text(
                                "${item['name']} - ${item['qty']} pcs "
                                " | Disc: ${item['discountApplied'].toStringAsFixed(2)} "
                                "| Total: ${total.toStringAsFixed(2)}",
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
