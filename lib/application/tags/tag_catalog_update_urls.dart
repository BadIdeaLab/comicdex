/// Fixed download locations for the tag catalog "check for updates" feature
/// (P59). Hosted on an independent repo whose release workflow republishes
/// both files together under the same stable `latest-build` tag whenever
/// `assets/tag_catalog.bin` / `assets/tag_catalog.version` change on `main`.
const String tagCatalogVersionUrl =
    'https://github.com/BadIdeaLab/comicdex/releases/download/latest-build/tag_catalog.version';

const String tagCatalogReleaseUrl =
    'https://github.com/BadIdeaLab/comicdex/releases/download/latest-build/tag_catalog.bin';
