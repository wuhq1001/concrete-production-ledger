import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const ConcreteLedgerApp());

class ConcreteLedgerApp extends StatelessWidget {
  const ConcreteLedgerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '混凝土生产台帐',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B62)),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const LedgerHomePage(),
      );
}

enum UserRole { administrator, operator, viewer }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
        UserRole.administrator => '管理员（演示）',
        UserRole.operator => '操作员（演示）',
        UserRole.viewer => '只读人员（演示）',
      };
}

class ProductionRecord {
  ProductionRecord({
    required this.dateTime,
    required this.project,
    required this.site,
    required this.strength,
    required this.mixCode,
    required this.volume,
    required this.slump,
    required this.truck,
    required this.operator,
    required this.cement,
    required this.water,
    required this.sand,
    required this.aggregate,
    required this.admixture,
    required this.notes,
  });

  final DateTime dateTime;
  final String project;
  final String site;
  final String strength;
  final String mixCode;
  final double volume;
  final double slump;
  final String truck;
  final String operator;
  final double cement;
  final double water;
  final double sand;
  final double aggregate;
  final double admixture;
  final String notes;
}

class LedgerHomePage extends StatefulWidget {
  const LedgerHomePage({super.key});

  @override
  State<LedgerHomePage> createState() => _LedgerHomePageState();
}

class _LedgerHomePageState extends State<LedgerHomePage> {
  UserRole _role = UserRole.administrator;
  String _query = '';
  final List<ProductionRecord> _records = [
    ProductionRecord(
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      project: '滨江花园一期',
      site: '2号楼基础底板',
      strength: 'C35',
      mixCode: 'P-C35-02',
      volume: 48,
      slump: 180,
      truck: '浙A·12345',
      operator: '张师傅',
      cement: 360,
      water: 165,
      sand: 720,
      aggregate: 1050,
      admixture: 5.4,
      notes: '正常生产',
    ),
    ProductionRecord(
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      project: '滨江花园一期',
      site: '5号楼剪力墙',
      strength: 'C40',
      mixCode: 'P-C40-01',
      volume: 32.5,
      slump: 160,
      truck: '浙A·67890',
      operator: '李师傅',
      cement: 410,
      water: 158,
      sand: 690,
      aggregate: 1080,
      admixture: 6.2,
      notes: '',
    ),
  ];

  bool get _canAdd => _role != UserRole.viewer;
  bool get _canDelete => _role == UserRole.administrator;

  List<ProductionRecord> get _filteredRecords {
    final query = _query.trim().toLowerCase();
    final items = _records.where((record) {
      if (query.isEmpty) return true;
      return [
        record.project,
        record.site,
        record.strength,
        record.mixCode,
        record.truck,
        record.operator,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return items;
  }

  double get _totalVolume => _records.fold(0, (sum, item) => sum + item.volume);

  double get _todayVolume {
    final now = DateTime.now();
    return _records
        .where((r) => r.dateTime.year == now.year && r.dateTime.month == now.month && r.dateTime.day == now.day)
        .fold(0, (sum, item) => sum + item.volume);
  }

  Future<void> _addRecord() async {
    final record = await showDialog<ProductionRecord>(
      context: context,
      builder: (_) => const _RecordFormDialog(),
    );
    if (record != null && mounted) setState(() => _records.add(record));
  }

  Future<void> _exportCsv() async {
    final rows = <List<String>>[
      ['生产时间', '工程名称', '施工部位', '强度等级', '配合比编号', '方量(m³)', '坍落度(mm)', '运输车号', '操作员', '水泥(kg/m³)', '水(kg/m³)', '砂(kg/m³)', '石(kg/m³)', '外加剂(kg/m³)', '备注'],
      ..._filteredRecords.map((r) => [
            _formatDateTime(r.dateTime), r.project, r.site, r.strength, r.mixCode,
            r.volume.toString(), r.slump.toString(), r.truck, r.operator,
            r.cement.toString(), r.water.toString(), r.sand.toString(),
            r.aggregate.toString(), r.admixture.toString(), r.notes,
          ]),
    ];
    String cell(String value) => '"${value.replaceAll('"', '""')}"';
    final csv = '\uFEFF${rows.map((row) => row.map(cell).join(',')).join('\r\n')}';
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('台帐 CSV 已复制，可粘贴到表格软件中')),
      );
    }
  }

