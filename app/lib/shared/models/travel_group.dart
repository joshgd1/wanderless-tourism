class TravelGroupMember {
  final String initials;
  final String colorHex;
  final String status;

  TravelGroupMember({
    required this.initials,
    required this.colorHex,
    required this.status,
  });

  factory TravelGroupMember.fromJson(Map<String, dynamic> json) {
    return TravelGroupMember(
      initials: json['initials'] as String? ?? '??',
      colorHex: json['color_hex'] as String? ?? '#888888',
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}

class TravelGroup {
  final int id;
  final String destination;
  final String status;
  final String? coherence;
  final String? proposedDate;
  final double? proposedDuration;
  final int minSize;
  final int maxSize;
  final int memberCount;
  final String? guideId;
  final List<TravelGroupMember>? members;
  final Map<String, dynamic>? guide;

  TravelGroup({
    required this.id,
    required this.destination,
    required this.status,
    this.coherence,
    this.proposedDate,
    this.proposedDuration,
    required this.minSize,
    required this.maxSize,
    required this.memberCount,
    this.guideId,
    this.members,
    this.guide,
  });

  factory TravelGroup.fromJson(Map<String, dynamic> json) {
    return TravelGroup(
      id: json['id'] as int,
      destination: json['destination'] as String,
      status: json['status'] as String,
      coherence: json['coherence'] as String?,
      proposedDate: json['proposed_date'] as String?,
      proposedDuration: (json['proposed_duration'] as num?)?.toDouble(),
      minSize: json['min_size'] as int? ?? 3,
      maxSize: json['max_size'] as int? ?? 8,
      memberCount: json['member_count'] as int? ?? 0,
      guideId: json['guide_id'] as String?,
      members: json['members'] != null
          ? (json['members'] as List)
              .map((m) => TravelGroupMember.fromJson(m as Map<String, dynamic>))
              .toList()
          : null,
      guide: json['guide'] as Map<String, dynamic>?,
    );
  }
}
