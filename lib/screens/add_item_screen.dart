import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/item_listing.dart';
import '../services/item_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, this.initial});

  final ItemListing? initial;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  String _itemType = ItemListing.typeFree;
  String _category = 'Textbooks';
  XFile? _image;
  Uint8List? _existingImageBytes;
  String? _existingImageUrl;
  bool _busy = false;

  static const _categories = [
    'Textbooks',
    'Notes & summaries',
    'Lab gear & scrubs',
    'Electronics',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;
    _title.text = initial.title;
    _description.text = initial.description;
    _price.text = initial.price?.toString() ?? '';
    _itemType = initial.itemType;
    _category = initial.category?.isNotEmpty == true
        ? initial.category!
        : _category;
    _existingImageBytes = initial.imageBytes;
    _existingImageUrl = initial.imageUrl.isEmpty ? null : initial.imageUrl;
  }

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
    final hasExistingImageData =
        _existingImageBytes != null ||
        (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);
    if (_image == null && !hasExistingImageData) {
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
      final editing = widget.initial != null;
      final id = editing ? widget.initial!.id : items.newItemDoc().id;
      final imageBytes = _image != null
          ? await _image!.readAsBytes()
          : _existingImageBytes;
      if (imageBytes != null && imageBytes.lengthInBytes > 900000) {
        throw Exception(
          'Image is too large for Firestore. Please choose a smaller image.',
        );
      }

      double? price;
      if (_itemType == ItemListing.typeSale) {
        price = double.tryParse(_price.text.trim());
      }

      final listing = ItemListing(
        id: id,
        title: _title.text.trim(),
        description: _description.text.trim(),
        imageUrl: _existingImageUrl ?? '',
        imageBytes: imageBytes,
        ownerId: user.uid,
        ownerName: user.displayName ?? 'Student',
        itemType: _itemType,
        status: widget.initial?.status ?? ItemListing.statusAvailable,
        price: _itemType == ItemListing.typeSale ? price : null,
        category: _category,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
      );

      if (editing) {
        await items.updateItem(listing);
      } else {
        await items.setItem(id, listing);
      }
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
    final isSale = _itemType == ItemListing.typeSale;
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit listing' : 'New listing')),
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
                            if (_existingImageBytes != null)
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _existingImageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              )
                            else if (_existingImageUrl != null &&
                                _existingImageUrl!.isNotEmpty)
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _existingImageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              )
                            else ...[
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
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _itemType,
              decoration: const InputDecoration(labelText: 'Listing type'),
              items: const [
                DropdownMenuItem(
                  value: ItemListing.typeFree,
                  child: Text('Free'),
                ),
                DropdownMenuItem(
                  value: ItemListing.typeExchange,
                  child: Text('Exchange'),
                ),
                DropdownMenuItem(
                  value: ItemListing.typeSale,
                  child: Text('For sale'),
                ),
              ],
              onChanged: _busy
                  ? null
                  : (v) => setState(() {
                        _itemType = v ?? ItemListing.typeFree;
                        if (_itemType != ItemListing.typeSale) {
                          _price.clear();
                        }
                      }),
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
            if (isSale)
              TextFormField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: '0.00',
                ),
                validator: (v) {
                  if (!isSale) return null;
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
                  : Text(isEdit ? 'Save changes' : 'Publish listing'),
            ),
          ],
        ),
      ),
    );
  }
}
