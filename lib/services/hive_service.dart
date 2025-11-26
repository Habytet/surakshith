import 'package:hive_flutter/hive_flutter.dart';
// Migrated to Firestore - no longer using Hive:
// - User model (typeId 0)
// - Client model (typeId 1)
// - Project model (typeId 2)
// - Report model (typeId 3)
// - Audit Area model (typeId 4)
// - Responsible Person model (typeId 5)
// - Audit Issue model (typeId 6)
// - Audit Entry model (typeId 7)
// - FSSAI Report model (typeId 8)
// ALL MODELS MIGRATED TO FIRESTORE - HIVE NO LONGER NEEDED!
// import 'package:surakshith/data/models/project_model_hive.dart'; // MIGRATED TO FIRESTORE
// import 'package:surakshith/data/models/report_model_hive.dart'; // MIGRATED TO FIRESTORE
// import 'package:surakshith/data/models/audit_area_model_hive.dart'; // MIGRATED TO FIRESTORE
// import 'package:surakshith/data/models/responsible_person_model_hive.dart'; // MIGRATED TO FIRESTORE
// import 'package:surakshith/data/models/audit_issue_model_hive.dart'; // MIGRATED TO FIRESTORE
// import 'package:surakshith/data/models/audit_area_entry_model_hive.dart'; // MIGRATED TO FIRESTORE
// import 'package:surakshith/data/models/fssai_report_model_hive.dart'; // MIGRATED TO FIRESTORE

class HiveService {
  static Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    // typeId 0: User - MIGRATED TO FIRESTORE
    // typeId 1: Client - MIGRATED TO FIRESTORE
    // typeId 2: Project - MIGRATED TO FIRESTORE
    // typeId 3: Report - MIGRATED TO FIRESTORE
    // typeId 4: Audit Area - MIGRATED TO FIRESTORE
    // typeId 5: Responsible Person - MIGRATED TO FIRESTORE
    // typeId 6: Audit Issue - MIGRATED TO FIRESTORE
    // typeId 7: Audit Entry - MIGRATED TO FIRESTORE
    // typeId 8: FSSAI Report - MIGRATED TO FIRESTORE

    // All adapters commented out - ALL MODELS MIGRATED TO FIRESTORE!
    // if (!Hive.isAdapterRegistered(1)) {
    //   Hive.registerAdapter(ClientModelHiveAdapter()); // MIGRATED TO FIRESTORE
    // }
    // if (!Hive.isAdapterRegistered(2)) {
    //   Hive.registerAdapter(ProjectModelHiveAdapter()); // MIGRATED TO FIRESTORE
    // }
    // if (!Hive.isAdapterRegistered(3)) {
    //   Hive.registerAdapter(ReportModelHiveAdapter()); // MIGRATED TO FIRESTORE
    // }
    // if (!Hive.isAdapterRegistered(4)) {
    //   Hive.registerAdapter(AuditAreaModelHiveAdapter()); // MIGRATED TO FIRESTORE
    // }
    // if (!Hive.isAdapterRegistered(5)) {
    //   Hive.registerAdapter(ResponsiblePersonModelHiveAdapter()); // MIGRATED TO FIRESTORE
    // }
    // if (!Hive.isAdapterRegistered(6)) {
    //   Hive.registerAdapter(AuditIssueModelHiveAdapter()); // MIGRATED TO FIRESTORE
    // }
    // if (!Hive.isAdapterRegistered(7)) {
    //   Hive.registerAdapter(AuditAreaEntryModelHiveAdapter()); // MIGRATED TO FIRESTORE
    // }
    // if (!Hive.isAdapterRegistered(8)) {
    //   Hive.registerAdapter(FssaiReportModelHiveAdapter()); // MIGRATED TO FIRESTORE
    // }
  }
}
