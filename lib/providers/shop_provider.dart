import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../helpers/db_helper.dart';

class ShopProvider with ChangeNotifier {
  List<Product> _products = [];
  List<CartItem> _cartItems = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;

  double get totalPrice {
    double total = 0.0;
    for (var item in _cartItems) {
      total += item.price * item.quantity;
    }
    return total;
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await DBHelper.getProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCart() async {
    _cartItems = await DBHelper.getCartItems();
    notifyListeners();
  }

  Future<void> addToCart(Product product) async {
    CartItem item = CartItem(
      productId: product.id ?? 0,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      quantity: 1,
    );
    await DBHelper.addToCart(item);
    await fetchCart();
  }

  Future<void> updateQuantity(int cartId, int newQuantity) async {
    await DBHelper.updateCartQuantity(cartId, newQuantity);
    await fetchCart();
  }

  Future<void> deleteCartItem(int cartId) async {
    await DBHelper.deleteCartItem(cartId);
    await fetchCart();
  }
}