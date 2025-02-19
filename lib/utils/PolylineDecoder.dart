import 'dart:math';
class PolylineDecoder {
  static const int DEFAULT_PRECISION = 5;
  static const List<int> DECODING_TABLE = [
    62, -1, -1, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1,
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, -1, -1, -1, -1, 63, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
    36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
  ];

  static List<Map<String, double>> decode(String encoded) {
    final List<int> decoder = decodeUnsignedValues(encoded);
    final Map<String, dynamic> header = decodeHeader(decoder[0], decoder[1]);

    final num factorDegree = pow(10, header['precision']);
    final num factorZ = pow(10, header['thirdDimPrecision']);
    final bool thirdDim = header['thirdDim'] > 0;

    int lastLat = 0, lastLng = 0, lastZ = 0;
    final List<Map<String, double>> res = [];

    for (int i = 2; i < decoder.length;) {
      final int deltaLat = toSigned(decoder[i]);
      final int deltaLng = toSigned(decoder[i + 1]);
      lastLat += deltaLat;
      lastLng += deltaLng;

      if (thirdDim) {
        final int deltaZ = toSigned(decoder[i + 2]);
        lastZ += deltaZ;
        res.add({
          "latitude": lastLat / factorDegree,
          "longitude": lastLng / factorDegree,
          "altitude": lastZ / factorZ,
        });
        i += 3;
      } else {
        res.add({
          "latitude": lastLat / factorDegree,
          "longitude": lastLng / factorDegree,
        });
        i += 2;
      }
    }

    return res;
  }

  static int decodeChar(String char) {
    final int charCode = char.codeUnitAt(0);
    return DECODING_TABLE[charCode - 45];
  }

  static List<int> decodeUnsignedValues(String encoded) {
    int result = 0, shift = 0;
    final List<int> resList = [];

    for (final char in encoded.split('')) {
      final int value = decodeChar(char);
      result |= (value & 0x1F) << shift;
      if ((value & 0x20) == 0) {
        resList.add(result);
        result = 0;
        shift = 0;
      } else {
        shift += 5;
      }
    }

    if (shift > 0) {
      throw Exception('Invalid encoding');
    }

    return resList;
  }

  static Map<String, dynamic> decodeHeader(int version, int encodedHeader) {
    final int headerNumber = encodedHeader;
    final int precision = headerNumber & 15;
    final int thirdDim = (headerNumber >> 4) & 7;
    final int thirdDimPrecision = (headerNumber >> 7) & 15;
    return {
      "precision": precision,
      "thirdDim": thirdDim,
      "thirdDimPrecision": thirdDimPrecision,
    };
  }

  static int toSigned(int val) {
    int res = val;
    if ((res & 1) != 0) {
      res = ~res;
    }
    res >>= 1;
    return res;
  }
}
