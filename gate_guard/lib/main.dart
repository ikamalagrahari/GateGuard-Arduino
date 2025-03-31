import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart' as mongo;

String mongoUri =
    "mongodb+srv://gondekarrutvik:hQyisHFDaAAnb41j@cluster0.b4u84.mongodb.net/gateguard";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // var db = await mongo.Db.create(
  //     "mongodb+srv://gondekarrutvik:hQyisHFDaAAnb41j@cluster.mongodb.net/gateguard");
  // await db.open();
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // final String mongoUri = mongoUri; // Replace with your MongoDB URI

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    var db = await mongo.Db.create(mongoUri);
    await db.open();
    var collection = db.collection('users');
    var user = await collection
        .findOne(mongo.where.eq('email', email).eq('password', password));
    await db.close();
    return user;
  }

  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    var user = await loginUser(email, password);
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid Credentials')));
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
            const Center(
                child: Text("GateGuard", style: TextStyle(fontSize: 24))),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleLogin,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  HomeScreen({required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int authorizedCards = 0;
  int totalUsers = 0;
  List<dynamic> userCards = [];

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    var db = await mongo.Db.create(mongoUri);
    await db.open();
    var usersCollection = db.collection('users');

    int cardsCount = 0;
    int usersCount = 0;
    List<dynamic> userCardsList = [];

    if (widget.user['role'] == 'admin') {
      var authorizedCardsCollection = db.collection('authorized_cards');
      cardsCount = await authorizedCardsCollection.count();
      usersCount = await usersCollection.count(mongo.where.eq('role', 'user'));
    } else {
      userCardsList = widget.user['cards'] ?? [];
    }

    await db.close();

    setState(() {
      authorizedCards = cardsCount;
      totalUsers = usersCount;
      userCards = userCardsList;
    });

    print("User Cards: ${widget.user['cards']}");

    await fetchCardScans();
  }

  Widget buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, ${widget.user['name']}!',
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (widget.user['role'] == 'admin') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildInfoCard(
                    'Authorized Cards', authorizedCards, Icons.credit_card),
                const SizedBox(width: 10),
                buildInfoCard('Users', totalUsers, Icons.people),
              ],
            ),
          ] else ...[
            Center(
              child: buildInfoCard(
                  'Your Cards', userCards.length, Icons.credit_card),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildInfoCard(String title, int count, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> cardScans = [];
  Future<void> fetchCardScans() async {
    var db = await mongo.Db.create(mongoUri);
    await db.open();
    var cardScansCollection = db.collection('card_scans');
    var authorizedCardsCollection = db.collection('authorized_cards');
    var usersCollection = db.collection('users');

    List<Map<String, dynamic>> scans = [];

    if (widget.user['role'] == 'admin') {
      // If admin, fetch all card scans
      print("Fetching all card scans...");
      scans = await cardScansCollection
          .find(mongo.where.sortBy('timestamp', descending: true))
          .toList() as List<Map<String, dynamic>>;
    } else {
      // If user, fetch only the card scans for their cards
      List<dynamic> userCards = widget.user['cards'] ?? [];

      if (userCards.isEmpty) {
        print("No card_uids found for user.");
        setState(() {
          cardScans = [];
        });
        await db.close();
        return;
      }

      // scans = await cardScansCollection
      //     .find(mongo.where.eq('card_uid', widget.user['cards'][0]))
      //     .toList(); // Convert the stream to a list

      // Temporarily replace the query with this for testing
      for (var cardUid in userCards) {
        scans.addAll(await cardScansCollection
            .find(mongo.where.eq('card_uid', cardUid))
            .toList());
      }

// Now sort the list
      scans.sort((a, b) {
        DateTime timestampA = DateTime.parse(a['timestamp']);
        DateTime timestampB = DateTime.parse(b['timestamp']);
        return timestampB.compareTo(timestampA); // Descending order
      });
    }

    // Process the scans
    for (var scan in scans) {
      try {
        // Find the card_uid in authorized_cards collection to get the associated card details
        var authorizedCard = await authorizedCardsCollection
            .findOne(mongo.where.eq('card_uid', scan['card_uid']));

        if (authorizedCard != null) {
          // Assuming each authorized card document has a 'user' field that references the user
          var userId = authorizedCard['user'];

          if (userId != null) {
            // Fetch the user associated with this card
            var user =
                await usersCollection.findOne(mongo.where.eq('_id', userId));

            if (user != null && user.containsKey('name')) {
              scan['user_name'] = user['name'] ?? 'Unknown User';
            } else {
              scan['user_name'] = 'Unknown User';
            }
          } else {
            scan['user_name'] = 'Unknown User'; // In case user_id is not found
          }
        } else {
          scan['user_name'] =
              'Unknown User'; // In case card_uid is not found in authorized_cards
        }

        DateTime timestamp = DateTime.parse(scan['timestamp']);
        scan['formatted_timestamp'] =
            DateFormat('dd-MM-yyyy hh:mm:ss a').format(timestamp);
      } catch (e) {
        print("Error processing scan: $e");
      }
    }

    if (mounted) {
      setState(() {
        cardScans = scans;
      });
    }

    await db.close();
  }

  Future<void> _refreshHistory() async {
    await fetchCardScans(); // Refetch card scans
  }

  Widget buildHistoryScreen() {
    if (cardScans.isEmpty) {
      return const Center(child: Text("No scan history available"));
    }
    return RefreshIndicator(
      // Wrap ListView with RefreshIndicator
      onRefresh: _refreshHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: cardScans.length,
        itemBuilder: (context, index) {
          var scan = cardScans[index];
          return Card(
            child: ListTile(
              leading: Icon(
                scan['accessgranted'] ? Icons.check_circle : Icons.cancel,
                color: scan['accessgranted'] ? Colors.green : Colors.red,
              ),
              title: Text('User: ${scan['user_name']}'),
              subtitle: Text('Time: ${scan['formatted_timestamp']}'),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _widgetOptions = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to log out?'),
              ],
            ),
          ),
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
                // Navigate back to the login page and remove all routes in the stack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
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
    List<Widget> _widgetOptions = [buildHomeScreen(), buildHistoryScreen()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutConfirmationDialog(
                  context); // Show the confirmation dialog
            },
          ),
        ],
      ),
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
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
