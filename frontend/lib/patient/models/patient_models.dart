class Order {
  final String id;
  final String paymentPlatform;
  final String shippingPlatform;
  final int statusCode;
  final String statusLabel;
  final double totPrice;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.paymentPlatform,
    required this.shippingPlatform,
    required this.statusCode,
    required this.statusLabel,
    required this.totPrice,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['order_id'].toString(),
      paymentPlatform: json['payment_platform'] as String,
      shippingPlatform: json['shipping_platform'] as String,
      statusCode: json['status_code'] as int,
      statusLabel: json['status_label'] as String,
      totPrice: (json['tot_price'] as num).toDouble(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OrderItem {
  final String medicineId;
  final String medicineName;
  final String imgLink;
  final int amount;
  final double price;

  OrderItem({
    required this.medicineId,
    required this.medicineName,
    required this.imgLink,
    required this.amount,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      medicineId: json['medicine_id'].toString(),
      medicineName: json['medicine_name'] as String,
      imgLink: json['img_link'] as String,
      amount: json['amount'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
}

class ShippingAddress {
  final String address;
  final String firstName;
  final String lastName;
  final double? lat;
  final double? lon;
  final String phone;
  final String postalCode;

  ShippingAddress({
    required this.address,
    required this.firstName,
    required this.lastName,
    required this.lat,
    required this.lon,
    required this.phone,
    required this.postalCode,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      address: (json['address'] as String?)?.trim() ?? '',
      firstName: (json['first_name'] as String?)?.trim() ?? '',
      lastName: (json['last_name'] as String?)?.trim() ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      phone: (json['phone'] as String?)?.trim() ?? '',
      postalCode: (json['postal_code'] as String?)?.trim() ?? '',
    );
  }
}

class ShippingStatus {
  final String? imageUrl;
  final String orderId;
  final String? shippingPlatform;
  final List<ShippingStatusEntry> status;
  ShippingStatus({
    this.imageUrl,
    required this.orderId,
    this.shippingPlatform,
    this.status = const [],
  });

  factory ShippingStatus.fromJson(Map<String, dynamic> json) {
    return ShippingStatus(
      imageUrl: (json['image_url'] as String?)?.trim(),
      orderId: json['order_id'].toString(),
      shippingPlatform: (json['shipping_platform'] as String?)?.trim(),
      status:
          (json['status'] as List<dynamic>?)
              ?.map(
                (e) => ShippingStatusEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class ShippingStatusEntry {
  final DateTime at;
  final String? details;
  final double? lat;
  final double? lon;

  ShippingStatusEntry({required this.at, this.details, this.lat, this.lon});

  factory ShippingStatusEntry.fromJson(Map<String, dynamic> json) {
    return ShippingStatusEntry(
      at: DateTime.parse(json['at'] as String),
      details: json['details'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
    );
  }
}