  void _deleteRecord(ProductionRecord record) {
    setState(() => _records.remove(record));
  }

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;
    return Scaffold(
      appBar: AppBar(
        title: const Text('混凝土生产台帐'),
        actions: [
          PopupMenuButton<UserRole>(
            tooltip: '切换演示身份',
            initialValue: _role,
            onSelected: (role) => setState(() => _role = role),
            itemBuilder: (context) => UserRole.values
                .map((role) => PopupMenuItem(value: role, child: Text(role.label)))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Chip(avatar: const Icon(Icons.person_outline, size: 18), label: Text(_role.label)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _canAdd
          ? FloatingActionButton.extended(
              onPressed: _addRecord,
              icon: const Icon(Icons.add),
              label: const Text('新增生产记录'),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 10),
                      Expanded(child: Text('原型演示：记录暂存于当前会话，重启后不会保留；身份切换仅用于展示界面权限。')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth > 650 ? 3 : 1;
                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 3.3 : 2.8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _SummaryCard(title: '今日生产方量', value: '${_todayVolume.toStringAsFixed(1)} m³', icon: Icons.today_outlined),
                    _SummaryCard(title: '累计记录方量', value: '${_totalVolume.toStringAsFixed(1)} m³', icon: Icons.local_concrete_outlined),
                    _SummaryCard(title: '生产记录数', value: '${_records.length} 条', icon: Icons.receipt_long_outlined),
                  ],
                );
              }),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Text('生产记录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  OutlinedButton.icon(onPressed: _exportCsv, icon: const Icon(Icons.file_download_outlined), label: const Text('复制 CSV')),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  hintText: '搜索工程、部位、强度、车号或操作员',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('没有找到生产记录')),
                )
              else
                ...records.map(_buildRecordCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(ProductionRecord record) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${record.project} · ${record.site}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  if (_canDelete)
                    IconButton(
                      tooltip: '删除记录（演示）',
                      onPressed: () => _deleteRecord(record),
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoText('时间', _formatDateTime(record.dateTime)),
                  _InfoText('强度', record.strength),
                  _InfoText('配合比', record.mixCode),
                  _InfoText('方量', '${record.volume} m³'),
                  _InfoText('坍落度', '${record.slump} mm'),
                  _InfoText('车号', record.truck),
                  _InfoText('操作员', record.operator),
                ],
              ),
              const Divider(height: 24),
              Text('材料用量（kg/m³）：水泥 ${record.cement} · 水 ${record.water} · 砂 ${record.sand} · 石 ${record.aggregate} · 外加剂 ${record.admixture}'),
              if (record.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('备注：${record.notes}'),
              ],
            ],
          ),
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text(title), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))],
              ),
            ],
          ),
        ),
      );
}

class _InfoText extends StatelessWidget {
  const _InfoText(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: '$label：', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _RecordFormDialog extends StatefulWidget {
  const _RecordFormDialog();

  @override
  State<_RecordFormDialog> createState() => _RecordFormDialogState();
}

class _RecordFormDialogState extends State<_RecordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {
    for (final name in [
      '工程名称', '施工部位', '强度等级', '配合比编号', '生产方量(m³)', '坍落度(mm)',
      '运输车号', '操作员', '水泥(kg/m³)', '水(kg/m³)', '砂(kg/m³)', '石(kg/m³)', '外加剂(kg/m³)', '备注',
    ]) name: TextEditingController(),
  };
  DateTime _dateTime = DateTime.now();

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? '请填写此项' : null;
  double _number(String key) => double.tryParse(_fields[key]!.text.trim()) ?? 0;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ProductionRecord(
        dateTime: _dateTime,
        project: _fields['工程名称']!.text.trim(),
        site: _fields['施工部位']!.text.trim(),
        strength: _fields['强度等级']!.text.trim(),
        mixCode: _fields['配合比编号']!.text.trim(),
        volume: _number('生产方量(m³)'),
        slump: _number('坍落度(mm)'),
        truck: _fields['运输车号']!.text.trim(),
        operator: _fields['操作员']!.text.trim(),
        cement: _number('水泥(kg/m³)'),
        water: _number('水(kg/m³)'),
        sand: _number('砂(kg/m³)'),
        aggregate: _number('石(kg/m³)'),
        admixture: _number('外加剂(kg/m³)'),
        notes: _fields['备注']!.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('新增生产记录'),
        content: SizedBox(
          width: 560,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('生产时间'),
                    subtitle: Text(_formatDateTime(_dateTime)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 8),
                  ..._fields.entries.map((entry) {
                    final numeric = entry.key.contains('方量') || entry.key.contains('mm)') || entry.key.contains('kg/m³');
                    final optional = entry.key == '备注';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: entry.value,
                        validator: optional ? null : _required,
                        keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                        maxLines: entry.key == '备注' ? 2 : 1,
                        decoration: InputDecoration(labelText: entry.key),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: _save, child: const Text('保存')),
        ],
      );

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dateTime));
    if (time == null || !mounted) return;
    setState(() => _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}

String _formatDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
}
