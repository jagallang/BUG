#!/usr/bin/env python3
"""
Firebase Firestore REST API를 사용하여 컬렉션을 직접 생성하는 스크립트
"""

import requests
import json
from datetime import datetime, timezone

# Firebase 프로젝트 설정
PROJECT_ID = "bugcash"
API_KEY = "AIzaSyCL7xdDHLHB9CggpjUHQI6mNcKEw_eHGJo"
BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

def timestamp_now():
    """현재 시간을 Firestore Timestamp 형태로 반환"""
    return datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')

def create_document(collection_name, document_id=None, data=None):
    """Firestore에 문서를 생성"""
    if document_id:
        url = f"{BASE_URL}/{collection_name}/{document_id}?key={API_KEY}"
        method = "PATCH"
    else:
        url = f"{BASE_URL}/{collection_name}?key={API_KEY}"
        method = "POST"

    # Firestore 형식으로 데이터 변환
    firestore_data = convert_to_firestore_format(data)

    response = requests.request(method, url, json={"fields": firestore_data})

    if response.status_code in [200, 201]:
        print(f"✅ 문서 생성 성공: {collection_name}")
        return response.json()
    else:
        print(f"❌ 문서 생성 실패: {response.status_code} - {response.text}")
        return None

def convert_to_firestore_format(data):
    """Python 데이터를 Firestore REST API 형식으로 변환"""
    def convert_value(value):
        if value is None:
            return {"nullValue": None}
        elif isinstance(value, bool):
            return {"booleanValue": value}
        elif isinstance(value, int):
            return {"integerValue": str(value)}
        elif isinstance(value, float):
            return {"doubleValue": value}
        elif isinstance(value, str):
            if value.endswith('Z') and 'T' in value:  # 타임스탬프 형식
                return {"timestampValue": value}
            return {"stringValue": value}
        elif isinstance(value, list):
            return {"arrayValue": {"values": [convert_value(item) for item in value]}}
        elif isinstance(value, dict):
            return {"mapValue": {"fields": {k: convert_value(v) for k, v in value.items()}}}
        else:
            return {"stringValue": str(value)}

    return {k: convert_value(v) for k, v in data.items()}

def create_tester_applications():
    """tester_applications 컬렉션 생성"""
    print("📋 tester_applications 컬렉션 생성 중...")

    # Document 1: 대기 중인 신청
    pending_data = {
        "appId": "eUOdv8wASX7RfSGMin7c",
        "testerId": "CazdCJYsxGMxEOzXGTen3AY5Kom2",
        "providerId": "provider_demo_123",
        "status": "pending",
        "statusUpdatedAt": timestamp_now(),
        "statusUpdatedBy": "",
        "appliedAt": timestamp_now(),
        "approvedAt": None,
        "startedAt": None,
        "completedAt": None,
        "testerInfo": {
            "name": "김테스터",
            "email": "tester@example.com",
            "experience": "중급",
            "motivation": "앱 품질 향상에 기여하고 싶습니다.",
            "deviceModel": "SM-S926N",
            "deviceOS": "Android 15",
            "deviceVersion": "API 35"
        },
        "missionInfo": {
            "appName": "BugCash Demo App",
            "totalDays": 14,
            "dailyReward": 5000,
            "totalReward": 70000,
            "requirements": [
                "일일 30분 이상 앱 사용",
                "피드백 작성 필수",
                "버그 발견 시 즉시 신고"
            ]
        },
        "progress": {
            "currentDay": 0,
            "progressPercentage": 0.0,
            "todayCompleted": False,
            "bugsReported": 0,
            "feedbackSubmitted": 0,
            "totalPoints": 0
        }
    }

    # Document 2: 승인된 신청
    approved_data = {
        "appId": "eUOdv8wASX7RfSGMin7c",
        "testerId": "active_tester_456",
        "providerId": "provider_demo_123",
        "status": "approved",
        "statusUpdatedAt": "2025-09-17T09:00:00Z",
        "statusUpdatedBy": "provider_demo_123",
        "appliedAt": "2025-09-17T05:00:00Z",
        "approvedAt": "2025-09-17T09:00:00Z",
        "startedAt": "2025-09-17T09:00:00Z",
        "completedAt": None,
        "testerInfo": {
            "name": "이활동",
            "email": "active@example.com",
            "experience": "고급",
            "motivation": "전문적인 QA 경험을 쌓고 싶습니다.",
            "deviceModel": "iPhone 15 Pro",
            "deviceOS": "iOS 17",
            "deviceVersion": "17.5.1"
        },
        "missionInfo": {
            "appName": "BugCash Demo App",
            "totalDays": 14,
            "dailyReward": 5000,
            "totalReward": 70000,
            "requirements": [
                "일일 30분 이상 앱 사용",
                "피드백 작성 필수",
                "버그 발견 시 즉시 신고"
            ]
        },
        "progress": {
            "currentDay": 3,
            "progressPercentage": 21.4,
            "todayCompleted": False,
            "bugsReported": 2,
            "feedbackSubmitted": 3,
            "totalPoints": 15000
        }
    }

    # Document 3: 완료된 신청
    completed_data = {
        "appId": "eUOdv8wASX7RfSGMin7c",
        "testerId": "completed_tester_789",
        "providerId": "provider_demo_123",
        "status": "completed",
        "statusUpdatedAt": "2025-09-19T10:00:00Z",
        "statusUpdatedBy": "provider_demo_123",
        "appliedAt": "2025-09-05T05:00:00Z",
        "approvedAt": "2025-09-05T10:00:00Z",
        "startedAt": "2025-09-05T10:00:00Z",
        "completedAt": "2025-09-19T10:00:00Z",
        "testerInfo": {
            "name": "박완료",
            "email": "completed@example.com",
            "experience": "고급",
            "motivation": "앱 품질 향상에 성공적으로 기여했습니다.",
            "deviceModel": "Galaxy S24 Ultra",
            "deviceOS": "Android 14",
            "deviceVersion": "API 34"
        },
        "missionInfo": {
            "appName": "BugCash Demo App",
            "totalDays": 14,
            "dailyReward": 5000,
            "totalReward": 70000,
            "requirements": [
                "일일 30분 이상 앱 사용",
                "피드백 작성 필수",
                "버그 발견 시 즉시 신고"
            ]
        },
        "progress": {
            "currentDay": 14,
            "progressPercentage": 100.0,
            "todayCompleted": True,
            "bugsReported": 8,
            "feedbackSubmitted": 14,
            "totalPoints": 70000,
            "latestFeedback": "14일 테스트 완료, 전반적으로 만족스러운 앱입니다.",
            "averageRating": 4.8
        }
    }

    # 문서들 생성
    create_document("tester_applications", None, pending_data)
    create_document("tester_applications", None, approved_data)
    create_document("tester_applications", None, completed_data)

