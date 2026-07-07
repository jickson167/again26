import 'package:flutter/material.dart';

import '../utils/admin_layout.dart';

class AdminRowAction {
  const AdminRowAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;
}

/// 목록 행 액션 — 모바일은 ⋮ 메뉴, 넓은 화면은 아이콘 버튼.
class AdminRowActions extends StatelessWidget {
  const AdminRowActions({super.key, required this.actions});

  final List<AdminRowAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    if (AdminLayout.isCompact(context)) {
      return PopupMenuButton<int>(
        tooltip: '메뉴',
        itemBuilder: (context) {
          return [
            for (var i = 0; i < actions.length; i++)
              PopupMenuItem<int>(
                value: i,
                child: ListTile(
                  leading: Icon(
                    actions[i].icon,
                    color: actions[i].isDestructive ? Colors.red : null,
                  ),
                  title: Text(
                    actions[i].label,
                    style: TextStyle(
                      color: actions[i].isDestructive ? Colors.red : null,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
          ];
        },
        onSelected: (index) => actions[index].onPressed(),
        icon: const Icon(Icons.more_vert),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final action in actions)
          IconButton(
            tooltip: action.label,
            icon: Icon(action.icon),
            color: action.isDestructive ? Colors.red : null,
            onPressed: action.onPressed,
          ),
      ],
    );
  }
}
