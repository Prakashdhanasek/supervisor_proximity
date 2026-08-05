class UnassignedDevice {
  final String id;
  final String deviceId;
  final String deviceModel;
  final String osVersion;
  final String status;
  final String? assignedVehicleId;

  const UnassignedDevice({
    required this.id,
    required this.deviceId,
    required this.deviceModel,
    required this.osVersion,
    required this.status,
    this.assignedVehicleId,
  });

  factory UnassignedDevice.fromJson(Map<String, dynamic> json) =>
      UnassignedDevice(
        id: json['id'],
        deviceId: json['deviceId'],
        deviceModel: json['deviceModel'],
        osVersion: json['osVersion'],
        status: json['status'],
        assignedVehicleId: json['assignedVehicleId'],
      );
}
