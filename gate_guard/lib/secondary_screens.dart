import 'package:flutter/material.dart';
import 'api_service.dart';

class AuthorizedCardsPage extends StatefulWidget {
  @override
  _AuthorizedCardsScreenState createState() => _AuthorizedCardsScreenState();
}

class _AuthorizedCardsScreenState extends State<AuthorizedCardsPage> {
  List<Map<String, dynamic>> authorizedCards = [];

  @override
  void initState() {
    super.initState();
    _loadAuthorizedCards();
  }

  Future<void> _loadAuthorizedCards() async {
    List<Map<String, dynamic>> cards = await ApiService.fetchAuthorizedCards();
    setState(() {
      authorizedCards = cards;
    });
  }

  void _openAddCardForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAuthorizedCardPage()),
    ).then((_) => _loadAuthorizedCards()); // Refresh list after adding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authorized Cards')),
      body: RefreshIndicator(
        onRefresh: _loadAuthorizedCards, // Pull to refresh
        child: authorizedCards.isEmpty
            ? const Center(child: Text("No authorized cards found"))
            : ListView.builder(
                itemCount: authorizedCards.length,
                itemBuilder: (context, index) {
                  var card = authorizedCards[index];
                  var user = card['user'] ?? {};

                  return ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: Text("Card UID: ${card['card_uid']}"),
                    subtitle: Text(
                        "User: ${user['name'] ?? 'Unknown'} (${user['email'] ?? 'Unknown'})"),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddCardForm,
        tooltip: "Add Authorized Card",
        child: const Icon(Icons.add),
      ),
    );
  }
}

class UsersListPage extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UsersListPage> {
  late Future<List<dynamic>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = ApiService.fetchUsers();
  }

  void _openAddUserForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddUserPage()),
    ).then((_) {
      setState(() {
        _usersFuture = ApiService.fetchUsers(); // Refresh list after adding
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: FutureBuilder<List<dynamic>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          // Display list of users
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var user = snapshot.data![index];
              return ListTile(
                title: Text(user['name']),
                subtitle: Text(user['email']),
                trailing: Text(user['role'].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddUserForm,
        tooltip: "Add User",
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddAuthorizedCardPage extends StatefulWidget {
  @override
  _AddAuthorizedCardPageState createState() => _AddAuthorizedCardPageState();
}

class _AddAuthorizedCardPageState extends State<AddAuthorizedCardPage> {
  final TextEditingController _cardUidController = TextEditingController();
  String? _selectedUserId; // Stores selected user ID
  List<Map<String, dynamic>> _users = []; // Stores list of users

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Load users from API
  }

  Future<void> _fetchUsers() async {
    List<Map<String, dynamic>> users = await ApiService.fetchUsers();
    setState(() {
      _users = users;
    });
  }

  void _submitCard() async {
    String cardUid = _cardUidController.text.trim();

    if (cardUid.isEmpty || _selectedUserId == null) return;

    bool success =
        await ApiService.createAuthorizedCard(cardUid, _selectedUserId!);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authorized Card Created Successfully!')),
      );
      Navigator.pop(context); // Close the form
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create authorized card.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Authorized Card")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cardUidController,
              decoration: const InputDecoration(labelText: "Card UID"),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedUserId,
              decoration: const InputDecoration(labelText: "Select User"),
              items: _users.map<DropdownMenuItem<String>>((user) {
                return DropdownMenuItem<String>(
                  // Explicitly specify type
                  value:
                      user['_id'] as String, // Ensure '_id' is cast to String
                  child: Text("${user['name']} (${user['email']})"),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedUserId = newValue; // Update selected user
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitCard,
              child: const Text("Add Card"),
            )
          ],
        ),
      ),
    );
  }
}

class AddUserPage extends StatefulWidget {
  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // For radio button group
  String _role = 'user'; // Default to 'user'

  // Function to handle form submission
  void _submitUser() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || _role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    bool success = await ApiService.createUser(name, email, password, _role);
    if (success) {
      Navigator.pop(context); // Close the form on success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add User")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            // Role selection via Radio Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Role: "),
                Row(
                  children: [
                    Radio<String>(
                      value: 'admin',
                      groupValue: _role,
                      onChanged: (String? value) {
                        setState(() {
                          _role = value!;
                        });
                      },
                    ),
                    Text("Admin"),
                    Radio<String>(
                      value: 'user',
                      groupValue: _role,
                      onChanged: (String? value) {
                        setState(() {
                          _role = value!;
                        });
                      },
                    ),
                    Text("User"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submitUser, child: Text("Add User"))
          ],
        ),
      ),
    );
  }
}

// For USER Login
class UserCardsPage extends StatefulWidget {
  final String userId; // User ID required for fetching cards

  const UserCardsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserCardsPageState createState() => _UserCardsPageState();
}

class _UserCardsPageState extends State<UserCardsPage> {
  List<Map<String, dynamic>> _userCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserCards();
  }

  Future<void> _fetchUserCards() async {
    List<Map<String, dynamic>> cards =
        await ApiService.fetchUserCards(widget.userId);
    if (mounted) {
      setState(() {
        _userCards = cards;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Cards")),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading indicator
          : _userCards.isEmpty
              ? const Center(child: Text("No cards found."))
              : RefreshIndicator(
                  onRefresh: _fetchUserCards, // Allow pull-to-refresh
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _userCards.length,
                    itemBuilder: (context, index) {
                      var card = _userCards[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.credit_card),
                          title: Text("Card UID: ${card['card_uid']}"),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
