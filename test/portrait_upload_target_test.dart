import 'package:flutter_test/flutter_test.dart';

import 'package:again26/utils/portrait_upload_target.dart';

void main() {
  group('PortraitUploadTarget', () {
    test('maps any uploaded filename to the entity id based target path', () {
      final target = PortraitUploadTarget.forEntity(
        entityId: '0002',
        sourceFileName: 'some-random-name.jpg',
        directory: 'player_images',
      );

      expect(target.relativePath, 'player_images/0002.jpg');
      expect(target.fileName, '0002.jpg');
    });

    test('uses a png fallback when the extension is missing', () {
      final target = PortraitUploadTarget.forEntity(
        entityId: 'ch_0001',
        sourceFileName: 'avatar',
        directory: 'coach_images',
      );

      expect(target.relativePath, 'coach_images/ch_0001.png');
      expect(target.fileName, 'ch_0001.png');
    });
  });
}
