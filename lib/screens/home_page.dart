import 'package:flutter/material.dart';
import '../models/record.dart';
import '../services/data_service.dart';
import '../utils/date_utils.dart' as date_utils;
import '../widgets/summary_card.dart';
import '../widgets/net_income_card.dart';
import '../widgets/statistics_section.dart';
import '../widgets/backup_section.dart';
import '../dialogs/add_record_dialog.dart';
import 'records_list_screen.dart';

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
  String _selectedMonth = date_utils.DateUtils.getCurrentMonth();
  bool _isLoading = true;

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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final loadedData = await DataService.loadData();
      setState(() {
        data = loadedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('حدث خطأ أثناء تحميل البيانات', isError: true);
    }
  }

  Future<void> _saveData() async {
    try {
      final success = await DataService.saveData(data);
      if (!success) {
        _showMessage('حدث خطأ أثناء حفظ البيانات', isError: true);
      }
    } catch (e) {
      _showMessage('حدث خطأ أثناء حفظ البيانات', isError: true);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        backgroundColor: isError ? Colors.red[600] : const Color(0xFF4F46E5),
        behavior: SnackBarBehavior.fixed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        action: isError
            ? SnackBarAction(
                label: 'إعادة المحاولة',
                textColor: Colors.white,
                onPressed: _loadData,
              )
            : null,
      ),
    );
  }

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

  void _onDataImported(Map<String, List<Record>> importedData) async {
    try {
      // Update the data immediately
      setState(() {
        data = importedData;
      });

      // Save the imported data
      await _saveData();

      // Force UI refresh
      setState(() {});
    } catch (e) {
      _showMessage('حدث خطأ أثناء حفظ البيانات المستوردة', isError: true);
    }
  }

  String? _findMostRecentMonth() {
    Set<String> allMonths = {};

    // Collect all months from both incomes and expenses
    for (var record in data['incomes']!) {
      String month = record.date.substring(0, 7); // YYYY-MM format
      allMonths.add(month);
    }
    for (var record in data['expenses']!) {
      String month = record.date.substring(0, 7); // YYYY-MM format
      allMonths.add(month);
    }

    if (allMonths.isEmpty) return null;

    // Sort months and get the most recent
    List<String> sortedMonths = allMonths.toList()..sort();
    String mostRecentMonth = sortedMonths.last;

    // Convert back to display format (YYYY-MM)
    return mostRecentMonth;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    if (_isLoading) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري تحميل البيانات...'),
              ],
            ),
          ),
        ),
      );
    }

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
              padding: EdgeInsets.only(
                left: isTablet ? 32 : 24,
                right: isTablet ? 32 : 24,
                top: isTablet ? 32 : 24,
                bottom: 140,
              ),
              child: Column(
                children: [
                  // Modern Header
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildHeader(isTablet),
                  ),

                  const SizedBox(height: 32),

                  // Month Selector
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildMonthSelector(),
                  ),

                  const SizedBox(height: 24),

                  // Summary Cards
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildSummaryCards(),
                  ),

                  const SizedBox(height: 32),

                  // Statistics Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: StatisticsSection(
                      incomes: _getMonthTotal('incomes'),
                      expenses: _getMonthTotal('expenses'),
                      isTablet: isTablet,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Backup Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: BackupSection(
                      data: data,
                      onDataImported: _onDataImported,
                      isTablet: isTablet,
                      selectedMonth: _selectedMonth, // Add this line
                    ),
                  ),

                  // Data Summary (for debugging)
                  // if (data['incomes']!.isNotEmpty ||
                  //     data['expenses']!.isNotEmpty)
                  //   FadeTransition(
                  //     opacity: _fadeAnimation,
                  //     child: _buildDataSummary(),
                  //   ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                onPressed: () => _showAddRecordDialog(
                    'incomes',
                    'إضافة مقبوضات',
                    const Color(0xFF10B981),
                    Icons.trending_up),
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('مقبوضات'),
                heroTag: "income",
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                onPressed: () => _showAddRecordDialog(
                    'expenses',
                    'إضافة مصروفات',
                    const Color(0xFFEF4444),
                    Icons.trending_down),
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('مصروفات'),
                heroTag: "expense",
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildDataSummary() {
    final totalIncomes = data['incomes']!.length;
    final totalExpenses = data['expenses']!.length;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'إجمالي البيانات المحفوظة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$totalIncomes',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const Text('مقبوضات'),
                ],
              ),
              Column(
                children: [
                  Text(
                    '$totalExpenses',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const Text('مصروفات'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
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
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
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
    );
  }

  Widget _buildMonthSelector() {
    return Container(
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
          const Icon(Icons.calendar_month, color: Color(0xFF4F46E5)),
          const SizedBox(width: 12),
          const Text(
            'اختر الشهر:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: date_utils.DateUtils.generateMonths()
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedMonth = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final incomes = _getMonthTotal('incomes');
    final expenses = _getMonthTotal('expenses');
    final net = incomes - expenses;

    return Column(
      children: [
        SummaryCard(
          title: 'المقبوضات',
          amount: incomes,
          count: _getFilteredRecords('incomes').length,
          color: const Color(0xFF10B981),
          icon: Icons.trending_up,
          onTap: () => _navigateToRecordsList('incomes', 'المقبوضات',
              const Color(0xFF10B981), Icons.trending_up),
        ),
        const SizedBox(height: 16),
        SummaryCard(
          title: 'المصروفات',
          amount: expenses,
          count: _getFilteredRecords('expenses').length,
          color: const Color(0xFFEF4444),
          icon: Icons.trending_down,
          onTap: () => _navigateToRecordsList('expenses', 'المصروفات',
              const Color(0xFFEF4444), Icons.trending_down),
        ),
        const SizedBox(height: 16),
        NetIncomeCard(
          netIncome: net,
          isTablet: MediaQuery.of(context).size.width > 600,
        ),
      ],
    );
  }
}
