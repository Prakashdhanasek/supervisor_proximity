import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'incidents': 'Incidents',
      'driver_performance': 'Driver Performance',
      'master_enrollment': 'Master & Enrollment',
      'approvals': 'Approvals',
      'fleet_map': 'Fleet Map',
      'search_placeholder': 'Search...',
      'all': 'All',
      'unreviewed': 'Unreviewed',
      'resolved': 'Resolved',
      'critical': 'Critical',
      'medium': 'Medium',
      'low': 'Low',
      'no_incidents': 'No incidents',
      'all_clear': 'All clear for now',
      'evidence': 'Evidence',
      'mark_resolved': 'Mark Resolved',
      'speed': 'Speed',
      'speed_limit': 'Speed Limit',
      'duration': 'Duration',
      'grade_a': 'Grade A',
      'grade_b': 'Grade B',
      'grade_c': 'Grade C',
      'grade_d': 'Grade D',
      'no_drivers_grade': 'No drivers in this grade',
      'score_breakdown': 'SCORE BREAKDOWN',
      'incident_breakdown': 'INCIDENT BREAKDOWN (THIS WEEK)',
      'weekly_trend': 'WEEKLY SAFETY TREND',
      'drivers': 'Drivers',
      'vehicles': 'Vehicles',
      'enroll': 'Enroll',
      'register': 'Register',
      'total': 'Total',
      'active': 'Active',
      'idle': 'Idle',
      'alert': 'Alert',
      'enrolled_drivers': 'enrolled drivers',
      'language': 'Language',
      'theme': 'Theme',
      'all_fleets': 'All Fleets',
      'offline': 'Offline',
      'live_fleet': 'Live Fleet',
      'live': 'Live',
      'search_drivers': 'Search drivers or vehicles...',
      'settings': 'Settings',
      'configuration_settings': 'CONFIGURATION SETTINGS',
      'vehicle_types': 'Vehicle Types',
      'project_sites': 'Project / Sites',
    },
    'ar': {
      'incidents': 'الحوادث',
      'driver_performance': 'أداء السائق',
      'master_enrollment': 'الرئيسية والتسجيل',
      'approvals': 'الموافقات',
      'fleet_map': 'خريطة الأسطول',
      'search_placeholder': 'بحث...',
      'all': 'الكل',
      'unreviewed': 'غير مراجعة',
      'resolved': 'محلول',
      'critical': 'حرج',
      'medium': 'متوسط',
      'low': 'منخفض',
      'no_incidents': 'لا توجد حوادث',
      'all_clear': 'كل شيء واضح الآن',
      'evidence': 'دليل',
      'mark_resolved': 'تحديد كمحلول',
      'speed': 'السرعة',
      'speed_limit': 'الحد الأقصى للسرعة',
      'duration': 'المدة',
      'grade_a': 'درجة A',
      'grade_b': 'درجة B',
      'grade_c': 'درجة C',
      'grade_d': 'درجة D',
      'no_drivers_grade': 'لا يوجد سائقين في هذه الدرجة',
      'score_breakdown': 'تفاصيل النتيجة',
      'incident_breakdown': 'تفاصيل الحوادث (هذا الأسبوع)',
      'weekly_trend': 'اتجاه السلامة الأسبوعي',
      'drivers': 'السائقين',
      'vehicles': 'المركبات',
      'enroll': 'تسجيل',
      'register': 'تسجيل',
      'total': 'الإجمالي',
      'active': 'نشط',
      'idle': 'خامل',
      'alert': 'تنبيه',
      'enrolled_drivers': 'السائقين المسجلين',
      'language': 'اللغة',
      'theme': 'السمة',
      'all_fleets': 'كل الأساطيل',
      'offline': 'غير متصل',
      'live_fleet': 'الأسطول المباشر',
      'live': 'مباشر',
      'search_drivers': 'البحث عن السائقين أو المركبات...',
      'settings': 'الإعدادات',
      'configuration_settings': 'إعدادات التكوين',
      'vehicle_types': 'أنواع المركبات',
      'project_sites': 'المشروع / المواقع',
    },
    'hi': {
      'incidents': 'घटनाएं',
      'driver_performance': 'ड्राइवर का प्रदर्शन',
      'master_enrollment': 'मास्टर और नामांकन',
      'approvals': 'मंजूरी',
      'fleet_map': 'बेड़े का नक्शा',
      'search_placeholder': 'खोजें...',
      'all': 'सभी',
      'unreviewed': 'असमीक्षित',
      'resolved': 'सुलझा हुआ',
      'critical': 'गंभीर',
      'medium': 'मध्यम',
      'low': 'कम',
      'no_incidents': 'कोई घटनाएं नहीं',
      'all_clear': 'अभी सब ठीक है',
      'evidence': 'प्रमाण',
      'mark_resolved': 'सुलझा हुआ चिह्नित करें',
      'speed': 'गति',
      'speed_limit': 'गति सीमा',
      'duration': 'अवधि',
      'grade_a': 'ग्रेड A',
      'grade_b': 'ग्रेड B',
      'grade_c': 'ग्रेड C',
      'grade_d': 'ग्रेड D',
      'no_drivers_grade': 'इस ग्रेड में कोई ड्राइवर नहीं',
      'score_breakdown': 'स्कोर का विवरण',
      'incident_breakdown': 'घटना का विवरण (इस सप्ताह)',
      'weekly_trend': 'साप्ताहिक सुरक्षा रुझान',
      'drivers': 'ड्राइवर',
      'vehicles': 'वाहन',
      'enroll': 'नामांकन करें',
      'register': 'रजिस्टर करें',
      'total': 'कुल',
      'active': 'सक्रिय',
      'idle': 'निष्क्रिय',
      'alert': 'चेतावनी',
      'enrolled_drivers': 'पंजीकृत ड्राइवर',
      'language': 'भाषा',
      'theme': 'थीम',
      'all_fleets': 'सभी बेड़े',
      'offline': 'ऑफ़लाइन',
      'live_fleet': 'लाइव बेड़ा',
      'live': 'लाइव',
      'search_drivers': 'ड्राइवर या वाहन खोजें...',
      'settings': 'सेटिंग्स',
      'configuration_settings': 'कॉन्फ़िगरेशन सेटिंग्स',
      'vehicle_types': 'वाहन के प्रकार',
      'project_sites': 'प्रोजेक्ट / साइटें',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
