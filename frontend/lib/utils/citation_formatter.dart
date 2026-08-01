class CitationFormatter {
  /// Format APA (7th Edition) Citation
  /// Author, A. A. (Year). Title of work. Publisher / URL.
  static String formatAPA({
    required String author,
    required String title,
    required String year,
    String? publisher,
    String? url,
  }) {
    final cleanAuthor = author.isNotEmpty ? author : 'Anonymous';
    final cleanYear = year.isNotEmpty ? '($year)' : '(n.d.)';
    final cleanTitle = title.isNotEmpty ? title : 'Untitled Source';
    
    String citation = '$cleanAuthor. $cleanYear. $cleanTitle.';
    if (publisher != null && publisher.isNotEmpty) {
      citation += ' $publisher.';
    }
    if (url != null && url.isNotEmpty) {
      citation += ' $url';
    }
    return citation;
  }

  /// Format MLA (9th Edition) Citation
  /// Author. "Title." Publisher, Year. URL.
  static String formatMLA({
    required String author,
    required String title,
    required String year,
    String? publisher,
    String? url,
  }) {
    final cleanAuthor = author.isNotEmpty ? author : 'Anonymous';
    final cleanTitle = title.isNotEmpty ? '"$title."' : '"Untitled Source."';
    final cleanYear = year.isNotEmpty ? year : 'n.d.';
    
    String citation = '$cleanAuthor. $cleanTitle';
    if (publisher != null && publisher.isNotEmpty) {
      citation += ' $publisher,';
    }
    citation += ' $cleanYear.';
    if (url != null && url.isNotEmpty) {
      citation += ' $url.';
    }
    return citation;
  }
}
