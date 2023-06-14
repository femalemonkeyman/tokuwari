import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

String decrypt(final String encrypted, final String passphrase) {
  try {
    Uint8List encryptedBytesWithSalt = base64.decode(encrypted);
    Uint8List encryptedBytes =
        encryptedBytesWithSalt.sublist(16, encryptedBytesWithSalt.length);
    final salt = encryptedBytesWithSalt.sublist(8, 16);
    final List<Uint8List> keyndIV = deriveKeyAndIV(passphrase, salt);
    final key = Key(keyndIV[0]);
    final iv = IV(keyndIV[1]);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: "PKCS7"));
    final decrypted =
        encrypter.decrypt64(base64.encode(encryptedBytes), iv: iv);
    return decrypted;
  } catch (error) {
    rethrow;
  }
}

List<Uint8List> deriveKeyAndIV(final String passphrase, final Uint8List salt) {
  Uint8List password = Uint8List.fromList(passphrase.codeUnits);
  Uint8List concatenatedHashes = Uint8List(0);
  Uint8List currentHash = Uint8List(0);
  Uint8List preHash = Uint8List(0);

  while (concatenatedHashes.length < 48) {
    if (currentHash.isNotEmpty) {
      preHash = Uint8List.fromList(currentHash + password + salt);
    } else {
      preHash = Uint8List.fromList(password + salt);
    }
    currentHash = Uint8List.fromList(md5.convert(preHash).bytes);
    concatenatedHashes = Uint8List.fromList(concatenatedHashes + currentHash);
  }
  return [
    concatenatedHashes.sublist(0, 32),
    concatenatedHashes.sublist(32, 48),
  ];
}
