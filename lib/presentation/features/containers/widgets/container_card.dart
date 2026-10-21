import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/localization/l10n_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../data/dto/container/container_search_dto.dart';
import '../../../../domain/entities/server.dart';
import 'container_web_url.dart';
import '../../../common/app_toast.dart';
import '../../../common/components/in_app_browser_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/dto/container/container_resource_stats_dto.dart';
import '../../../common/components/resource_metric_tile.dart';
import '../../../common/components/status_tag.dart';
import '../../../common/components/thin_divider.dart';

class ContainerCard extends StatelessWidget {
  const ContainerCard({
    super.key,
    required this.container,
    this.server,
    this.customWebUrl,
    this.onEditWebUrl,
    this.stats,
    this.onTap,
    this.onFavoriteTap,
    this.onStart,
    this.onStop,
    this.onRestart,
  });

  final ContainerItemDto container;
  final Server? server;

  /// 用户手动覆盖的 Web 地址（长按菜单里编辑）。空 = 用自动解析的。
  final String? customWebUrl;

  /// 编辑地址回调（containerId, newUrl|null）。null = 清除自定义恢复自动。
  final void Function(String containerId, String? url)? onEditWebUrl;
  final ContainerResourceStatsDto? stats;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final isRunning = container.state.toLowerCase() == 'running';
    final isPaused = container.state.toLowerCase() == 'paused';
    final statusColor = isRunning
        ? CupertinoColors.systemGreen.resolveFrom(context)
        : isPaused
        ? CupertinoColors.systemYellow.resolveFrom(context)
        : CupertinoColors.systemRed.resolveFrom(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground(context).withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.separator(context).withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    container.isFromApp
                        ? TablerIcons.brand_appstore
                        : TablerIcons.box,
                    size: 24,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        container.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.label(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        container.imageName,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryLabel(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: onFavoriteTap,
                  child: Icon(
                    container.isPinned
                        ? TablerIcons.star_filled
                        : TablerIcons.star,
                    size: 20,
                    color: container.isPinned
                        ? CupertinoColors.systemYellow
                        : AppColors.tertiaryLabel(context),
                  ),
                ),
              ],
            ),
            if (container.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                container.description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryLabel(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                StatusTag(
                  label: container.state.toUpperCase(),
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    container.runTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryLabel(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            ..._buildWebUrlRow(context),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ResourceMetricTile(
                    label: 'CPU',
                    value: '${stats?.cpuPercent.toStringAsFixed(2) ?? '0.00'}%',
                    icon: TablerIcons.cpu,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ResourceMetricTile(
                    label: context.l10n.containers_memory,
                    value: formatBytes(stats?.memoryUsage ?? 0),
                    icon: TablerIcons.device_sd_card,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const ThinDivider(indent: 0),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CardAction(
                    icon: TablerIcons.player_play,
                    label: isPaused
                        ? context.l10n.containers_restore
                        : context.l10n.containers_start,
                    color: CupertinoColors.systemGreen,
                    enabled: !isRunning || isPaused,
                    onTap: onStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CardAction(
                    icon: TablerIcons.player_stop,
                    label: context.l10n.containers_stop,
                    color: CupertinoColors.systemRed,
                    enabled: isRunning && !isPaused,
                    onTap: onStop,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CardAction(
                    icon: TablerIcons.refresh,
                    label: context.l10n.containers_restart,
                    color: CupertinoColors.systemBlue,
                    enabled: isRunning,
                    onTap: onRestart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 容器 Web 访问地址行：解析 ports 生成 http://host:port，点击内嵌浏览器打开。
  List<Widget> _buildWebUrlRow(BuildContext context) {
    if (container.state.toLowerCase() != 'running') return const [];
    final srv = server;
    if (srv == null) return const [];
    // 用户自定义地址优先
    final custom = customWebUrl?.trim();
    if (custom != null && custom.isNotEmpty) {
      final u = Uri.tryParse(custom);
      if (u != null && u.hasScheme) {
        return _webRow(context, u, 0);
      }
    }
    final urls = extractWebUrls(container.ports, srv);
    if (urls.isEmpty) return const [];
    final first = urls.first;
    final extra = urls.length - 1;
    return _webRow(context, first, extra);
  }

  /// 长按菜单：编辑地址（持久化由 onEditWebUrl 处理）/ 系统浏览器 / 复制。
  Future<void> _showWebUrlMenu(BuildContext context, Uri first) async {
    final actions = <(
      String,
      Future<void> Function(),
    )>[
      (
        '编辑地址',
        () => _editWebUrl(context, first),
      ),
      (
        '系统浏览器打开',
        () async {
          final ok = await canLaunchUrl(first);
          if (ok) await launchUrl(first, mode: LaunchMode.externalApplication);
        },
      ),
      (
        '复制地址',
        () async {
          await Clipboard.setData(ClipboardData(text: first.toString()));
          showAppToast('已复制');
        },
      ),
    ];
    if (!context.mounted) return;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(first.toString()),
        actions: [
          for (final (label, fn) in actions)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetContext);
                fn();
              },
              child: Text(label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('取消'),
        ),
      ),
    );
  }

  /// 弹出编辑框；确定后回调 onEditWebUrl 持久化（列表页负责存取）。
  Future<void> _editWebUrl(BuildContext context, Uri current) async {
    final controller = TextEditingController(text: customWebUrl ?? current.toString());
    final newUrl = await showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('编辑 Web 地址'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'http://192.168.1.10:5244',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final v = controller.text.trim();
              // 清空 = 恢复自动解析
              if (v.isEmpty) {
                Navigator.pop(dialogContext, '');
                return;
              }
              final u = Uri.tryParse(v);
              if (u == null || !u.hasScheme) {
                Navigator.pop(dialogContext);
                return;
              }
              Navigator.pop(dialogContext, v);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (newUrl == null) return;
    onEditWebUrl?.call(container.containerID, newUrl.isEmpty ? null : newUrl);
  }

  List<Widget> _webRow(BuildContext context, Uri first, int extra) {
    return [
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () {
          Navigator.of(context, rootNavigator: true).push(
            CupertinoPageRoute(
              builder: (_) => InAppBrowserPage(
                title: container.name,
                initialUrl: first,
              ),
            ),
          );
        },
        onLongPress: () => _showWebUrlMenu(context, first),
        child: Row(
          children: [
            Icon(TablerIcons.world,
                size: 14, color: CupertinoColors.systemBlue.resolveFrom(context)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                extra > 0 ? '$first  (+$extra)' : '$first',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemBlue.resolveFrom(context),
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              TablerIcons.external_link,
              size: 14,
              color: AppColors.tertiaryLabel(context),
            ),
          ],
        ),
      ),
    ];
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.color,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.1), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
