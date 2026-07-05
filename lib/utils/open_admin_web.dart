import 'dart:html' as html;

void openAdminPanel() {
  html.window.location.href = Uri.base.resolve('admin/').toString();
}

void openAdminPlayerEdit(String playerId) {
  html.window.location.href =
      Uri.base.resolve('admin/players/$playerId/edit').toString();
}
