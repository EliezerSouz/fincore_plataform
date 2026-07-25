import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pdv_item.dart';

enum PdvState {
  idle,
  drafting,
  selectingCustomer,
  selectingPayment,
  awaitingPix,
  completed,
  error
}

class PdvExpressController extends ChangeNotifier {
  PdvState _state = PdvState.idle;
  PdvState get state => _state;

  final List<PdvItem> _cart = [];
  List<PdvItem> get cart => List.unmodifiable(_cart);

  String? _customerPhone;
  String? get customerPhone => _customerPhone;

  String? _customerName;
  String? get customerName => _customerName;

  String _paymentMethod = 'Dinheiro';
  String get paymentMethod => _paymentMethod;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _pixTimer;
  int _pixCountdown = 120;
  int get pixCountdown => _pixCountdown;

  void changeState(PdvState newState) {
    _state = newState;
    notifyListeners();
  }

  int get totalInCents => _cart.fold(0, (sum, item) => sum + item.totalInCents);

  void addItem(String id, String name, int priceInCents, double quantity) {
    final index = _cart.indexWhere((item) => item.productId == id);
    if (index != -1) {
      _cart[index].quantity += quantity;
    } else {
      _cart.add(PdvItem(
        productId: id,
        name: name,
        priceInCents: priceInCents,
        quantity: quantity,
      ));
    }
    _state = PdvState.drafting;
    notifyListeners();
  }

  void updateQuantity(String id, double newQty) {
    final index = _cart.indexWhere((item) => item.productId == id);
    if (index != -1) {
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = newQty;
      }
    }
    if (_cart.isEmpty) {
      _state = PdvState.idle;
    } else {
      _state = PdvState.drafting;
    }
    notifyListeners();
  }

  void selectCustomer(String name, String phone) {
    _customerName = name;
    _customerPhone = phone;
    _state = _cart.isEmpty ? PdvState.idle : PdvState.drafting;
    notifyListeners();
  }

  void clearCustomer() {
    _customerName = null;
    _customerPhone = null;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void reset() {
    _cart.clear();
    _customerPhone = null;
    _customerName = null;
    _paymentMethod = 'Dinheiro';
    _errorMessage = null;
    _pixTimer?.cancel();
    _pixCountdown = 120;
    _state = PdvState.idle;
    notifyListeners();
  }

  void startCheckout() {
    if (_cart.isEmpty) {
      _errorMessage = 'O carrinho está vazio.';
      _state = PdvState.error;
      notifyListeners();
      return;
    }
    _state = PdvState.selectingPayment;
    notifyListeners();
  }

  void confirmPayment() {
    if (_paymentMethod == 'PIX') {
      _state = PdvState.awaitingPix;
      _pixCountdown = 120;
      notifyListeners();
      
      // Simular Webhook de Recebimento do PIX Cloud em 5 segundos
      _pixTimer?.cancel();
      _pixTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_pixCountdown > 115) {
          _pixCountdown--;
          notifyListeners();
        } else {
          timer.cancel();
          _state = PdvState.completed;
          notifyListeners();
        }
      });
    } else {
      _state = PdvState.completed;
      notifyListeners();
    }
  }

  void retryPix() {
    _errorMessage = null;
    confirmPayment();
  }

  void forceContingente() {
    // contingência local sem sincronia imediata
    _pixTimer?.cancel();
    _paymentMethod = 'PIX Contingente';
    _state = PdvState.completed;
    notifyListeners();
  }

  @override
  void dispose() {
    _pixTimer?.cancel();
    super.dispose();
  }
}
