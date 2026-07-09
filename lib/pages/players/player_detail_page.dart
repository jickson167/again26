import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/key_position.dart';
import '../../models/player.dart';
import '../../models/player_style.dart';
import '../../services/app_services.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/player_detail_card.dart';

class PlayerDetailPage extends StatefulWidget {
  const PlayerDetailPage({
    super.key,
    required this.services,
    required this.playerId,
    this.editableComment = false,
  });

  final AppServices services;
  final String playerId;
  final bool editableComment;

  @override
  State<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage> {
  Player? _player;
  Map<String, KeyPosition> _keyPositions = {};
  List<String> _styleLabels = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.services.playerService.fetchById(widget.playerId),
        widget.services.keyPositionService.fetchAll(),
        widget.services.playerStyleService.fetchByIdMap(),
      ]);
      if (!mounted) {
        return;
      }

      final player = results[0] as Player?;
      final stylesById = results[2] as Map<String, PlayerStyle>;
      setState(() {
        _player = player;
        _keyPositions = {
          for (final kp in results[1] as List<KeyPosition>) kp.id: kp,
        };
        _styleLabels = player == null
            ? const []
            : resolveStyleLabels(
                styleIds: player.styleIds,
                stylesById: stylesById,
              );
        _loading = false;
        if (player == null) {
          _error = '선수를 찾을 수 없습니다.';
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('선수 상세'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/players'),
        ),
        actions: [
          if (_player != null)
            IconButton(
              tooltip: '수정',
              onPressed: () => context.go('/admin/${_player!.id}/edit'),
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadPlayer)
              : _player == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: PlayerDetailCard(
                            player: _player!,
                            keyPositionsById: _keyPositions,
                            styleLabels: _styleLabels,
                            editableComment: widget.editableComment,
                            onSaveComment: widget.editableComment
                                ? (comment) async {
                                    await widget.services.playerService.patch(
                                      _player!.id,
                                      {'comment': comment},
                                    );
                                    await _loadPlayer();
                                  }
                                : null,
                          ),
                        ),
                      ),
                    ),
    );
  }
}
