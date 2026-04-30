import 'dart:math';

class InviteCodeGenerator {
  static String generate() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I, O, 1, 0
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }
}