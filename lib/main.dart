import 'package:flutter/material.dart';

void main() => runApp(const ShoppingListApp());

class ShoppingListApp extends StatelessWidget {
  const ShoppingListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const ShoppingListPage(),
    );
  }
}

// ---------------------------------------------------------------- model
class Item {
  Item(
    this.name, {
    this.note = '',
    this.category = 'Food',
    this.quantity = 1,
    this.bought = false,
  });

  String name; // not final: the details screen can rename an item
  String note;
  String category;
  int quantity;
  bool bought;
}

const List<String> categories = ['Food', 'Drinks', 'Home'];

// ------------------------------------------------------------ list page
class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Item> _items = [];
  String? _error;
  String _filter = 'All';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Part 5: a second list built from _items; _items itself is never filtered.
  List<Item> get _shown {
    final toBuy = _items.where((item) => !item.bought).toList();
    final bought = _items.where((item) => item.bought).toList();
    if (_filter == 'To buy') return toBuy;
    if (_filter == 'Bought') return bought;
    return [...toBuy, ...bought]; // All: bought items at the bottom
  }

  void _say(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), action: action),
    );
  }

  // Parts 1 + 3: refuse empty, merge duplicates, otherwise add.
  void _addItem() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Type an item first');
      return;
    }
    final matches = _items.where(
      (item) => item.name.trim().toLowerCase() == text.toLowerCase(),
    );
    if (matches.isNotEmpty) {
      final existing = matches.first;
      setState(() {
        existing.quantity++;
        _controller.clear();
        _error = null;
      });
      _say('${existing.name} is already on the list: now ×${existing.quantity}');
      return;
    }
    setState(() {
      _items.add(Item(text));
      _controller.clear();
      _error = null;
    });
  }

  void _toggle(Item item) {
    setState(() => item.bought = !item.bought);
  }

  // Part 2: quantity never goes below 1 (check before changing).
  void _increase(Item item) {
    setState(() => item.quantity++);
  }

  void _decrease(Item item) {
    if (item.quantity > 1) {
      setState(() => item.quantity--);
    }
  }

  // Parts 4 + 5: delete the item itself (not a screen index) and allow undo.
  void _delete(Item item) {
    final position = _items.indexOf(item); // find where it was BEFORE removing
    setState(() => _items.remove(item));
    _say(
      '${item.name} removed',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() {
            final spot = position > _items.length ? _items.length : position;
            _items.insert(spot, item);
          });
        },
      ),
    );
  }

  // Part 6: open the details screen, redraw when we come back.
  void _openDetails(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailsScreen(item: item)),
    ).then((_) {
      setState(() {});
    });
  }

  Widget _buildBody() {
    if (_items.isEmpty) {
      return const Center(child: Text('Your list is empty'));
    }
    final shown = _shown;
    if (shown.isEmpty) {
      return const Center(child: Text('Nothing here'));
    }
    return ListView.builder(
      itemCount: shown.length,
      itemBuilder: (context, index) {
        final item = shown[index];
        final subtitle =
            item.note.isEmpty ? item.category : '${item.category} · ${item.note}';
        return Card(
          child: ListTile(
            leading: Checkbox(
              value: item.bought,
              onChanged: (_) => _toggle(item),
            ),
            title: Text(
              item.name,
              style: TextStyle(
                decoration: item.bought
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: item.bought ? Colors.grey : null,
              ),
            ),
            subtitle: Text(subtitle),
            onTap: () => _toggle(item),
            onLongPress: () => _openDetails(item),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  tooltip: 'Less',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _decrease(item),
                ),
                Text('${item.quantity}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'More',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _increase(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _delete(item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Add an item',
                      border: const OutlineInputBorder(),
                      errorText: _error,
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _addItem,
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final name in const ['All', 'To buy', 'Bought'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(name),
                      selected: _filter == name,
                      onSelected: (_) {
                        setState(() {
                          _filter = name;
                        });
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------- details screen
class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.item});

  final Item item;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  late String category;
  String? nameError;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.item.name;
    noteController.text = widget.item.note;
    category = widget.item.category;
  }

  @override
  void dispose() {
    nameController.dispose();
    noteController.dispose();
    super.dispose();
  }

  // Changes are written to the item ONLY here, so the back arrow changes nothing.
  void _save() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      setState(() => nameError = 'Name cannot be empty');
      return;
    }
    widget.item.name = name;
    widget.item.note = noteController.text.trim();
    widget.item.category = category;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: const OutlineInputBorder(),
                errorText: nameError,
              ),
              onChanged: (_) {
                if (nameError != null) setState(() => nameError = null);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final name in categories)
                  ChoiceChip(
                    label: Text(name),
                    selected: category == name,
                    onSelected: (_) {
                      setState(() {
                        category = name;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
