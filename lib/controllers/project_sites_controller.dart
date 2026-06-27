import 'package:flutter/foundation.dart';
import '../models/project_site.dart';
import '../services/project_sites_service.dart';

class ProjectSitesController extends ChangeNotifier {
  final _service = ProjectSitesService();

  List<ProjectSite> _projectSites = [];
  ProjectSite? _selectedSite;
  bool _isLoading = false;
  String? _error;

  List<ProjectSite> get projectSites => _projectSites;
  ProjectSite? get selectedSite => _selectedSite;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setSelectedSite(ProjectSite? site) {
    _selectedSite = site;
    notifyListeners();
  }

  Future<void> fetchProjectSites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _projectSites = await _service.fetchProjectSites();
      _projectSites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProjectSite(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newSite = await _service.createProjectSite(name);
      _projectSites.insert(0, newSite);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProjectSite(String id, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedSite = await _service.updateProjectSite(id, name);
      final index = _projectSites.indexWhere((v) => v.id == id);
      if (index != -1) {
        _projectSites[index] = updatedSite;
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleProjectSiteStatus(String id, bool currentStatus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newStatus = !currentStatus;
      await _service.updateProjectSiteStatus(id, newStatus);

      final index = _projectSites.indexWhere((v) => v.id == id);
      if (index != -1) {
        final current = _projectSites[index];
        _projectSites[index] = ProjectSite(
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
