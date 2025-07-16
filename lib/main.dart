import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';

void main() => runApp(const FinanceApp());

class Record {
  String desc;
  double amount;
  String date; // YYYY-MM-DD

  Record({required this.desc, required this.amount, required this.date});

  factory Record.fromJson(Map<String, dynamic> j) =>
      Record(desc: j['desc'], amount: j['amount'], date: j['date']);

  Map<String, dynamic> toJson() =>
      {'desc': desc, 'amount': amount, 'date': date};
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'ArabicFont',
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
        cardTheme: CardTheme(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar')],
      locale: const Locale('ar'),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  Map<String, List<Record>> data = {
    'incomes': [],
    'expenses': [],
  };

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/data.json');
  }

  Future<void> _loadData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final jo = json.decode(jsonStr);
        setState(() {
          data['incomes'] =
              (jo['incomes'] as List).map((e) => Record.fromJson(e)).toList();
          data['expenses'] =
              (jo['expenses'] as List).map((e) => Record.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  Future<void> _saveData() async {
    final file = await _localFile;
    final jo = {
      'incomes': data['incomes']!.map((r) => r.toJson()).toList(),
      'expenses': data['expenses']!.map((r) => r.toJson()).toList(),
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jo),
        flush: true);
  }

  List<String> get _months => List.generate(18, (i) {
        final d = DateTime.now().subtract(Duration(days: 30 * i));
        return DateFormat('yyyy-MM').format(d);
      });

  List<Record> _getFilteredRecords(String type) {
    return data[type]!.where((r) => r.date.startsWith(_selectedMonth)).toList();
  }

  double _getMonthTotal(String type) {
    return _getFilteredRecords(type).fold(0.0, (sum, r) => sum + r.amount);
  }

  void _navigateToRecordsList(
      String type, String title, Color color, IconData icon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordsListScreen(
          type: type,
          title: title,
          color: color,
          icon: icon,
          records: _getFilteredRecords(type),
          selectedMonth: _selectedMonth,
          onDelete: (record) {
            setState(() {
              data[type]!.remove(record);
            });
            _saveData();
          },
        ),
      ),
    );
  }

  void _showAddRecordDialog(
      String type, String title, Color color, IconData icon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddRecordDialog(
        type: type,
        title: title,
        color: color,
        icon: icon,
        onAdd: (record) {
          setState(() {
            data[type]!.add(record);
          });
          _saveData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF1F5F9),
                Color(0xFFE0E7FF),
                Color(0xFFEDE9FE),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              child: Column(
                children: [
                  // Modern Header
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4F46E5),
                                    Color(0xFF7C3AED)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4F46E5)
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Text(
                                'إدارة المالية',
                                style: TextStyle(
                                  fontSize: isTablet ? 36 : 28,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..shader = const LinearGradient(
                                      colors: [
                                        Color(0xFF4F46E5),
                                        Color(0xFF7C3AED)
                                      ],
                                    ).createShader(
                                        const Rect.fromLTWH(0, 0, 200, 70)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تتبع مقبوضاتك ومصروفاتك بطريقة ذكية وحديثة',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Month Selector
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              color: Color(0xFF4F46E5)),
                          const SizedBox(width: 12),
                          const Text(
                            'اختر الشهر:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedMonth,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              items: _months
                                  .map((m) => DropdownMenuItem(
                                      value: m, child: Text(m)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null)
                                  setState(() => _selectedMonth = v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Summary Cards - Clickable
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildClickableSummaryCards(isTablet),
                  ),

                  const SizedBox(height: 32),

                  // Statistics Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildStatisticsSection(isTablet),
                  ),

                  const SizedBox(height: 105),

                  // Backup Section
                  // FadeTransition(
                  //   opacity: _fadeAnimation,
                  //   child: _buildBackupSection(isTablet),
                  // ),
                ],
              ),
            ),
          ),
        ),

        // Floating Action Buttons
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Add Income FAB
            FloatingActionButton.extended(
              onPressed: () => _showAddRecordDialog('incomes', 'إضافة مقبوضات',
                  const Color(0xFF10B981), Icons.trending_up),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('مقبوضات'),
              heroTag: "income",
            ),

            const SizedBox(height: 8),

