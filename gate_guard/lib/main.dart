import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'secondary_screens.dart';

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
  bool _obscurePassword = true;
  bool _isLoading = false; // New loading flag

  void _handleLogin() async {
    setState(() {
      _isLoading = true; // Show loading spinner
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    var result = await ApiService.loginUser(email, password);

    setState(() {
      _isLoading = false; // Hide loading spinner
    });

    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen(user: result['user'])),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.lock, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 40),
                const Text(
                  "Welcome to GateGuard!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("LOGIN", style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    setState(() => _isLoading = true); // Start loading
    await _fetchDashboardData();
    await _fetchCardScans();
    setState(() => _isLoading = false); // Done loading
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
      color: Colors.blue, // Set card background to blue
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14), // Rounded corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White count for readability
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAuthorizedCards() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthorizedCardsPage(),
      ),
    );
  }

  void _navigateToUsersList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UsersListPage(),
      ),
    );
  }

  void _navigatetoUserCards() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserCardsPage(userId: widget.user['_id']),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return RefreshIndicator(
      onRefresh: _initializeDashboard, // refresh both data sets
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: CircularProgressIndicator(color: Colors.blue),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${widget.user['name']}!',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (widget.user['role'] == 'admin') ...[
                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _navigateToAuthorizedCards,
                            child: SizedBox(
                              width: double.infinity,
                              child: _buildInfoCard('Authorized Cards',
                                  authorizedCards, Icons.credit_card),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _navigateToUsersList,
                            child: SizedBox(
                              width: double.infinity,
                              child: _buildInfoCard(
                                  'Users', totalUsers, Icons.people),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: GestureDetector(
                        onTap: _navigatetoUserCards,
                        child: SizedBox(
                          width: double.infinity,
                          child: _buildInfoCard('Your Cards', userCards.length,
                              Icons.credit_card),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildHistoryScreen() {
    return RefreshIndicator(
      onRefresh: _initializeDashboard, // or just _fetchCardScans if preferred
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            )
          : cardScans.isEmpty
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
                              scan['accessgranted'] ? Colors.green : Colors.red,
                        ),
                        title: Text('User: ${scan['user_name']}'),
                        subtitle: Text(
                          'Date: ${DateFormat('dd-MM-yyyy hh:mm:ss a').format(
                            DateTime.parse(scan['timestamp']),
                          )}',
                        ),
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
