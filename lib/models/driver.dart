class DriverFacePhoto {
  final String id;
  final String driverId;
  final String photoPath;
  final String faceCondition;
  final DateTime capturedAt;

  DriverFacePhoto({
    required this.id,
    required this.driverId,
    required this.photoPath,
    required this.faceCondition,
    required this.capturedAt,
  });

  factory DriverFacePhoto.fromJson(Map<String, dynamic> json) {
    return DriverFacePhoto(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      photoPath: json['photoPath'] as String,
      faceCondition: json['faceCondition'] as String? ?? 'face',
      capturedAt: json['capturedAt'] != null
          ? DateTime.parse(json['capturedAt'] as String)
          : DateTime.now(),
    );
  }
}

class AssignedVehicle {
  final String vehicleId;
  final String vehicleRegistrationNumber;
  final int overspeedThreshold;

  AssignedVehicle({
    required this.vehicleId,
    required this.vehicleRegistrationNumber,
    required this.overspeedThreshold,
  });

  factory AssignedVehicle.fromJson(Map<String, dynamic> json) {
    return AssignedVehicle(
      vehicleId: json['vehicleId'] as String,
      vehicleRegistrationNumber:
          json['vehicleRegistrationNumber'] as String? ?? 'Unknown',
      overspeedThreshold: json['overspeedThreshold'] as int? ?? 60,
    );
  }
}

class Driver {
  final String id;
  final String fullName;
  final String email;
  final String mobileNumber;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String assignedProjectSite;
  final List<AssignedVehicle> assignedVehicles;
  final String shift;
  final bool faceEnrollNormalFace;
  final bool faceEnrollWithSpectacles;
  final bool faceEnrollLowLightCabin;
  final bool faceEnrollCabinLighting;
  final bool faceEnrollFixedTabletAngle;
  final bool faceEnrollSunglasses;
  final String? username;
  final bool isActive;
  final String status;
  final String preferredLanguage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DriverFacePhoto> facePhotos;
  final String? supervisorName;
  final String? adminName;

  Driver({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.assignedProjectSite,
    required this.assignedVehicles,
    required this.shift,
    required this.faceEnrollNormalFace,
    required this.faceEnrollWithSpectacles,
    required this.faceEnrollLowLightCabin,
    required this.faceEnrollCabinLighting,
    required this.faceEnrollFixedTabletAngle,
    required this.faceEnrollSunglasses,
    this.username,
    required this.isActive,
    required this.status,
    required this.preferredLanguage,
    required this.createdAt,
    required this.updatedAt,
    required this.facePhotos,
    this.supervisorName,
    this.adminName,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String? ?? '',
      licenseExpiry: json['licenseExpiry'] != null
          ? DateTime.parse(json['licenseExpiry'] as String)
          : DateTime.now(),
      assignedProjectSite:
          json['assignedProjectSite'] as String? ?? 'Unassigned',
      assignedVehicles:
          (json['assignedVehicles'] as List<dynamic>?)
              ?.map((v) => AssignedVehicle.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      shift: json['shift'] as String? ?? 'General',
      faceEnrollNormalFace: json['faceEnrollNormalFace'] as bool? ?? false,
      faceEnrollWithSpectacles:
          json['faceEnrollWithSpectacles'] as bool? ?? false,
      faceEnrollLowLightCabin:
          json['faceEnrollLowLightCabin'] as bool? ?? false,
      faceEnrollCabinLighting:
          json['faceEnrollCabinLighting'] as bool? ?? false,
      faceEnrollFixedTabletAngle:
          json['faceEnrollFixedTabletAngle'] as bool? ?? false,
      faceEnrollSunglasses: json['faceEnrollSunglasses'] as bool? ?? false,
      username: json['username'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      status: json['status'] as String? ?? 'Active',
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      facePhotos:
          (json['facePhotos'] as List<dynamic>?)
              ?.map((p) => DriverFacePhoto.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      supervisorName: json['supervisorName'] as String?,
      adminName: json['adminName'] as String?,
    );
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  String get vehicleDisplay {
    if (assignedVehicles.isNotEmpty) {
      return assignedVehicles
          .map((v) => v.vehicleRegistrationNumber)
          .join(', ');
    }
    return 'Unassigned';
  }

  List<String> get enrolledFaceConditions {
    final conditions = <String>[];
    if (faceEnrollNormalFace) conditions.add('Normal Face');
    if (faceEnrollWithSpectacles) conditions.add('With Spectacles');
    if (faceEnrollLowLightCabin) conditions.add('Low Light Cabin');
    if (faceEnrollCabinLighting) conditions.add('Cabin Lighting');
    if (faceEnrollFixedTabletAngle) conditions.add('Fixed Tablet Angle');
    if (faceEnrollSunglasses) conditions.add('Sunglasses (if permitted)');
    return conditions;
  }

  List<String> get facePhotoUrls {
    return facePhotos
        .map((p) => 'https://proximity-driver-api.prod-app.in${p.photoPath}')
        .toList();
  }

  String get normalizedStatus {
    if (!isActive) return 'SUSPENDED';
    final s = status.toLowerCase();
    if (s.contains('pending')) return 'PENDING';
    if (s.contains('suspend')) return 'SUSPENDED';
    return 'ACTIVE';
  }
}
