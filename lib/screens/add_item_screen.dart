import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/item_listing.dart';
import '../services/item_service.dart';
import '../services/storage_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  bool _isFree = true;
  String _category = 'Textbooks';
  XFile? _image;
  bool _busy = false;

  static const _categories = [
    'Textbooks',
    'Notes & summaries',
    'Lab gear & scrubs',
    'Electronics',
    'Other',
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file != null) setState(() => _image = file);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a photo of the item.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final items = context.read<ItemService>();
      final storage = context.read<StorageService>();
      final doc = items.newItemDoc();
      final id = doc.id;
      final url = await storage.uploadItemImage(_image!, id);

      double? price;
      if (!_isFree) {
        price = double.tryParse(_price.text.trim());
      }

      final listing = ItemListing(
        id: id,
        title: _title.text.trim(),
        description: _description.text.trim(),
        imageUrl: url,
        ownerId: user.uid,
        ownerName: user.displayName ?? 'Student',
        isFree: _isFree,
        price: _isFree ? null : price,
        category: _category,
        createdAt: DateTime.now(),
      );

      await items.setItem(id, listing);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New listing')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _busy ? null : _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add a photo',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_image!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _busy ? null : _pickImage,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Choose different photo'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Calculus textbook (9th ed.)',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('This item is free'),
              value: _isFree,
              onChanged: _busy
                  ? null
                  : (v) => setState(() {
                        _isFree = v;
                      }),
            ),
            if (!_isFree)
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: '0.00',
                ),
                validator: (v) {
                  if (_isFree) return null;
                  if (v == null || double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publish listing'),
            ),
          ],
        ),
      ),
    );
  }
}
