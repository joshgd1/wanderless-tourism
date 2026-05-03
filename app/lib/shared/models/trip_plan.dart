class ProposedStop {
  final String name;
  final double durationHours;
  final String? notes;

  ProposedStop({
    required this.name,
    required this.durationHours,
    this.notes,
  });

  factory ProposedStop.fromJson(Map<String, dynamic> json) {
    return ProposedStop(
      name: json['name'] as String,
      durationHours: (json['duration_hours'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'duration_hours': durationHours,
      if (notes != null) 'notes': notes,
    };
  }
}

class TripPlan {
  final int id;
  final String touristId;
  final String destination;
  final List<String> interests;
  final List<ProposedStop> proposedStops;
  final String status;
  final String? guideId;
  final String? tourDate;
  final double? durationHours;
  final int? groupSize;
  final double? safetyWeight;
  final String? dietaryRequirement;
  final bool? avoidLateNight;
  final String? createdAt;

  TripPlan({
    required this.id,
    required this.touristId,
    required this.destination,
    required this.interests,
    required this.proposedStops,
    required this.status,
    this.guideId,
    this.tourDate,
    this.durationHours,
    this.groupSize,
    this.safetyWeight,
    this.dietaryRequirement,
    this.avoidLateNight,
    this.createdAt,
  });

  factory TripPlan.fromJson(Map<String, dynamic> json) {
    return TripPlan(
      id: json['id'] as int,
      touristId: json['tourist_id'] as String,
      destination: json['destination'] as String,
      interests: (json['interests'] as List).cast<String>(),
      proposedStops: (json['proposed_stops'] as List)
          .map((s) => ProposedStop.fromJson(s as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String,
      guideId: json['guide_id'] as String?,
      tourDate: json['tour_date_start'] as String?,
      durationHours: (json['duration_hours'] as num?)?.toDouble(),
      groupSize: json['group_size'] as int?,
      safetyWeight: (json['safety_weight'] as num?)?.toDouble(),
      dietaryRequirement: json['dietary_requirement'] as String?,
      avoidLateNight: json['avoid_late_night'] as bool?,
      createdAt: json['created_at'] as String?,
    );
  }
}
