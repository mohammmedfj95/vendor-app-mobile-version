import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'new_sale_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3142);
    final cardColor = Theme.of(context).cardColor;
    final shadowColor =
        isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  'Here\'s what\'s happening today',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    child: _buildDashboardCard(
                      context,
                      'Total Products',
                      '256',
                      Icons.inventory,
                      const Color(0xFF6C63FF),
                      isDarkMode
                          ? const Color(0xFF2C2C54)
                          : const Color(0xFFE8E7FF),
                    ),
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: _buildDashboardCard(
                      context,
                      'Low Stock',
                      '12',
                      Icons.warning_amber,
                      const Color(0xFFFF6B6B),
                      isDarkMode
                          ? const Color(0xFF542C2C)
                          : const Color(0xFFFFE8E8),
                    ),
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    child: _buildDashboardCard(
                      context,
                      'Total Sales',
                      '\$15,240',
                      Icons.attach_money,
                      const Color(0xFF4CAF50),
                      isDarkMode
                          ? const Color(0xFF2C542C)
                          : const Color(0xFFE8F5E9),
                    ),
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: _buildDashboardCard(
                      context,
                      'Categories',
                      '8',
                      Icons.category,
                      const Color(0xFFFF9800),
                      isDarkMode
                          ? const Color(0xFF544C2C)
                          : const Color(0xFFFFF3E0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FadeInUp(
                duration: const Duration(milliseconds: 1100),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sales Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const titles = [
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                      'Sun'
                                    ];
                                    if (value.toInt() < 0 ||
                                        value.toInt() >= titles.length) {
                                      return const Text('');
                                    }
                                    return Text(
                                      titles[value.toInt()],
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [
                                  FlSpot(0, 3),
                                  FlSpot(1, 4),
                                  FlSpot(2, 3.5),
                                  FlSpot(3, 5),
                                  FlSpot(4, 4),
                                  FlSpot(5, 6),
                                  FlSpot(6, 5.5),
                                ],
                                isCurved: true,
                                color: const Color(0xFF6C63FF),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color:
                                      const Color(0xFF6C63FF).withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                duration: const Duration(milliseconds: 1200),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Recent Activities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      _buildActivityItem(
                        'New Product Added',
                        'Wireless Headphones',
                        'Just now',
                        const Color(0xFF6C63FF),
                        Icons.add_shopping_cart,
                        isDarkMode,
                      ),
                      const Divider(height: 1),
                      _buildActivityItem(
                        'Sale Completed',
                        'Order #123 - \$299',
                        '2 hours ago',
                        const Color(0xFF4CAF50),
                        Icons.sell,
                        isDarkMode,
                      ),
                      const Divider(height: 1),
                      _buildActivityItem(
                        'Low Stock Alert',
                        'Smart Watch - 2 items left',
                        '5 hours ago',
                        const Color(0xFFFF6B6B),
                        Icons.warning_amber,
                        isDarkMode,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewSaleScreen()),
            );
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('New Sale'),
          backgroundColor: const Color(0xFF6C63FF),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, String value,
      IconData icon, Color color, Color backgroundColor) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardColor = Theme.of(context).cardColor;
    final shadowColor =
        isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time,
      Color color, IconData icon, bool isDarkMode) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : const Color(0xFF2D3142),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: Text(
        time,
        style: TextStyle(
          color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
          fontSize: 12,
        ),
      ),
    );
  }
}
