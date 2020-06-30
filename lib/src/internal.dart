var updateGoldensOnFailure = false;
var pendingGoldenUpdates = <Future<void>>[];

Future<void> waitForGoldenUpdates() {
  final copy = pendingGoldenUpdates.toList();
  pendingGoldenUpdates = [];
  return Future.wait(copy);
}
