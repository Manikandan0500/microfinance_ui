import 'package:flutter/material.dart';
import 'product_launcher.dart';
import '../programs/mock_database.dart';
import '../programs/region_master_screen.dart';
import '../programs/branch_region_map_screen.dart';
import '../programs/loan_product_master_screen.dart';
import '../programs/delinquency_bucket_master_screen.dart';
import '../programs/penalty_rate_history_screen.dart';
import '../programs/asset_classification_gl_map_screen.dart';
import '../programs/prepayment_foreclosure_config_screen.dart';
import '../programs/rate_revision_history_screen.dart';
import '../programs/holiday_calendar_screen.dart';
import '../programs/authorization_screen.dart';
import '../programs/auth_config_screen.dart';


// ── AM Masters Screens ──────────────────────────────────────────────────────
import '../am_masters/screens/organizations_screen.dart';
import '../am_masters/screens/branches_screen.dart';
import '../am_masters/screens/products_screen.dart';
import '../am_masters/screens/product_mapping_screen.dart';
import '../am_masters/screens/user_accounts_screen.dart';
import '../am_masters/screens/user_product_mapping_screen.dart';
import '../am_masters/screens/modules_screen.dart';
import '../am_masters/screens/menu_master_screen.dart';
import '../am_masters/config/app_config.dart';
import '../Login/services/auth_service 4.dart';
import '../am_masters/models/user.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isSidebarHovered = false;
  final GlobalKey _nineDotsKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  OverlayEntry? _profileOverlayEntry;
  
  // Active navigation section
  String _selectedPage = 'Dashboard';
  
  // Database instance
  final MockDatabase _db = MockDatabase();

  // Logged-in user
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _db.addListener(_onDbChanged);
    _currentUser = AuthService().currentUser;
  }

  @override
  void dispose() {
    _db.removeListener(_onDbChanged);
    _closeProductLauncher();
    _closeProfileOverlay();
    super.dispose();
  }

  void _onDbChanged() {
    if (mounted) setState(() {});
  }

  // ── Profile overlay ────────────────────────────────────────────────────────
  void _closeProfileOverlay() {
    _profileOverlayEntry?.remove();
    _profileOverlayEntry = null;
  }

  void _toggleProfileOverlay() {
    if (_profileOverlayEntry != null) {
      _closeProfileOverlay();
      return;
    }
    final RenderBox renderBox =
        _profileKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final user = _currentUser;

    _profileOverlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeProfileOverlay,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 8,
            right: MediaQuery.of(context).size.width -
                offset.dx -
                size.width,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header band
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E3A5F), Color(0xFF0A1628)],
                        ),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              _initials(user),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _fullName(user),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if ((user?.title ?? '').isNotEmpty)
                            Text(
                              user!.title!,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    // Detail rows
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Column(
                        children: [
                          _profileRow(
                              Icons.phone_outlined, 'Mobile',
                              user?.mobile ?? '—'),
                          _profileRow(
                              Icons.email_outlined, 'Email',
                              user?.email ?? '—'),
                          _profileRow(
                              Icons.corporate_fare_outlined, 'Org Code',
                              user?.orgCode?.toString() ?? '—'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_profileOverlayEntry!);
  }

  String _fullName(User? user) {
    if (user == null) return 'User Profile';
    final parts = [
      user.fName ?? '',
      user.mName ?? '',
      user.lName ?? '',
    ].where((p) => p.isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : user.name ?? 'User Profile';
  }

  String _initials(User? user) {
    final f = user?.fName ?? user?.name ?? '';
    final l = user?.lName ?? '';
    if (f.isEmpty && l.isEmpty) return 'UP';
    return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'
        .toUpperCase();
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleProductLauncher() {
    if (_overlayEntry != null) {
      _closeProductLauncher();
    } else {
      _showProductLauncher();
    }
  }

  void _closeProductLauncher() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showProductLauncher() {
    final RenderBox renderBox = _nineDotsKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = ProductLauncher.createOverlayEntry(
      offset: offset,
      size: size,
      onClose: _closeProductLauncher,
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header (Top bar)
          Container(
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF0A1628), // very dark navy
                  Color(0xFF152238), // dark blue
                  Color(0xFF1E3A5F), // medium dark blue
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  key: _nineDotsKey,
                  icon: const Icon(Icons.apps, color: Colors.white, size: 32),
                  onPressed: _toggleProductLauncher,
                  tooltip: 'Product Launcher',
                ),
                const SizedBox(width: 8),
                const Text(
                  'MICRO FINANCE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                const Spacer(),
                // ── User profile section ──────────────────────────────────────────
                GestureDetector(
                  key: _profileKey,
                  onTap: _toggleProfileOverlay,
                  child: Row(
                    children: [
                      Text(
                        _fullName(_currentUser),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          _initials(_currentUser),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.white24,
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () async {
                    await AuthService().logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
          // Body below header
          Expanded(
            child: Row(
              children: [
                // Sidebar with Hover effect
                MouseRegion(
                  onEnter: (_) => setState(() => _isSidebarHovered = true),
                  onExit: (_) => setState(() => _isSidebarHovered = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _isSidebarHovered ? 260 : 70,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF0A1628), // very dark navy
                          Color(0xFF152238), // dark blue
                          Color(0xFF1E3A5F), // medium dark blue
                        ],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                      children: [
                        const SizedBox(height: 16),
                        if (_isSidebarHovered)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'MENU',
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              _buildMenuItem(
                                icon: Icons.dashboard_outlined,
                                title: 'Dashboard',
                                isSelected: _selectedPage == 'Dashboard',
                                onTap: () {
                                  setState(() {
                                    _selectedPage = 'Dashboard';
                                  });
                                },
                              ),
                              if (_isSidebarHovered)
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    dividerColor: Colors.transparent,
                                  ),
                                  child: ExpansionTile(
                                    leading: const Icon(Icons.folder_open, color: Colors.white70),
                                    title: const Text('MF Masters', style: TextStyle(color: Colors.white, fontSize: 14)),
                                    iconColor: Colors.white,
                                    collapsedIconColor: Colors.white70,
                                    childrenPadding: const EdgeInsets.only(left: 12.0),
                                    initiallyExpanded: false,
                                    children: [
                                      _buildSubMenuItem('Region Master', Icons.map_outlined),
                                      _buildSubMenuItem('Branch Region Map', Icons.account_tree_outlined),
                                      _buildSubMenuItem('Loan Product Master', Icons.credit_score_outlined),
                                      _buildSubMenuItem('Delinquency Bucket Master', Icons.warning_amber_outlined),
                                      _buildSubMenuItem('Penalty Rate History', Icons.gavel_outlined),
                                      _buildSubMenuItem('Asset Classification GL Map', Icons.category_outlined),
                                      _buildSubMenuItem('Prepayment / Foreclosure Configuration', Icons.settings_outlined),
                                      _buildSubMenuItem('Rate Revision History', Icons.trending_up_outlined),
                                      _buildSubMenuItem('Holiday Calendar', Icons.calendar_month_outlined),
                                    ],
                                  ),
                                ),
                              if (_isSidebarHovered)
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    dividerColor: Colors.transparent,
                                  ),
                                  child: ExpansionTile(
                                    leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white70),
                                    title: const Text('AM Masters', style: TextStyle(color: Colors.white, fontSize: 14)),
                                    iconColor: Colors.white,
                                    collapsedIconColor: Colors.white70,
                                    childrenPadding: const EdgeInsets.only(left: 12.0),
                                    initiallyExpanded: false,
                                    children: [
                                      _buildSubMenuItem('Organizations', Icons.apartment_outlined),
                                      _buildSubMenuItem('Branches', Icons.account_balance_outlined),
                                      _buildSubMenuItem('Products', Icons.inventory_2_outlined),
                                      _buildSubMenuItem('Product Mapping', Icons.link_outlined),
                                      _buildSubMenuItem('User Accounts', Icons.group_outlined),
                                      _buildSubMenuItem('User Product Mapping', Icons.security_outlined),
                                      _buildSubMenuItem('Modules', Icons.view_module_outlined),
                                      _buildSubMenuItem('Menu Master', Icons.menu_book_outlined),
                                    ],
                                  ),
                                ),
                              if (_isSidebarHovered)
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    dividerColor: Colors.transparent,
                                  ),
                                  child: ExpansionTile(
                                    leading: const Icon(Icons.computer_outlined, color: Colors.white70),
                                    title: const Text('System', style: TextStyle(color: Colors.white, fontSize: 14)),
                                    iconColor: Colors.white,
                                    collapsedIconColor: Colors.white70,
                                    childrenPadding: const EdgeInsets.only(left: 12.0),
                                    initiallyExpanded: false,
                                    children: [
                                      _buildSubMenuItem('Configuration', Icons.settings_applications_outlined),
                                      _buildSubMenuItem('Authorization Queue', Icons.security_outlined),
                                    ],
                                  ),
                                )
                              else ...[
                                _buildMenuItem(
                                  icon: Icons.folder_open,
                                  title: 'MF Masters',
                                  isSelected: false,
                                  onTap: () {},
                                ),
                                _buildMenuItem(
                                  icon: Icons.admin_panel_settings_outlined,
                                  title: 'AM Masters',
                                  isSelected: false,
                                  onTap: () {},
                                ),
                                _buildMenuItem(
                                  icon: Icons.computer_outlined,
                                  title: 'System',
                                  isSelected: false,
                                  onTap: () {},
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8F9FC),
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedPage) {
      // ── MF Masters ────────────────────────────────────────────────────────
      case 'Region Master':
        return const RegionMasterScreen();
      case 'Branch Region Map':
        return const BranchRegionMapScreen();
      case 'Loan Product Master':
        return const LoanProductMasterScreen();
      case 'Delinquency Bucket Master':
        return const DelinquencyBucketMasterScreen();
      case 'Penalty Rate History':
        return const PenaltyRateHistoryScreen();
      case 'Asset Classification GL Map':
        return const AssetClassificationGlMapScreen();
      case 'Prepayment / Foreclosure Configuration':
        return const PrepaymentForeclosureConfigScreen();
      case 'Rate Revision History':
        return const RateRevisionHistoryScreen();
      case 'Holiday Calendar':
        return const HolidayCalendarScreen();
      // ── AM Masters ────────────────────────────────────────────────────────
      case 'Organizations':
        return const Organizations();
      case 'Branches':
        return const Branches();
      case 'Products':
        return const Products();
      case 'Product Mapping':
        return const ProductOrganization();
      case 'User Accounts':
        return Users();
      case 'User Product Mapping':
        return const UserAccess();
      case 'Modules':
        return Modules();
      case 'Menu Master':
        return MenuMaster();
      // ── System ────────────────────────────────────────────────────────────
      case 'Configuration':
        return const AuthConfigScreen();
      case 'Authorization Queue':
        return const AuthorizationScreen();

      // ── Dashboard ─────────────────────────────────────────────────────────
      case 'Dashboard':
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Microfinance Settings Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2640),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Configure loan products, regions, buckets, prepayment fees, holiday shifts, and accounting General Ledgers.',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 2.0,
              children: [
                _buildDashboardCard('Region Master', 'Setup geographic and management regions above branches.', Icons.location_city, _db.regions.length),
                _buildDashboardCard('Branch Region Map', 'Map core foundation branches to custom regions.', Icons.map, _db.branchMaps.length),
                _buildDashboardCard('Loan Product Master', 'Configure products interest rules and range constraints.', Icons.account_balance, _db.loanProducts.length),
                _buildDashboardCard('Delinquency Bucket Master', 'Define regulatory NPA stages and bucket penalty ranges.', Icons.assignment_late, _db.delinquencyBuckets.length),
                _buildDashboardCard('Penalty Rate History', 'Effective-dated penalty rate definitions per product stage.', Icons.history, _db.penaltyRates.length),
                _buildDashboardCard('Asset Classification GL Map', 'Link balance sheet GL heads per delinquency classification.', Icons.account_tree, _db.assetGlMaps.length),
                _buildDashboardCard('Prepayment / Foreclosure Configuration', 'Penalty values and recalc methods for early payouts.', Icons.settings, _db.prepaymentConfigs.length),
                _buildDashboardCard('Rate Revision History', 'Floating-rate benchmark revisions audit trail.', Icons.rate_review, _db.rateRevisions.length),
                _buildDashboardCard('Holiday Calendar', 'Manage organization/branch holidays and shifting due dates.', Icons.calendar_month, _db.holidays.length),
                // AM Masters / System
                _buildDashboardCard('Authorization Queue', 'Review and approve/reject pending system authorizations.', Icons.verified_user, 0),
                _buildDashboardCard('Organizations', 'Manage parent organization units.', Icons.apartment, 0),
                _buildDashboardCard('User Accounts', 'Manage system users and access roles.', Icons.group, 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, String desc, IconData icon, int count) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E9F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedPage = title;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF2A5C91), size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E2640)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$count total records',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.white10,
      splashColor: Colors.transparent,
      child: Container(
        color: isSelected ? const Color(0xFF2A5C91) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: _isSidebarHovered ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 22),
            if (_isSidebarHovered) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(String title, IconData icon) {
    final isSelected = _selectedPage == title;
    return Container(
      color: isSelected ? const Color(0xFF242F50) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        hoverColor: Colors.white10,
        splashColor: Colors.transparent,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
        visualDensity: const VisualDensity(vertical: -2),
        onTap: () {
          setState(() {
            _selectedPage = title;
          });
        },
      ),
    );
  }
}
