import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../settings/presentation/provider/settings_provider.dart';
import '../../data/datasource/mrp_ocr_service.dart';
import '../../data/datasource/product_cache_local_datasource.dart';
import '../../data/datasource/product_lookup_service.dart';
import '../../domain/entities/shopping_item.dart';
import '../provider/shopping_list_provider.dart';
import '../ui/scanner_screen.dart';

class AddItemBottomSheet extends ConsumerStatefulWidget {
  final ShoppingItem? existingItem;

  const AddItemBottomSheet({super.key, this.existingItem});

  @override
  ConsumerState<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends ConsumerState<AddItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _lookupService = ProductLookupService();
  final _productCache = ProductCacheLocalDataSource();
  final _mrpOcr = MrpOcrService();
  final _imagePicker = ImagePicker();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _priceCtrl;
  bool _isScanning = false;
  bool _isOcrScanning = false;

  /// Barcode scanned in this session, if any. Used to write the
  /// name + price back to the local cache on submit so next scan
  /// auto-fills both fields.
  String? _lastScannedBarcode;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _quantityCtrl = TextEditingController(
      text: item?.quantity.toInt().toString() ?? '1',
    );
    _priceCtrl = TextEditingController(
      text: item?.price.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleScan() async {
    // 1. Open the scanner.
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
        fullscreenDialog: true,
      ),
    );
    debugPrint('[Scan] scanned code="$code"');
    if (!mounted || code == null || code.trim().isEmpty) return;
    _lastScannedBarcode = code.trim();

    setState(() => _isScanning = true);

    // 2. Check our local cache first — that's the user's own prior
    //    submission for this barcode, and it includes the price.
    final cached = await _productCache.getByBarcode(code);
    if (!mounted) return;

    if (cached != null) {
      setState(() => _isScanning = false);
      _nameCtrl.text = cached.name;
      _priceCtrl.text = cached.price.toStringAsFixed(2);
      final settings = ref.read(settingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${cached.name} — last price '
            '${settings.currencySymbol}${cached.price.toStringAsFixed(2)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 3. Cache miss — hit Open Food Facts for at least the name.
    final info = await _lookupService.lookupByBarcode(code);
    if (!mounted) return;
    setState(() => _isScanning = false);

    if (info != null) {
      debugPrint(
        '[Scan] match -> name=${info.name}, brand=${info.brand}, '
        'quantity=${info.quantity}, displayName="${info.displayName}"',
      );
      _nameCtrl.text = info.displayName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found: ${info.displayName} — enter a price'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      debugPrint('[Scan] no match, falling back to raw barcode');
      _nameCtrl.text = code;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Product not in the database — barcode added, edit the name.",
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleMrpScan() async {
    // 1. Open the phone's native camera.
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      // Imagepicker does not support a true reticle; compress to keep
      // OCR fast on older phones while still preserving enough detail.
      imageQuality: 85,
    );
    if (!mounted || photo == null) return;
    debugPrint('[MrpScan] captured -> ${photo.path}');

    // 2. Run text recognition + regex extraction.
    setState(() => _isOcrScanning = true);
    final price = await _mrpOcr.extractMrpFromImage(photo.path);
    if (!mounted) return;
    setState(() => _isOcrScanning = false);

    // 3. Fill the price field, or tell the user nothing was found.
    if (price != null) {
      _priceCtrl.text = price.toStringAsFixed(2);
      final settings = ref.read(settingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Detected ${settings.currencySymbol}${price.toStringAsFixed(2)} '
            '— edit if wrong',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't read a price — try again with the MRP box centered and well-lit.",
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final quantity = double.parse(_quantityCtrl.text);
    final price = double.parse(_priceCtrl.text);

    final notifier = ref.read(shoppingListProvider.notifier);

    if (_isEditing) {
      notifier.updateItem(
        id: widget.existingItem!.id,
        name: name,
        quantity: quantity,
        price: price,
      );
    } else {
      notifier.addItem(
        name: name,
        quantity: quantity,
        price: price,
      );
    }

    // If this submission came from a scan, remember what the user saved
    // so the next scan can auto-fill name + price. Fire-and-forget.
    final barcode = _lastScannedBarcode;
    if (barcode != null && barcode.isNotEmpty) {
      _productCache.upsert(barcode: barcode, name: name, price: price);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final settings = ref.watch(settingsProvider);
    final currencySymbol = settings.currencySymbol;
    final currencyIcon = settings.currencyIcon;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit Item' : 'Add New Item',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Material(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _isScanning ? null : _handleScan,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _isScanning
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(20),

            _buildLabel('Item Name'),
            const Gap(6),
            TextFormField(
              controller: _nameCtrl,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.dmSans(color: AppColors.textPrimary),
              decoration: _inputDecoration(
                'e.g. Organic Milk',
                Icons.label_outline,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const Gap(16),

            _buildLabel('Number of Items'),
            const Gap(6),
            TextFormField(
              controller: _quantityCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.dmSans(color: AppColors.textPrimary),
              decoration: _inputDecoration(
                '1',
                Icons.numbers_rounded,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final n = int.tryParse(v);
                if (n == null) return 'Enter a whole number';
                if (n <= 0) return 'Must be greater than 0';
                return null;
              },
            ),
            const Gap(16),

            _buildLabel('Price per Item ($currencySymbol)'),
            const Gap(6),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.dmSans(color: AppColors.textPrimary),
              decoration: _inputDecoration(
                '0.00',
                currencyIcon,
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: _isOcrScanning ? null : _handleMrpScan,
                  tooltip: 'Scan MRP from package',
                  icon: _isOcrScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.photo_camera_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Price is required';
                if (double.tryParse(v) == null) return 'Invalid number';
                if (double.parse(v) < 0) return 'Must be ≥ 0';
                return null;
              },
            ),
            const Gap(24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isEditing ? 'Save Changes' : 'Add to List',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.textHint, size: 18)
          : null,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