def create_daily_interactions():
    """daily_interactions 컬렉션 생성"""
    print("\n📅 daily_interactions 컬렉션 생성 중...")

    today = datetime.now().strftime("%Y-%m-%d")
    yesterday = datetime.now().replace(day=datetime.now().day-1).strftime("%Y-%m-%d")

    # 오늘 상호작용 (대기중)
    today_data = {
        "applicationId": "app_001",
        "date": today,
        "dayNumber": 3,
        "tester": {
            "submitted": False,
            "submittedAt": None,
            "feedback": "",
            "screenshots": [],
            "bugReports": [],
            "sessionDuration": 0,
            "appRating": None
        },
        "provider": {
            "reviewed": False,
            "reviewedAt": None,
            "approved": False,
            "pointsAwarded": 0,
            "providerComment": "",
            "needsImprovement": False
        },
        "status": "pending",
        "createdAt": timestamp_now(),
        "updatedAt": timestamp_now()
    }

    # 어제 상호작용 (완료됨)
    yesterday_data = {
        "applicationId": "app_001",
        "date": yesterday,
        "dayNumber": 2,
        "tester": {
            "submitted": True,
            "submittedAt": "2025-09-18T14:00:00Z",
            "feedback": "앱이 전반적으로 잘 작동합니다. 로그인 속도가 빨라졌네요.",
            "screenshots": ["screenshot_001.jpg"],
            "bugReports": [],
            "sessionDuration": 35,
            "appRating": 4
        },
        "provider": {
            "reviewed": True,
            "reviewedAt": "2025-09-18T16:00:00Z",
            "approved": True,
            "pointsAwarded": 5000,
            "providerComment": "좋은 피드백 감사합니다.",
            "needsImprovement": False
        },
        "status": "approved",
        "createdAt": yesterday + "T00:00:00Z",
        "updatedAt": "2025-09-18T16:00:00Z"
    }

    create_document("daily_interactions", f"app_001_{today}", today_data)
    create_document("daily_interactions", f"app_001_{yesterday}", yesterday_data)

def create_apps():
    """apps 컬렉션 생성"""
    print("\n📱 apps 컬렉션 생성 중...")

    app_data = {
        "appId": "eUOdv8wASX7RfSGMin7c",
        "appName": "BugCash Demo App",
        "providerId": "provider_demo_123",
        "missionConfig": {
            "isActive": True,
            "maxTesters": 10,
            "currentTesters": 3,
            "testingPeriod": 14,
            "dailyReward": 5000,
            "requirements": [
                "일일 30분 이상 앱 사용",
                "피드백 작성 필수",
                "버그 발견 시 즉시 신고"
            ]
        },
        "stats": {
            "totalApplications": 15,
            "pendingApplications": 2,
            "activeTesters": 3,
            "completedTesters": 10,
            "totalBugsFound": 25,
            "averageRating": 4.2
        },
        "createdAt": "2025-09-15T00:00:00Z",
        "updatedAt": timestamp_now()
    }

    create_document("apps", "eUOdv8wASX7RfSGMin7c", app_data)

def main():
    """메인 실행 함수"""
    print("🔥 Firebase Firestore 컬렉션 생성 시작")
    print(f"프로젝트 ID: {PROJECT_ID}")
    print(f"Base URL: {BASE_URL}")
    print()

    try:
        # 1. tester_applications 컬렉션 생성
        create_tester_applications()

        # 2. daily_interactions 컬렉션 생성
        create_daily_interactions()

        # 3. apps 컬렉션 생성
        create_apps()

        print("\n🎉 모든 컬렉션 생성 완료!")
        print("Firebase Console에서 확인: https://console.firebase.google.com/u/0/project/bugcash/firestore")
        print()
        print("생성된 컬렉션:")
        print("- tester_applications (3개 문서)")
        print("- daily_interactions (2개 문서)")
        print("- apps (1개 문서)")

    except Exception as e:
        print(f"❌ 오류 발생: {e}")

if __name__ == "__main__":
    main()