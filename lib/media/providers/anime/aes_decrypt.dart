import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypter_plus/encrypter_plus.dart';

String decrypt(final String encrypted, final String passphrase) {
  final Uint8List encryptedBytesWithSalt = base64.decode(encrypted);
  final Uint8List encryptedBytes = encryptedBytesWithSalt.sublist(16, encryptedBytesWithSalt.length);
  final (key, iv) = deriveKeyAndIV(passphrase, encryptedBytesWithSalt.sublist(8, 16));
  return Encrypter(AES(key, mode: AESMode.cbc, padding: "PKCS7")).decrypt64(base64.encode(encryptedBytes), iv: iv);
}

(Key, IV) deriveKeyAndIV(final String passphrase, final Uint8List salt) {
  final password = Uint8List.fromList(passphrase.codeUnits);
  final Uint8List concatenatedHashes = Uint8List(48);
  Uint8List currentHash = Uint8List(0);
  for (int i = 0; i < 48; i += currentHash.length) {
    currentHash = Uint8List.fromList(md5.convert(currentHash + password + salt).bytes);
    concatenatedHashes.setRange(i, i + currentHash.length, currentHash);
  }
  return (Key(concatenatedHashes.sublist(0, 32)), IV(concatenatedHashes.sublist(32, 48)));
}
