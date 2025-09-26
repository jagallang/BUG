import 'dart:convert';
import 'dart:io';

void main() async {
  // Firebase REST API를 사용하여 테스트 프로젝트 생성
  final projectId = 'bugcash';
  final baseUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  final client = HttpClient();

  try {
    // 테스트 프로젝트 1 - pending 상태
    final project1Data = {
      'fields': {
        'appName': {'stringValue': '테스트 쇼핑몰 앱'},
        'description': {'stringValue': '쇼핑몰 앱의 결제 기능과 사용자 인터페이스를 테스트해주세요.'},
        'providerId': {'stringValue': 'test-provider-1'},
        'providerName': {'stringValue': '테스트 공급자 1'},
        'status': {'stringValue': 'pending'},
        'maxTesters': {'integerValue': '10'},
        'testPeriodDays': {'integerValue': '14'},
        'rewards': {
          'mapValue': {
            'fields': {
              'baseReward': {'integerValue': '50000'},
              'bonusReward': {'integerValue': '10000'}
            }
          }
        },
        'requirements': {
          'mapValue': {
            'fields': {
              'platforms': {
                'arrayValue': {
                  'values': [
                    {'stringValue': 'android'},
                    {'stringValue': 'ios'}
                  ]
                }
              },
              'minAge': {'integerValue': '18'},
              'maxAge': {'integerValue': '60'}
            }
          }
        },
        'createdAt': {'timestampValue': DateTime.now().toIso8601String()},
        'updatedAt': {'timestampValue': DateTime.now().toIso8601String()}
      }
    };

    final request1 = await client.postUrl(Uri.parse('$baseUrl/projects'));
    request1.headers.set('Content-Type', 'application/json');
    request1.write(jsonEncode(project1Data));
    final response1 = await request1.close();
    print('Project 1 created: ${response1.statusCode}');

    // 테스트 프로젝트 2 - pending 상태
    final project2Data = {
      'fields': {
        'appName': {'stringValue': '게임 앱 테스트'},
        'description': {'stringValue': '새로운 게임 앱의 게임플레이와 버그를 찾아주세요.'},
        'providerId': {'stringValue': 'test-provider-2'},
        'providerName': {'stringValue': '테스트 공급자 2'},
        'status': {'stringValue': 'pending'},
        'maxTesters': {'integerValue': '15'},
        'testPeriodDays': {'integerValue': '21'},
        'rewards': {
          'mapValue': {
            'fields': {
              'baseReward': {'integerValue': '75000'},
              'bonusReward': {'integerValue': '15000'}
            }
          }
        },
        'requirements': {
          'mapValue': {
            'fields': {
              'platforms': {
                'arrayValue': {
                  'values': [
                    {'stringValue': 'android'},
                    {'stringValue': 'ios'}
                  ]
                }
              },
              'minAge': {'integerValue': '16'},
              'maxAge': {'integerValue': '50'}
            }
          }
        },
        'createdAt': {'timestampValue': DateTime.now().toIso8601String()},
        'updatedAt': {'timestampValue': DateTime.now().toIso8601String()}
      }
    };

    final request2 = await client.postUrl(Uri.parse('$baseUrl/projects'));
    request2.headers.set('Content-Type', 'application/json');
    request2.write(jsonEncode(project2Data));
    final response2 = await request2.close();
    print('Project 2 created: ${response2.statusCode}');

    print('테스트 프로젝트 데이터 생성이 완료되었습니다!');
  } catch (e) {
    print('오류 발생: $e');
  } finally {
    client.close();
  }
}