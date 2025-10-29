import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Storage Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const StorageExamplePage(),
    );
  }
}

class StorageExamplePage extends StatefulWidget {
  const StorageExamplePage({super.key});

  @override
  State<StorageExamplePage> createState() => _StorageExamplePageState();
}

class _StorageExamplePageState extends State<StorageExamplePage> {
  // Storage instances (nullable in case initialization fails)
  Preferences? _preferences;
  Preferences? _scopedPreferences;
  SecureStorage? _secureStorage;
  SecureStorage? _scopedSecureStorage;

  // Event history
  final List<String> _eventHistory = [];

  // UI state
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _scopeController = TextEditingController();
  
  String _selectedStorage = 'preferences';
  Map<String, String> _currentData = {};
  int _currentSize = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeStorage();
  }

  void _initializeStorage() {
    try {
      _preferences = Preferences();
      _scopedPreferences = Preferences.withScope('user_settings');
      _secureStorage = SecureStorage();
      _scopedSecureStorage = SecureStorage.withScope('api_credentials');
      
      _isInitialized = true;
      _addToHistory('Storage instances initialized successfully');
      _refreshCurrentData();
    } catch (e) {
      _isInitialized = false;
      _addToHistory('Error initializing storage: $e');
    }
  }

  Storage? _getCurrentStorage() {
    if (!_isInitialized) return null;
    
    switch (_selectedStorage) {
      case 'preferences':
        return _preferences;
      case 'scoped_preferences':
        return _scopedPreferences;
      case 'secure_storage':
        return _secureStorage;
      case 'scoped_secure_storage':
        return _scopedSecureStorage;
      default:
        return _preferences;
    }
  }

  void _addToHistory(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _eventHistory.insert(0, '[$timestamp] $message');
      if (_eventHistory.length > 100) {
        _eventHistory.removeLast();
      }
    });
  }

  void _clearHistory() {
    setState(() {
      _eventHistory.clear();
    });
    _addToHistory('Event history cleared');
  }

  void _refreshCurrentData() {
    setState(() {
      final storage = _getCurrentStorage();
      if (storage == null) {
        _currentData = {};
        _currentSize = 0;
        return;
      }
      _currentData = storage.getAll();
      _currentSize = storage.size;
    });
  }

  void _setKeyValue() {
    final key = _keyController.text.trim();
    final value = _valueController.text;

    if (key.isEmpty) {
      _addToHistory('Error: Key cannot be empty');
      return;
    }

    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }

    final success = storage.set(key, value);

    if (success) {
      _addToHistory('Set [$_selectedStorage]: "$key" = "$value"');
      _refreshCurrentData();
      _keyController.clear();
      _valueController.clear();
    } else {
      _addToHistory('Error: Failed to set "$key"');
    }
  }

  void _getValue() {
    final key = _keyController.text.trim();

    if (key.isEmpty) {
      _addToHistory('Error: Key cannot be empty');
      return;
    }

    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }

    final value = storage.get(key, '(not found)');
    
    _addToHistory('Get [$_selectedStorage]: "$key" = "$value"');
  }

  void _removeKey() {
    final key = _keyController.text.trim();

    if (key.isEmpty) {
      _addToHistory('Error: Key cannot be empty');
      return;
    }

    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }

    final success = storage.remove(key);

    if (success) {
      _addToHistory('Remove [$_selectedStorage]: "$key" removed successfully');
      _refreshCurrentData();
      _keyController.clear();
    } else {
      _addToHistory('Error: Failed to remove "$key" (may not exist)');
    }
  }

  void _containsKey() {
    final key = _keyController.text.trim();

    if (key.isEmpty) {
      _addToHistory('Error: Key cannot be empty');
      return;
    }

    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }

    final exists = storage.contains(key);
    
    _addToHistory('Contains [$_selectedStorage]: "$key" = $exists');
  }

  void _clearStorage() {
    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }

    final success = storage.clear();

    if (success) {
      _addToHistory('Clear [$_selectedStorage]: All data cleared');
      _refreshCurrentData();
    } else {
      _addToHistory('Error: Failed to clear storage');
    }
  }

  void _listAllKeys() {
    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }

    final keys = storage.keys;
    
    _addToHistory('Keys [$_selectedStorage]: ${keys.length} keys - [${keys.join(', ')}]');
  }

  void _getSize() {
    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }

    final size = storage.size;
    
    _addToHistory('Size [$_selectedStorage]: $size items');
  }

  void _getAllData() {
    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }

    final data = storage.getAll();
    
    _addToHistory('GetAll [$_selectedStorage]: ${data.length} items');
    data.forEach((key, value) {
      _addToHistory('  "$key" = "$value"');
    });
  }

  // Test case methods
  void _testBasicOperations() {
    _addToHistory('--- Starting Basic Operations Test ---');
    
    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }
    
    // Set
    storage.set('test_key', 'test_value');
    _addToHistory('✓ Set test_key = test_value');
    
    // Get
    final value = storage.get('test_key');
    _addToHistory('✓ Get test_key = $value');
    
    // Contains
    final exists = storage.contains('test_key');
    _addToHistory('✓ Contains test_key = $exists');
    
    // Remove
    storage.remove('test_key');
    _addToHistory('✓ Removed test_key');
    
    // Contains after remove
    final stillExists = storage.contains('test_key');
    _addToHistory('✓ Contains after remove = $stillExists');
    
    _addToHistory('--- Basic Operations Test Complete ---');
    _refreshCurrentData();
  }

  void _testBulkOperations() {
    _addToHistory('--- Starting Bulk Operations Test ---');
    
    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }
    
    // Add multiple items
    for (int i = 1; i <= 10; i++) {
      storage.set('bulk_key_$i', 'value_$i');
    }
    _addToHistory('✓ Added 10 items');
    
    // List all keys
    final keys = storage.keys;
    _addToHistory('✓ Total keys: ${keys.length}');
    
    // Get all data
    final data = storage.getAll();
    _addToHistory('✓ Retrieved all data: ${data.length} items');
    
    _addToHistory('--- Bulk Operations Test Complete ---');
    _refreshCurrentData();
  }

  void _testSpecialCharacters() {
    _addToHistory('--- Starting Special Characters Test ---');
    
    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }
    
    final testCases = [
      ('emoji_key', '😀🎉🚀'),
      ('chinese_key', '你好世界'),
      ('special_chars', '@#\$%^&*()'),
      ('unicode_key', 'Héllo Wörld'),
      ('json_like', '{"name":"value","array":[1,2,3]}'),
    ];
    
    for (var (key, value) in testCases) {
      storage.set(key, value);
      final retrieved = storage.get(key);
      final match = retrieved == value ? '✓' : '✗';
      _addToHistory('$match "$key" = "$value" (retrieved: "$retrieved")');
    }
    
    _addToHistory('--- Special Characters Test Complete ---');
    _refreshCurrentData();
  }

  void _testDefaultValues() {
    _addToHistory('--- Starting Default Values Test ---');
    
    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }
    
    // Test non-existent key with default
    final value1 = storage.get('non_existent_key', 'default_value');
    _addToHistory('✓ Get non-existent with default = "$value1"');
    
    // Test non-existent key without default
    final value2 = storage.get('another_non_existent_key');
    _addToHistory('✓ Get non-existent without default = "$value2"');
    
    _addToHistory('--- Default Values Test Complete ---');
  }

  void _testOverwriteValues() {
    _addToHistory('--- Starting Overwrite Values Test ---');
    
    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }
    
    storage.set('overwrite_test', 'original_value');
    _addToHistory('✓ Set original value');
    
    final value1 = storage.get('overwrite_test');
    _addToHistory('✓ Retrieved: "$value1"');
    
    storage.set('overwrite_test', 'updated_value');
    _addToHistory('✓ Overwrote with new value');
    
    final value2 = storage.get('overwrite_test');
    _addToHistory('✓ Retrieved after overwrite: "$value2"');
    
    storage.remove('overwrite_test');
    _addToHistory('✓ Cleaned up test key');
    
    _addToHistory('--- Overwrite Values Test Complete ---');
    _refreshCurrentData();
  }

  void _testLargeData() {
    _addToHistory('--- Starting Large Data Test ---');
    
    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }
    
    // Test with increasingly larger strings
    final sizes = [100, 1000, 10000];
    
    for (var size in sizes) {
      final largeValue = 'x' * size;
      final key = 'large_data_$size';
      
      final setSuccess = storage.set(key, largeValue);
      final retrieved = storage.get(key);
      final match = retrieved.length == size;
      
      _addToHistory(
        '${match ? "✓" : "✗"} $size chars: set=$setSuccess, retrieved=${retrieved.length} chars'
      );
      
      storage.remove(key);
    }
    
    _addToHistory('--- Large Data Test Complete ---');
    _refreshCurrentData();
  }

  void _testEmptyValues() {
    _addToHistory('--- Starting Empty Values Test ---');
    
    final storage = _getCurrentStorage();
    if (storage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }
    
    // Test empty string value
    storage.set('empty_value', '');
    final retrieved = storage.get('empty_value', 'default');
    _addToHistory('✓ Empty value retrieved: "$retrieved" (length: ${retrieved.length})');
    
    // Test if key exists
    final exists = storage.contains('empty_value');
    _addToHistory('✓ Empty value key exists: $exists');
    
    storage.remove('empty_value');
    _addToHistory('✓ Cleaned up empty value test');
    
    _addToHistory('--- Empty Values Test Complete ---');
    _refreshCurrentData();
  }

  void _testScopedStorage() {
    _addToHistory('--- Starting Scoped Storage Test ---');
    
    if (!_isInitialized || _preferences == null || _scopedPreferences == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }
    
    // Test both regular and scoped preferences
    _preferences!.set('shared_key', 'regular_value');
    _scopedPreferences!.set('shared_key', 'scoped_value');
    
    final regularValue = _preferences!.get('shared_key');
    final scopedValue = _scopedPreferences!.get('shared_key');
    
    _addToHistory('✓ Regular preferences: "$regularValue"');
    _addToHistory('✓ Scoped preferences: "$scopedValue"');
    _addToHistory('✓ Values are isolated: ${regularValue != scopedValue}');
    
    _preferences!.remove('shared_key');
    _scopedPreferences!.remove('shared_key');
    
    _addToHistory('--- Scoped Storage Test Complete ---');
    _refreshCurrentData();
  }

  void _compareStorageTypes() {
    _addToHistory('--- Starting Storage Types Comparison ---');
    
    if (!_isInitialized || _preferences == null || _scopedPreferences == null ||
        _secureStorage == null || _scopedSecureStorage == null) {
      _addToHistory('Error: Storage not initialized');
      return;
    }
    
    const testKey = 'comparison_test';
    const testValue = 'test_value_123';
    
    // Test in all storage types
    _preferences!.set(testKey, testValue);
    _scopedPreferences!.set(testKey, testValue);
    _secureStorage!.set(testKey, testValue);
    _scopedSecureStorage!.set(testKey, testValue);
    
    _addToHistory('✓ Set value in all storage types');
    
    _addToHistory('Preferences size: ${_preferences!.size}');
    _addToHistory('Scoped Preferences size: ${_scopedPreferences!.size}');
    _addToHistory('SecureStorage size: ${_secureStorage!.size}');
    _addToHistory('Scoped SecureStorage size: ${_scopedSecureStorage!.size}');
    
    // Clean up
    _preferences!.remove(testKey);
    _scopedPreferences!.remove(testKey);
    _secureStorage!.remove(testKey);
    _scopedSecureStorage!.remove(testKey);
    
    _addToHistory('--- Storage Types Comparison Complete ---');
    _refreshCurrentData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Example - Comprehensive Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearHistory,
            tooltip: 'Clear Event History',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side - Test controls
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Storage Selection
                  _buildSectionCard('Storage Selection', [
                    Row(
                      children: [
                        Expanded(child: _buildInfoRow('Type', _selectedStorage)),
                        Expanded(child: _buildInfoRow('Size', '$_currentSize items')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedStorage,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'preferences',
                          child: Text('Preferences (Default)'),
                        ),
                        DropdownMenuItem(
                          value: 'scoped_preferences',
                          child: Text('Preferences (Scoped: user_settings)'),
                        ),
                        DropdownMenuItem(
                          value: 'secure_storage',
                          child: Text('SecureStorage (Default)'),
                        ),
                        DropdownMenuItem(
                          value: 'scoped_secure_storage',
                          child: Text('SecureStorage (Scoped: api_credentials)'),
                        ),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _selectedStorage = value;
                          });
                          _addToHistory('Switched to: $value');
                          _refreshCurrentData();
                        }
                      },
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Key-Value Operations
                  _buildSectionCard('Key-Value Operations', [
                    TextField(
                      controller: _keyController,
                      decoration: const InputDecoration(
                        labelText: 'Key',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _valueController,
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactButton(Icons.save, 'Set', _setKeyValue),
                        _buildCompactButton(Icons.search, 'Get', _getValue),
                        _buildCompactButton(Icons.delete, 'Remove', _removeKey),
                        _buildCompactButton(Icons.check, 'Contains', _containsKey),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Storage Operations
                  _buildSectionCard('Storage Operations', [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactButton(Icons.list, 'List Keys', _listAllKeys),
                        _buildCompactButton(Icons.info, 'Get Size', _getSize),
                        _buildCompactButton(Icons.view_list, 'Get All', _getAllData),
                        _buildCompactButton(Icons.delete_forever, 'Clear All', _clearStorage),
                        _buildCompactButton(Icons.refresh, 'Refresh View', _refreshCurrentData),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Test Cases
                  _buildSectionCard('Test Cases', [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactButton(
                          Icons.play_arrow,
                          'Basic Operations',
                          _testBasicOperations,
                        ),
                        _buildCompactButton(
                          Icons.format_list_numbered,
                          'Bulk Operations',
                          _testBulkOperations,
                        ),
                        _buildCompactButton(
                          Icons.language,
                          'Special Chars',
                          _testSpecialCharacters,
                        ),
                        _buildCompactButton(
                          Icons.settings,
                          'Default Values',
                          _testDefaultValues,
                        ),
                        _buildCompactButton(
                          Icons.edit,
                          'Overwrite',
                          _testOverwriteValues,
                        ),
                        _buildCompactButton(
                          Icons.data_usage,
                          'Large Data',
                          _testLargeData,
                        ),
                        _buildCompactButton(
                          Icons.rectangle,
                          'Empty Values',
                          _testEmptyValues,
                        ),
                        _buildCompactButton(
                          Icons.folder,
                          'Scoped Storage',
                          _testScopedStorage,
                        ),
                        _buildCompactButton(
                          Icons.compare,
                          'Compare Types',
                          _compareStorageTypes,
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Current Data View
                  _buildSectionCard('Current Data ($_currentSize items)', [
                    if (_currentData.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No data in storage',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _currentData.length,
                          itemBuilder: (context, index) {
                            final entry = _currentData.entries.elementAt(index);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                title: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  entry.value.length > 50
                                      ? '${entry.value.substring(0, 50)}...'
                                      : entry.value,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () {
                                    final storage = _getCurrentStorage();
                                    if (storage != null) {
                                      storage.remove(entry.key);
                                      _addToHistory('Removed "${entry.key}" from view');
                                      _refreshCurrentData();
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ]),
                ],
              ),
            ),
          ),

          // Right side - Event history
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(left: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Event History (${_eventHistory.length})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _eventHistory.isEmpty
                        ? const Center(
                            child: Text(
                              'No events yet\nPerform storage operations to see events',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _eventHistory.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  _eventHistory[index],
                                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton(IconData icon, String label, VoidCallback onPressed) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 36),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    _scopeController.dispose();
    
    _preferences?.dispose();
    _scopedPreferences?.dispose();
    _secureStorage?.dispose();
    _scopedSecureStorage?.dispose();
    
    super.dispose();
  }
}