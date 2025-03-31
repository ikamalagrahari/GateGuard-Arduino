import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GateGuard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    var result = await ApiService.loginUser(email, password);
    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen(user: result['user'])),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid Credentials')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("GateGuard", style: TextStyle(fontSize: 24)),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _handleLogin, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int authorizedCards = 0;
  int totalUsers = 0;
  List<dynamic> userCards = [];
  List<dynamic> cardScans = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchCardScans();
  }

  Future<void> _fetchDashboardData() async {
    var data = await ApiService.fetchDashboardData(
        widget.user['_id'], widget.user['role']);
    if (data != null) {
      setState(() {
        authorizedCards = data['authorizedCards'];
        totalUsers = data['totalUsers'];
        userCards = data['userCards'] ?? [];
      });
    }
  }

  Future<void> _fetchCardScans() async {
    var scans = await ApiService.fetchCardScans(
        widget.user['_id'], widget.user['role'], userCards);
    setState(() {
      cardScans = scans;
    });
  }

  Widget _buildInfoCard(String title, int count, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 18)),
            Text('$count',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return RefreshIndicator(
      onRefresh: _fetchDashboardData, // Correct function name for refreshing
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Allow pull even when content is small
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${widget.user['name']}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (widget.user['role'] == 'admin') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard(
                      'Authorized Cards', authorizedCards, Icons.credit_card),
                  const SizedBox(width: 10),
                  _buildInfoCard('Users', totalUsers, Icons.people),
                ],
              ),
            ] else ...[
              Center(
                child: _buildInfoCard(
                    'Your Cards', userCards.length, Icons.credit_card),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryScreen() {
    return RefreshIndicator(
      onRefresh: _fetchCardScans,
      child: cardScans.isEmpty
          ? const Center(child: Text("No scan history available"))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: cardScans.length,
              itemBuilder: (context, index) {
                var scan = cardScans[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                        scan['accessgranted']
                            ? Icons.check_circle
                            : Icons.cancel,
                        color:
                            scan['accessgranted'] ? Colors.green : Colors.red),
                    title: Text('User: ${scan['user_name']}'),
                    subtitle: Text(
                        'Time: ${DateFormat('dd-MM-yyyy hh:mm:ss a').format(DateTime.parse(scan['timestamp']))}'),
                  ),
                );
              },
            ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                // Perform logout actions (e.g., clear stored tokens)
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false, // Remove all previous routes
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _widgetOptions = [_buildHomeScreen(), _buildHistoryScreen()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
