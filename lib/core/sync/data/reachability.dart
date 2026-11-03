// Is the internet really there? A phone on a dead MTN signal still reports
// "mobile", so a DNS lookup confirms it (decision 0014 §5).
export 'reachability_stub.dart' if (dart.library.io) 'reachability_io.dart';