            // Add Expense FAB
            FloatingActionButton.extended(
              onPressed: () => _showAddRecordDialog('expenses', 'إضافة مصروفات',
                  const Color(0xFFEF4444), Icons.trending_down),
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('مصروفات'),
              heroTag: "expense",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableSummaryCards(bool isTablet) {
    final incomes = _getMonthTotal('incomes');
    final expenses = _getMonthTotal('expenses');
    final net = incomes - expenses;

    return Column(
      children: [
        // Income and Expense Cards
        _buildClickableSummaryCard(
            'المقبوضات',
            incomes,
            _getFilteredRecords('incomes').length,
            const Color(0xFF10B981),
            Icons.trending_up,
            () => _navigateToRecordsList('incomes', 'المقبوضات',
                const Color(0xFF10B981), Icons.trending_up)),
        const SizedBox(height: 16),
        _buildClickableSummaryCard(
            'المصروفات',
            expenses,
            _getFilteredRecords('expenses').length,
            const Color(0xFFEF4444),
            Icons.trending_down,
            () => _navigateToRecordsList('expenses', 'المصروفات',
                const Color(0xFFEF4444), Icons.trending_down)),

        const SizedBox(height: 16),

        // Net Income Card
        _buildNetIncomeCard(net, isTablet),
      ],
    );
  }

  Widget _buildClickableSummaryCard(String title, double amount, int count,
      Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Touch indicator
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.touch_app, color: Colors.white, size: 16),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(icon,
                          color: Colors.white.withOpacity(0.8), size: 28),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        "${amount.toStringAsFixed(0)} ₪",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count عملية',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetIncomeCard(double net, bool isTablet) {
    final color = net >= 0 ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B);
    final isProfit = net >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isProfit ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'صافي الدخل',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${net.toStringAsFixed(0)} ₪",
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 36 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isProfit ? 'ربح' : 'خسارة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(bool isTablet) {
    final incomes = _getMonthTotal('incomes');
    final expenses = _getMonthTotal('expenses');
    final total = incomes + expenses;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bar_chart,
                    color: Color(0xFF4F46E5), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'إحصائيات الشهر',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (total > 0) ...[
            // Income Percentage
            _buildStatBar(
              'المقبوضات',
              incomes,
              total > 0 ? (incomes / total) : 0,
              const Color(0xFF10B981),
            ),

            const SizedBox(height: 12),

            // Expense Percentage
            _buildStatBar(
              'المصروفات',
              expenses,
              total > 0 ? (expenses / total) : 0,
              const Color(0xFFEF4444),
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد بيانات لعرض الإحصائيات',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBar(
      String title, double amount, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerRight,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// Add Record Dialog
class AddRecordDialog extends StatefulWidget {
  final String type;
  final String title;
  final Color color;
  final IconData icon;
  final Function(Record) onAdd;

  const AddRecordDialog({
    super.key,
    required this.type,
    required this.title,
    required this.color,
    required this.icon,
    required this.onAdd,
  });

  @override
  State<AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<AddRecordDialog>
    with TickerProviderStateMixin {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _addRecord() {
    final desc = _descController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (desc.isEmpty || amount <= 0) {
      _showErrorDialog('املأ كل الحقول بشكل صحيح');
      return;
    }

    final record = Record(
      desc: desc,
      amount: amount,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );

    widget.onAdd(record);
    Navigator.pop(context);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('تم إضافة ${widget.title.replaceAll('إضافة ', '')} بنجاح'),
        backgroundColor: widget.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 16,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      widget.color.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.color,
                                  widget.color.withOpacity(0.8)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.color.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(widget.icon,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: widget.color,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description Field
                      TextFormField(
                        controller: _descController,
                        decoration: InputDecoration(
                          labelText: 'وصف العملية',
                          hintText: 'أدخل وصف مفصل للعملية',
                          prefixIcon:
                              Icon(Icons.description, color: widget.color),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: widget.color, width: 2),
                          ),
                          filled: true,
                          fillColor: widget.color.withOpacity(0.05),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Amount Field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'المبلغ',
                          hintText: '0.00',
                          prefixIcon:
                              Icon(Icons.attach_money, color: widget.color),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: widget.color, width: 2),
                          ),
                          filled: true,
                          fillColor: widget.color.withOpacity(0.05),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Date Field
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            locale: const Locale('ar'),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: widget.color),
                              const SizedBox(width: 12),
                              const Text('التاريخ: '),
                              Text(
                                DateFormat('yyyy-MM-dd').format(_selectedDate),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_drop_down, color: widget.color),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                              child: const Text('إلغاء'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _addRecord,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.color,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'إضافة العملية',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Records List Screen (same as before but with minor improvements)
class RecordsListScreen extends StatelessWidget {
  final String type;
  final String title;
  final Color color;
  final IconData icon;
  final List<Record> records;
  final String selectedMonth;
  final Function(Record) onDelete;

  const RecordsListScreen({
    super.key,
    required this.type,
    required this.title,
    required this.color,
    required this.icon,
    required this.records,
    required this.selectedMonth,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final total = records.fold(0.0, (sum, r) => sum + r.amount);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF1F5F9),
                Color(0xFFE0E7FF),
                Color(0xFFEDE9FE),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(isTablet ? 32 : 24),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_forward, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: isTablet ? 28 : 24,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              'الشهر: $selectedMonth',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Total Card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إجمالي الشهر',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${total.toStringAsFixed(0)} ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${records.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Records List
                Expanded(
                  child: records.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد عمليات هذا الشهر',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'استخدم الأزرار العائمة لإضافة عمليات جديدة',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 32 : 16),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding:
                                    EdgeInsets.all(isTablet ? 20 : 16),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon,
                                      color: color, size: isTablet ? 28 : 24),
                                ),
                                title: Text(
                                  record.desc,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isTablet ? 18 : 16,
                                  ),
                                ),
                                subtitle: Text(
                                  record.date,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: isTablet ? 14 : 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 16 : 12,
                                        vertical: isTablet ? 8 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            color,
                                            color.withOpacity(0.8)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        record.amount.toStringAsFixed(0),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isTablet ? 16 : 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.red[400],
                                      onPressed: () =>
                                          _showDeleteDialog(context, record),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Record record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${record.desc}"؟'),
        actions: [
          TextButton(
            onPressed: () {
              onDelete(record);
              Navigator.pop(context);
              Navigator.pop(context); // Go back to main screen
            },
            child: Text('نعم', style: TextStyle(color: color)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لا'),
          ),
        ],
      ),
    );
  }
}
