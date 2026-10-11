import 'dart:math';

class EcvaEngine {
  /// Calculates priority score using Haversine distance and time decay
  static double calculatePriority({
    required double userLat,
    required double userLng,
    required double reportLat,
    required double reportLng,
    required dynamic timestamp,
  }) {
    // Convert timestamp to DateTime if integer
    DateTime reportTime;
    if (timestamp is int) {
      reportTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      reportTime = DateTime.parse(timestamp);
    } else {
      reportTime = DateTime.now();
    }

    // 1. Haversine Distance (in kilometers)
    const double earthRadiusKm = 6371.0;
    double dLat = _toRadians(reportLat - userLat);
    double dLng = _toRadians(reportLng - userLng);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(userLat)) *
            cos(_toRadians(reportLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distanceKm = earthRadiusKm * c;

    // 2. Spatial Score (Closer reports get higher priority)
    double spatialScore = 1.0 / (1.0 + distanceKm);

    // 3. Temporal Decay Score (Newer reports get higher priority)
    int hoursOld = DateTime.now().difference(reportTime).inHours;
    double temporalScore = exp(-0.05 * hoursOld);

    // Final Weighted Priority
    return (spatialScore * 0.6) + (temporalScore * 0.4);
  }

  static double _toRadians(double degree) {
    return degree * (pi / 180.0);
  }
}

// import 'dart:math';

// class EcvaEngine {
//   // Earth's radius in kilometers
//   static const double earthRadiusKm = 6371.0;

//   // Spatial decay factor gamma (controls how quickly weight drops over distance)
//   static const double spatialDecayGamma = 0.5; // e.g., 0.5 per km

//   // Consensus threshold required for verification
//   static const double verificationThreshold = 2.5;

//   /// Calculates Great-Circle distance between two coordinates using the Haversine formula
//   static double calculateHaversineDistance(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     double dLat = _toRadians(lat2 - lat1);
//     double dLon = _toRadians(lon2 - lon1);

//     double rLat1 = _toRadians(lat1);
//     double rLat2 = _toRadians(lat2);

//     double a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(rLat1) * cos(rLat2) * sin(dLon / 2) * sin(dLon / 2);

//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));

//     return earthRadiusKm * c; // Distance in kilometers
//   }

//   /// Calculates spatial decay weight based on distance d: W(d) = e^(-gamma * d)
//   static double calculateSpatialWeight(double distanceKm) {
//     return exp(-spatialDecayGamma * distanceKm);
//   }

//   /// Evaluates consensus score for a target report given a list of nearby peer reports
//   static Map<String, dynamic> evaluateConsensus({
//     required Map<String, dynamic> targetReport,
//     required List<Map<String, dynamic>> nearbyPeerReports,
//   }) {
//     double totalScore = 1.0; // Base score from original report

//     double targetLat = targetReport['latitude'];
//     double targetLon = targetReport['longitude'];
//     String targetCategory = targetReport['category'];

//     for (var peerReport in nearbyPeerReports) {
//       // Skip comparing report with itself
//       if (peerReport['reportId'] == targetReport['reportId']) continue;

//       // Only aggregate matching hazard categories
//       if (peerReport['category'] == targetCategory) {
//         double distance = calculateHaversineDistance(
//           targetLat,
//           targetLon,
//           peerReport['latitude'],
//           peerReport['longitude'],
//         );

//         // Apply spatial decay equation
//         double weight = calculateSpatialWeight(distance);
//         totalScore += weight;
//       }
//     }

//     bool isVerified = totalScore >= verificationThreshold;

//     return {
//       'reportId': targetReport['reportId'],
//       'consensusScore': totalScore,
//       'isVerified': isVerified ? 1 : 0,
//     };
//   }

//   static double _toRadians(double degree) {
//     return degree * (pi / 180.0);
//   }
// }


