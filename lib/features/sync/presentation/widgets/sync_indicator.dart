import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../data/sync_service.dart';
import '../../domain/sync_status.dart';
import '../../../../../core/themes/app_colors.dart';
import '../provider/sync_provider.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncAsync = ref.watch(syncProvider);

    return syncAsync.when(
      loading: () => _buildBadge(
        label: 'Connecting...',
        color: AppColors.textSecondary,
        icon: Icons.cloud_outlined,
        animate: false,
      ),
      error: (_, __) => _buildBadge(
        label: SyncStatus.error.label,
        color: AppColors.error,
        icon: Icons.cloud_off_rounded,
        animate: false,
      ),
      data: (status) => _buildBadge(
        label: status.label,
        color: _colorFor(status),
        icon: _iconFor(status),
        animate: status == SyncStatus.syncing,
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required IconData icon,
    required bool animate,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            animate
                ? _SpinningIcon(icon: icon, color: color)
                : Icon(icon, size: 13, color: color),
            const Gap(5),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return AppColors.info;
      case SyncStatus.synced:
        return AppColors.success;
      case SyncStatus.error:
        return AppColors.error;
    }
  }

  IconData _iconFor(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return Icons.sync_rounded;
      case SyncStatus.synced:
        return Icons.cloud_done_rounded;
      case SyncStatus.error:
        return Icons.cloud_off_rounded;
    }
  }
}

class _SpinningIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _SpinningIcon({required this.icon, required this.color});

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Icon(widget.icon, size: 13, color: widget.color),
    );
  }
}
