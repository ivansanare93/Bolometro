import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../services/auth_service.dart';
import '../services/friends_service.dart';
import '../l10n/app_localizations.dart';

/// Pantalla de gestión de amigos
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendsService _friendsService = FriendsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.userId;
    final localizations = AppLocalizations.of(context)!;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.friends),
        ),
        body: Center(
          child: Text(localizations.loginRequiredMessage),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.friends),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.people), text: localizations.myFriends),
            Tab(icon: const Icon(Icons.person_add), text: localizations.friendRequests),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(userId),
          _buildFriendRequests(userId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFriendDialog(context, userId),
        icon: const Icon(Icons.person_add),
        label: Text(localizations.addFriend),
      ),
    );
  }

  Widget _buildFriendsList(String userId) {
    final localizations = AppLocalizations.of(context)!;
    
    return StreamBuilder<List<Friend>>(
      stream: _friendsService.streamAmigos(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('${localizations.error}: ${snapshot.error}'),
          );
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.noFriendsYet,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.addFriendsToCompare,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _buildFriendCard(friend, userId);
          },
        );
      },
    );
  }

  Widget _buildFriendCard(Friend friend, String userId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: friend.photoUrl != null
              ? NetworkImage(friend.photoUrl!)
              : null,
          child: friend.photoUrl == null
              ? Text(friend.nombre[0].toUpperCase())
              : null,
        ),
        title: Text(friend.nombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (friend.email != null) Text(friend.email!),
            const SizedBox(height: 4),
            if (friend.totalPartidas != null && friend.promedioGeneral != null)
              Text(
                '${friend.totalPartidas} partidas • Promedio: ${friend.promedioGeneral!.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  const Icon(Icons.person_remove, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.removeFriend),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'remove') {
              _confirmRemoveFriend(friend, userId);
            }
          },
        ),
      ),
    );
  }

  Widget _buildFriendRequests(String userId) {
    final localizations = AppLocalizations.of(context)!;
    
    return StreamBuilder<List<FriendRequest>>(
      stream: _friendsService.streamSolicitudesPendientes(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('${localizations.error}: ${snapshot.error}'),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.noPendingRequests,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request, userId);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(FriendRequest request, String userId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: request.fromUserPhotoUrl != null
              ? NetworkImage(request.fromUserPhotoUrl!)
              : null,
          child: request.fromUserPhotoUrl == null
              ? Text(request.fromUserName[0].toUpperCase())
              : null,
        ),
        title: Text(request.fromUserName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (request.fromUserEmail != null) Text(request.fromUserEmail!),
            const SizedBox(height: 4),
            Text(
              _getTimeAgo(request.createdAt),
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _acceptRequest(request, userId),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _rejectRequest(request, userId),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context, String userId) {
    final emailController = TextEditingController();
    final authService = Provider.of<AuthService>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.addFriend),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizations.searchFriend),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: localizations.email,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.enterEmail)),
                );
                return;
              }

              // Validate email format
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.enterValidEmail)),
                );
                return;
              }

              Navigator.pop(context);

              // Buscar usuario
              final user = await _friendsService.buscarUsuarioPorEmail(email);

              if (user == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.userNotFound)),
                );
                return;
              }

              // Enviar solicitud
              final currentUser = authService.user;
              if (currentUser == null) return;

              final success = await _friendsService.enviarSolicitudAmistad(
                fromUserId: currentUser.uid,
                fromUserName: currentUser.displayName ?? 'Usuario',
                fromUserEmail: currentUser.email,
                fromUserPhotoUrl: currentUser.photoURL,
                toUserId: user['userId'],
              );

              if (!context.mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(localizations.friendRequestSent)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(localizations.couldNotSendRequest)),
                );
              }
            },
            child: Text(localizations.sendRequest),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(FriendRequest request, String userId) async {
    final localizations = AppLocalizations.of(context)!;
    final success = await _friendsService.aceptarSolicitudAmistad(
      userId,
      request,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.requestAccepted)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.error} al aceptar solicitud')),
      );
    }
  }

  Future<void> _rejectRequest(FriendRequest request, String userId) async {
    final localizations = AppLocalizations.of(context)!;
    final success = await _friendsService.rechazarSolicitudAmistad(
      userId,
      request.requestId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.requestRejected)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.error} al rechazar solicitud')),
      );
    }
  }

  void _confirmRemoveFriend(Friend friend, String userId) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.removeFriend),
        content:
            Text(localizations.confirmRemoveFriend.replaceAll('{name}', friend.nombre)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);

              final success = await _friendsService.eliminarAmigo(
                userId,
                friend.userId,
              );

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.friendRemoved)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${localizations.error} al eliminar amigo')),
                );
              }
            },
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Hace menos de un minuto';
    }
  }
}
