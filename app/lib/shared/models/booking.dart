class Booking {
  final int id;
  final String touristId;
  final String guideId;
  final String? guideName;
  final String destination;
  final String tourDate;
  final double durationHours;
  final int groupSize;
  final double grossValue;
  final String status;
  final String paymentStatus;

  Booking({
    required this.id,
    required this.touristId,
    required this.guideId,
    this.guideName,
    required this.destination,
    required this.tourDate,
    required this.durationHours,
    required this.groupSize,
    required this.grossValue,
    required this.status,
    required this.paymentStatus,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      touristId: json['tourist_id'] as String,
      guideId: json['guide_id'] as String,
      guideName: json['guide_name'] as String?,
      destination: json['destination'] as String,
      tourDate: json['tour_date'] as String,
      durationHours: (json['duration_hours'] as num).toDouble(),
      groupSize: json['group_size'] as int,
      grossValue: (json['gross_value'] as num).toDouble(),
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
    );
  }
}

class ItineraryStop {
  final String name;
  final int order;
  final double durationHours;

  ItineraryStop({
    required this.name,
    required this.order,
    required this.durationHours,
  });

  factory ItineraryStop.fromJson(Map<String, dynamic> json) {
    return ItineraryStop(
      name: json['name'] as String,
      order: json['order'] as int,
      durationHours: (json['duration_hours'] as num).toDouble(),
    );
  }
}

class Itinerary {
  final int? id;
  final int bookingId;
  final List<ItineraryStop> stops;
  final String status;

  Itinerary({
    this.id,
    required this.bookingId,
    required this.stops,
    required this.status,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] as int?,
      bookingId: json['booking_id'] as int,
      stops: (json['stops'] as List)
          .map((s) => ItineraryStop.fromJson(s as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String,
    );
  }
}
