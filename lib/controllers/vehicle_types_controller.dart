import 'package:flutter/foundation.dart';
import '../models/vehicle_type.dart';
import '../services/vehicle_types_service.dart';

class VehicleTypesController extends ChangeNotifier {
  final _service = VehicleTypesService();
  
  List<VehicleType> _vehicleTypes = [];
  bool _isLoading = false;
  String? _error;

  List<VehicleType> get vehicleTypes => _vehicleTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchVehicleTypes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehicleTypes = await _service.fetchVehicleTypes();
      // Sort by creation date descending (newest first)
      _vehicleTypes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createVehicleType(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newType = await _service.createVehicleType(name);
      _vehicleTypes.insert(0, newType);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVehicleType(String id, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedType = await _service.updateVehicleType(id, name);
      final index = _vehicleTypes.indexWhere((v) => v.id == id);
      if (index != -1) {
        _vehicleTypes[index] = updatedType;
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleVehicleTypeStatus(String id, bool currentStatus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newStatus = !currentStatus;
      await _service.updateVehicleTypeStatus(id, newStatus);
      
      final index = _vehicleTypes.indexWhere((v) => v.id == id);
      if (index != -1) {
        final current = _vehicleTypes[index];
        _vehicleTypes[index] = VehicleType(
          id: current.id,
          name: current.name,
          isActive: newStatus,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          createdByName: current.createdByName,
        );
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
