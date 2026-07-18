String imageTypeCodeToExtension(String? code) {
  switch (code) {
    case 'j':
      return 'jpg';
    case 'p':
      return 'png';
    case 'g':
      return 'gif';
    case 'w':
      return 'webp';
    case 't':
      return 'tiff';
    case 'b':
      return 'bmp';
    case 'h':
      return 'heif';
    case 'a':
      return 'avif';
    default:
      return 'jpg';
  }
}
