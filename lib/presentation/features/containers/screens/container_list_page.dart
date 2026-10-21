import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../../core/localization/l10n_x.dart';
import '../../../../core/router/sheet_dismiss_refresh_mixin.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../common/components/app_empty_state.dart';
import '../../../common/components/app_header_search_field.dart';
import '../../../common/components/frosted_scaffold.dart';
import '../../../common/components/frosted_filter_bar.dart';
import '../../../common/components/frosted_overlay_menu.dart';
import '../../../common/components/skeleton_item.dart';
import '../../server_detail/providers/active_server_provider.dart';
import '../providers/container_list_provider.dart';
import '../models/container_list_state.dart';
import '../widgets/container_card.dart';
import '../widgets/container_action_sheet.dart';
import '../../../../domain/entities/server.dart';
import '../../../../data/repositories_impl/server_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/app_toast.dart';

class ContainerListPage extends StatelessWidget {
  const ContainerListPage({super.key, required this.serverId});

  final int serverId;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [activeServerIdProvider.overrideWithValue(serverId)],
      child: _ContainerListContent(serverId: serverId),
    );
  }
}

class _ContainerListContent extends ConsumerStatefulWidget {
  const _ContainerListContent({required this.serverId});

  final int serverId;

  @override
  ConsumerState<_ContainerListContent> createState() =>
      _ContainerListPageState();
}

