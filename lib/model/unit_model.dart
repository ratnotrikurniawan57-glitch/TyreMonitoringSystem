// lib/model/unit_model.dart

class UnitModel {
  final String type;
  final String classSize;
  final String unitNumber;
  final String brand;
  final String desc;
  final String status;

  UnitModel({
    required this.type,
    required this.classSize,
    required this.unitNumber,
    required this.brand,
    required this.desc,
    required this.status,
  });

  String get fullCode => "$type$classSize-$unitNumber";

  // DATA LIST 11 UNIT BOS
  static List<Map<String, dynamic>> masterDataList = [
    {'code': 'DT090-001', 'brand': 'komatsu', 'desc': 'hd 785-7'},
    {'code': 'DT090-002', 'brand': 'volvo', 'desc': 'fmx 440'},
    {'code': 'DT090-003', 'brand': 'scania', 'desc': 'p410'},
    {'code': 'DT090-004', 'brand': 'volvo', 'desc': 'fmx 400'},
    {'code': 'DT090-005', 'brand': 'komatsu', 'desc': 'hd465'},
    {'code': 'DT090-006', 'brand': 'scania', 'desc': 'r580'},
    {'code': 'DT090-007', 'brand': 'volvo', 'desc': 'fmx 440'},
    {'code': 'DT090-008', 'brand': 'komatsu', 'desc': 'hd785'},
    {'code': 'DT090-009', 'brand': 'scania', 'desc': 'p410'},
    {'code': 'DT090-010', 'brand': 'volvo', 'desc': 'fmx 400'},
    {'code': 'DT090-011', 'brand': 'komatsu', 'desc': 'hd785'},
  ];
}
