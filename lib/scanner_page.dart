import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:scanner/data.dart';
import 'package:scanner/discount_dialog.dart';
import 'package:scanner/models/cart.dart';
import 'package:scanner/models/discount.dart';
import 'package:scanner/models/discount_cart.dart';
import 'package:scanner/utils.dart';
import 'package:scanner/utils/torupiah.dart';
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
  final List<CartItem> _cartData = [];
  final List<CartItem> _cartDataView = [];
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

    final existingIndex = _cartData.indexWhere((item) => item.id == scannedData['id']);
    if (existingIndex != -1) {
      _cartData[existingIndex].qty += 1;
    } else {
      _cartData.add(CartItem(id: scannedData["id"], name: scannedData["name"], price: scannedData["price"]));
    }

    // Recalculate discounts after every scan
    final newCart = recalculateDiscounts(_cartData, DiscountRule.discountRules(), DiscountItemLink.getDummy());

    _cartDataView
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
                              Text("No. ${item["id"]}"),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item["name"], overflow: TextOverflow.ellipsis),
                                  Text(((item["price"] ?? 0) as num).toRupiah()),
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
                _cart(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cart() {
    if (_cartDataView.isEmpty) return const SizedBox.shrink();

    // // Split items by name + discount combination
    // final List<CartItem> separatedItems = [];

    // for (var item in _cartDataView) {
    //   // If same item name and same discountApplied exists, combine qty
    //   final existingIndex = separatedItems.indexWhere(
    //     (e) => e.name == item.name && (e.discountApplied) == (item.discountApplied),
    //   );

    //   if (existingIndex != -1) {
    //     separatedItems[existingIndex].qty += item.qty;
    //   } else {
    //     separatedItems.add(item);
    //   }
    // }

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(0, 2), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🛒 CART", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.separated(
              itemCount: _cartDataView.length,
              separatorBuilder: (context, index) => Divider(height: 32, color: Colors.grey),
              itemBuilder: (context, index) {
                return _cartCard(_cartDataView[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartCard(CartItem item) {
    final price = item.price.toDouble();
    final discount = item.discountApplied.toDouble();
    final hasDiscount = discount > 0 || (item.manualDiscount ?? 0) > 0;

    final discountQty = item.qtyDiscounted;
    final normalQty = item.qty - discountQty;

    // Calculate totals
    final totalDiscounted = (price * discountQty) - discount;
    final totalNormal = price * normalQty;
    final totalDiscountBeforeDisc = item.price * discountQty;

    final List<Widget> rows = [];

    if (normalQty > 0) {
      rows.add(
        _buildCartRow(
          name: item.name,
          qty: normalQty,
          price: price,
          total: totalNormal,
          normal: totalNormal,
          isDiscounted: false,
        ),
      );
    }

    if (hasDiscount && discountQty > 0) {
      rows.add(
        _buildCartRow(
          name: "${item.name} (Disc)",
          qty: discountQty,
          price: price,
          total: totalDiscounted,
          normal: totalDiscountBeforeDisc,
          isDiscounted: true,
          discountAmount: discount,
          discName: item.discName,
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        final manualRule = await showManualDiscountDialog(context);
        if (manualRule == null) return;

        final previousManualDiscount = item.manualDiscount ?? 0.0;
        final previousAutoDiscount = item.discountApplied - previousManualDiscount;

        // Remove only the old manual discount (keep auto)
        if (item.mountedDiscountId != null && previousManualDiscount > 0) {
          item.discountApplied -= previousManualDiscount;
          if (item.discountApplied < 0) item.discountApplied = 0;
        }
        if (item.isRestricted) {
          item.discountApplied = 0;
        }

        // Update with manual rule
        item.isRestricted = manualRule.restricted;
        item.mountedDiscountId = manualRule.id;

        final double itemSubtotal = item.price * item.qty;
        final double remainingTotal = itemSubtotal - previousAutoDiscount;

        double newManualDiscount = 0;

        // Calculate new discount
        if (manualRule.type == DiscountType.percent && manualRule.discountPercent != null) {
          newManualDiscount = remainingTotal * (manualRule.discountPercent! / 100);
        } else if (manualRule.type == DiscountType.amount && manualRule.discountAmount != null) {
          // for fixed amount, limit it to remaining total (never over-discount)
          newManualDiscount = manualRule.discountAmount!;
          if (newManualDiscount > remainingTotal) newManualDiscount = remainingTotal;
        }

        // Apply new discount
        if (item.isRestricted) {
          // Restricted → replace everything
          item.discountApplied = newManualDiscount;
          item.qtyDiscounted = item.qty;
        } else {
          // Non-restricted → add manual discount to remaining total
          item.discountApplied = previousAutoDiscount + newManualDiscount;
          item.qtyDiscounted = item.qty;
        }

        // Store manual discount
        item.manualDiscount = newManualDiscount;

        setState(() {});
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...rows,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("Total qty: ${item.qty}"), Text((item.qty * item.price).toRupiah())],
          ),
        ],
      ),
    );
  }

  Widget _buildCartRow({
    required String name,
    required int qty,
    required double price,
    required double total,
    required double normal,
    required bool isDiscounted,
    double? discountAmount,
    String? discName,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDiscounted ? Colors.green.shade800 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text("$qty × ${price.toRupiah()}", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                if (isDiscounted && (discountAmount ?? 0) > 0) ...[
                  Text(
                    "Disc: ${discountAmount!.toRupiah()}",
                    style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "$discName",
                    style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),

          // Total
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                normal.toRupiah(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDiscounted ? Colors.grey : Colors.black,
                  decoration: isDiscounted ? TextDecoration.lineThrough : TextDecoration.none,
                  decorationThickness: 2,
                ),
              ),
              if (isDiscounted) ...[
                Text(
                  total.toRupiah(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    decorationThickness: 2,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
