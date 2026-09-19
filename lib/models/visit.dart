import 'green_space.dart';

class Visit {
  final String id;
  final String greenSpaceId;
  final String greenSpaceName;
  final double latitude;
  final double longitude;
  final DateTime startTime;
  final DateTime endTime;
  final int preScore;
  final int postScore;
  final int stressReduction;
  final int quietRating;
  final List<int> preAnswers;
  final List<int> postAnswers;

  const Visit({
    required this.id,
    required this.greenSpaceId,
    required this.greenSpaceName,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.endTime,
    required this.preScore,
    required this.postScore,
    required this.stressReduction,
    required this.quietRating,
    required this.preAnswers,
    required this.postAnswers,
  });

  Visit copyWith({GreenSpace? greenSpace}) => Visit(
        id: id,
        greenSpaceId: greenSpace?.id ?? greenSpaceId,
        greenSpaceName: greenSpace?.name ?? greenSpaceName,
        latitude: greenSpace?.latitude ?? latitude,
        longitude: greenSpace?.longitude ?? longitude,
        startTime: startTime,
        endTime: endTime,
        preScore: preScore,
        postScore: postScore,
        stressReduction: stressReduction,
        quietRating: quietRating,
        preAnswers: preAnswers,
        postAnswers: postAnswers,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'greenSpaceId': greenSpaceId,
        'greenSpaceName': greenSpaceName,
        'latitude': latitude,
        'longitude': longitude,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'preScore': preScore,
        'postScore': postScore,
        'stressReduction': stressReduction,
        'quietRating': quietRating,
        'preAnswers': preAnswers,
        'postAnswers': postAnswers,
      };

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
        id: json['id'] as String,
        greenSpaceId: json['greenSpaceId'] as String,
        greenSpaceName: json['greenSpaceName'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        preScore: json['preScore'] as int,
        postScore: json['postScore'] as int,
        stressReduction: json['stressReduction'] as int,
        quietRating: json['quietRating'] as int,
        preAnswers: (json['preAnswers'] as List).cast<int>(),
        postAnswers: (json['postAnswers'] as List).cast<int>(),
      );
}