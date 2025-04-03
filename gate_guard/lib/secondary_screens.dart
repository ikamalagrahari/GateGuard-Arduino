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

  void _editCard(Map<String, dynamic> card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAuthorizedCardPage(existingCard: card),
      ),
    ).then((_) => _loadAuthorizedCards()); // Refresh list after editing
  }

  void _deleteCard(String cardId) async {
    bool success = await ApiService.deleteAuthorizedCard(cardId);
    if (success) {
      _loadAuthorizedCards();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Card deleted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete card")),
      );
    }
  }

  void _showCardOptions(Map<String, dynamic> card) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit"),
            onTap: () {
              Navigator.pop(context);
              _editCard(card);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Delete"),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(card['_id']);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String cardUid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Card"),
        content: const Text("Are you sure you want to delete this card?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCard(cardUid);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authorized Cards')),
      body: RefreshIndicator(
        onRefresh: _loadAuthorizedCards,
        child: authorizedCards.isEmpty
            ? const Center(child: Text("No authorized cards found"))
            : ListView.builder(
                itemCount: authorizedCards.length,
                itemBuilder: (context, index) {
                  var card = authorizedCards[index];
                  var user = card['user'] ?? {};

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      leading: const Icon(Icons.credit_card),
                      title: Text("Card UID: ${card['card_uid']}"),
                      subtitle: Text(
                          "User: ${user['name'] ?? 'Unknown'} (${user['email'] ?? 'Unknown'})"),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showCardOptions(card),
                      ),
                    ),
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
  _UsersListPageState createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  late Future<List<dynamic>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = ApiService.fetchUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = ApiService.fetchUsers();
    });
  }

  void _openAddUserForm({Map<String, dynamic>? user}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddUserPage(user: user)),
    ).then((_) => _refreshUsers()); // Refresh list after add/update
  }

  void _showUserOptions(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit"),
            onTap: () {
              Navigator.pop(context);
              _openAddUserForm(user: user);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Delete"),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(user['_id']);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await ApiService.deleteUser(userId);
              if (success) _refreshUsers();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
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

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var user = snapshot.data![index];
              return ListTile(
                title: Text(user['name']),
                subtitle: Text(user['email']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(user['role'].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showUserOptions(user),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddUserForm(),
        tooltip: "Add User",
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddAuthorizedCardPage extends StatefulWidget {
  final Map<String, dynamic>? existingCard;

  const AddAuthorizedCardPage({Key? key, this.existingCard}) : super(key: key);

  @override
  _AddAuthorizedCardPageState createState() => _AddAuthorizedCardPageState();
}

class _AddAuthorizedCardPageState extends State<AddAuthorizedCardPage> {
  final TextEditingController _cardUidController = TextEditingController();
  String? _selectedUserId; // Stores selected user ID
  late Future<List<Map<String, dynamic>>> _usersFuture; // Future for users

  @override
  void initState() {
    super.initState();
    _usersFuture = ApiService.fetchUsers();
    if (widget.existingCard != null) {
      _cardUidController.text = widget.existingCard!['card_uid'];
      _selectedUserId = widget.existingCard!['user']['_id'];
    }
  }

  Future<void> _submitCard() async {
    String cardUid = _cardUidController.text.trim();

    if (cardUid.isEmpty || _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter card UID and select a user.')),
      );
      return;
    }

    bool success;
    if (widget.existingCard == null) {
      success =
          await ApiService.createAuthorizedCard(cardUid, _selectedUserId!);
    } else {
      success = await ApiService.updateAuthorizedCard(
          widget.existingCard!['_id'], cardUid, _selectedUserId!);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.existingCard == null
                ? 'Card Created Successfully!'
                : 'Card Updated Successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process the request.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCard == null
            ? "Add Authorized Card"
            : "Edit Authorized Card"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cardUidController,
              decoration: const InputDecoration(labelText: "Card UID"),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Text("Error loading users.");
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("No users available.");
                }

                return DropdownButtonFormField<String>(
                  value: _selectedUserId,
                  decoration: const InputDecoration(labelText: "Select User"),
                  items: snapshot.data!.map<DropdownMenuItem<String>>((user) {
                    return DropdownMenuItem<String>(
                      value: user['_id'] as String,
                      child: Text("${user['name']} (${user['email']})"),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedUserId = newValue;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitCard,
              child: Text(
                  widget.existingCard == null ? "Add Card" : "Update Card"),
            ),
          ],
        ),
      ),
    );
  }
}

class AddUserPage extends StatefulWidget {
  final Map<String, dynamic>? user; // Optional user for editing

  const AddUserPage({Key? key, this.user}) : super(key: key);

  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _role = 'user'; // Default role

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      // Prefill form fields if updating user
      _nameController.text = widget.user!['name'];
      _emailController.text = widget.user!['email'];
      _role = widget.user!['role'];
    }
  }

  void _submitUser() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || _role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    bool success;
    if (widget.user == null) {
      // Create new user
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password is required for new users')),
        );
        return;
      }
      success = await ApiService.createUser(name, email, password, _role);
    } else {
      // Update existing user
      success = await ApiService.updateUser(
          widget.user!['_id'], name, email, _role, password);
    }

    if (success) {
      Navigator.pop(context); // Close the form on success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.user == null ? "Add User" : "Edit User")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            if (widget.user == null) // Only show password field for new users
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text("Role: "),
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
                    const Text("Admin"),
                    Radio<String>(
                      value: 'user',
                      groupValue: _role,
                      onChanged: (String? value) {
                        setState(() {
                          _role = value!;
                        });
                      },
                    ),
                    const Text("User"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitUser,
              child: Text(widget.user == null ? "Add User" : "Update User"),
            ),
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
