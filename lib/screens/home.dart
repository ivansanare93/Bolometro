  Future<void> _bootstrap() async {
    final uid = authService.userId;
    if (uid != null) {
      await dataRepository.setUser(uid);
      await dataRepository.obtenerPerfil();
    }
    // Open the Hive box as before
    // ... other bootstrap code ...
  }