import 'dart:typed_data';

/// Encodes normalized (-1..1) PCM samples into a mono 16-bit WAV byte
/// buffer, so they can be handed to any file-based audio player.
class WavEncoder {
  const WavEncoder();

  Uint8List encode(List<double> samples, {required int sampleRate}) {
    final pcm = Int16List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      pcm[i] = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    }

    const bitsPerSample = 16;
    const channels = 1;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = pcm.lengthInBytes;

    final header = ByteData(44);
    void writeString(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        header.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    header.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    writeString(36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    final bytes = BytesBuilder();
    bytes.add(header.buffer.asUint8List());
    bytes.add(pcm.buffer.asUint8List());
    return bytes.toBytes();
  }
}