class _ContainerListPageState extends ConsumerState<_ContainerListContent>
    with SheetDismissRefreshMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _overlaps = false;
  Server? _server;
  Map<String, String> _customWebUrls = {};

  @override
  void onAllSheetsClosed() {
    ref.read(containerListControllerProvider.notifier).refresh();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadServer();
  }

  Future<void> _loadServer() async {
    try {
      final repo = ref.read(serverRepositoryProvider);
      final s = await repo.find(widget.serverId);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('container_web_urls') ?? '{}';
      final map = (jsonDecode(raw) as Map).cast<String, String>();
      if (mounted) {
        setState(() {
          _server = s;
          _customWebUrls = map;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveCustomWebUrl(String containerId, String? url) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('container_web_urls') ?? '{}';
    final map = (jsonDecode(raw) as Map).cast<String, String>();
    if (url == null || url.isEmpty) {
      map.remove(containerId);
    } else {
      map[containerId] = url;
    }
    await prefs.setString('container_web_urls', jsonEncode(map));
    if (mounted) setState(() => _customWebUrls = map);
    showAppToast(url == null ? '已恢复自动地址' : 'Web 地址已更新');
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(containerListControllerProvider.notifier).loadMore();
    }

    final overlaps =
        _scrollController.hasClients && _scrollController.offset > 12;
    if (overlaps != _overlaps) {
      setState(() => _overlaps = overlaps);
    }
  }

  Widget _buildSkeletonItem(BuildContext context, int index) {
    return Container(
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
              const SkeletonItem(width: 42, height: 42, borderRadius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonItem(
                      width: 120 + (index % 3) * 40.0,
                      height: 16,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 6),
                    SkeletonItem(
                      width: 80 + (index % 2) * 30.0,
                      height: 12,
                      borderRadius: 3,
                    ),
                  ],
                ),
              ),
              const SkeletonItem(width: 20, height: 20, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SkeletonItem(
                width: 50 + (index % 2) * 10.0,
                height: 18,
                borderRadius: 4,
              ),
              const SizedBox(width: 8),
              SkeletonItem(
                width: 60 + (index % 3) * 20.0,
                height: 12,
                borderRadius: 3,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: SkeletonItem(
                  width: double.infinity,
                  height: 36,
                  borderRadius: 8,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SkeletonItem(
                  width: double.infinity,
                  height: 36,
                  borderRadius: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonItem(
            width: double.infinity,
            height: 1,
            borderRadius: 0,
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: SkeletonItem(
                  width: double.infinity,
                  height: 30,
                  borderRadius: 6,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SkeletonItem(
                  width: double.infinity,
                  height: 30,
                  borderRadius: 6,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SkeletonItem(
                  width: double.infinity,
                  height: 30,
                  borderRadius: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(containerListControllerProvider);
    final notifier = ref.read(containerListControllerProvider.notifier);

    return FrostedScaffold(
      title: _isSearching ? '' : context.l10n.containers_containerList,
      showBackButton: !_isSearching,
      trailingBuilder: (isDark, isOverlapping) {
        if (_isSearching) {
          return AppHeaderSearchField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            placeholder: context.l10n.containers_searchContainers,
            onChanged: notifier.search,
            onClear: () => notifier.search(''),
            onCancel: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
              notifier.search('');
            },
          );
        }

        return FrostedOverlayMenuButton(
          label: context.l10n.containers_more,
          isDark: isDark,
          isOverlapping: isOverlapping,
          items: [
            FrostedMenuItem(
              text: context.l10n.containers_searchContainers,
              icon: TablerIcons.search,
              action: () {
                setState(() => _isSearching = true);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _searchFocusNode.requestFocus();
                });
              },
            ),
            FrostedMenuItem(
              text: context.l10n.containers_pruneContainers,
              icon: TablerIcons.trash,
              action: () => notifier.pruneContainers(context),
            ),
            FrostedMenuItem(
              text: context.l10n.containers_sortByCpu,
              icon: TablerIcons.cpu,
              action: () => notifier.sortBy(ContainerSortType.cpu),
            ),
            FrostedMenuItem(
              text: context.l10n.containers_sortByMemory,
              icon: TablerIcons.database,
              action: () => notifier.sortBy(ContainerSortType.memory),
            ),
            if (asyncState.valueOrNull?.sortType != ContainerSortType.none)
              FrostedMenuItem(
                text: context.l10n.containers_restoreDefaultSort,
                icon: TablerIcons.sort_ascending,
                action: () => notifier.sortBy(ContainerSortType.none),
              ),
          ],
        );
      },
      body: asyncState.when(
        data: (state) {
          final filters = notifier.buildFilters(context);
          final topPadding = FrostedScaffold.contentTopPadding(context);

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topPadding + 58)),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final containers = state.sortedContainers;
                          if (index == containers.length) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            );
                          }
                          final container = containers[index];
                          return ContainerCard(
                            container: container,
                            server: _server,
                            customWebUrl: _customWebUrls[container.containerID],
                            onEditWebUrl: _saveCustomWebUrl,
                            stats: state.stats[container.containerID],
                            onTap: () => showContainerActionSheet(
                              context,
                              ref,
                              container,
                            ),
                            onFavoriteTap: () =>
                                notifier.togglePin(context, container),
                            onStart: () => notifier.operateContainer(
                              context: context,
                              container: container,
                              operation:
                                  container.state.toLowerCase() == 'paused'
                                  ? 'unpause'
                                  : 'start',
                              title: container.state.toLowerCase() == 'paused'
                                  ? context.l10n.containers_restoreContainer
                                  : context.l10n.containers_startContainer,
                            ),
                            onStop: () => notifier.operateContainer(
                              context: context,
                              container: container,
                              operation: 'stop',
                              title: context.l10n.containers_stopContainer,
                            ),
                            onRestart: () => notifier.operateContainer(
                              context: context,
                              container: container,
                              operation: 'restart',
                              title: context.l10n.containers_restartContainer,
                            ),
                          );
                        },
                        childCount:
                            state.sortedContainers.length +
                            (state.isLoadingMore ? 1 : 0),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                child: FrostedFilterBar(
                  items: filters,
                  selectedValue: state.filterState,
                  overlaps: _overlaps,
                  onSelected: notifier.filter,
                ),
              ),
            ],
          );
        },
        loading: () {
          final topPadding = FrostedScaffold.contentTopPadding(context);
          return Stack(
            children: [
              CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topPadding + 58)),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 100),
                    sliver: SliverList.builder(
                      itemCount: 6,
                      itemBuilder: _buildSkeletonItem,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                child: FrostedFilterBar(
                  items: const [],
                  selectedValue: 'all',
                  overlaps: false,
                  onSelected: (_) {},
                ),
              ),
            ],
          );
        },
        error: (err, _) => AppErrorState(
          title: context.l10n.containers_loadContainersFailed,
          error: err,
          onRetry: () =>
              ref.read(containerListControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }
}
