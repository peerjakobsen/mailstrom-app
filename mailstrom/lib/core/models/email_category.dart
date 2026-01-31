enum EmailCategory {
  personal('Personal'),
  social('Social'),
  newsletter('Newsletter'),
  notification('Notification'),
  marketing('Marketing'),
  transactional('Transactional'),
  unknown('Unknown');

  const EmailCategory(this.displayName);
  final String displayName;
}
