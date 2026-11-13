# 행궁다과 팝업 키오스크

화성행궁 전통 다과를 소개하는 iPad·Android 태블릿용 Flutter 데모입니다. 한국어·영어·일본어로 여섯 문항에 답하면 앱이 기기에서 다과를 추천합니다.

## 실행

Flutter 3.41.5와 Dart 3.11.3을 기준으로 확인했습니다. iOS 실기기는 Xcode에서 개발 팀과 서명을 설정해 주세요.

```sh
flutter pub get
flutter devices
flutter run -d <DEVICE_ID>
```

시작 화면의 이름을 길게 누르면 관리자 설정이 열립니다. 새 설치에서 운영자가 처음 열 때 숫자 네 자리를 두 번 입력해 PIN을 설정합니다. 관리자 설정에서 품절 상태와 다과별 추천 비중을 바꿀 수 있습니다.

## 코드와 검증

- `lib/pages/kiosk_page.dart`에서 시작, 설문, 추천 결과와 자동 초기화 흐름을 관리합니다.
- `lib/services/local_recommendation_engine.dart`에서 답변과 운영 가능한 다과를 바탕으로 추천합니다.
- `lib/services/admin_settings.dart`와 `lib/services/dangwa_inventory.dart`에서 기기별 관리자 설정을 저장합니다.

```sh
flutter analyze
flutter test
```

이 공개본은 전시용 프로젝트의 데모 사본입니다. 공식 로고와 제품 사진은 데모 그래픽으로 교체했고, 길 안내에는 직접 그린 약도를 사용합니다.

## 개발

이 팝업 키오스크 서비스는 [jjukummee](https://github.com/jjukummee)가 개발했습니다.

## 글꼴

- [Fraunces · SIL Open Font License](assets/fonts/Fraunces-OFL.txt)
- [Pretendard · SIL Open Font License](assets/fonts/Pretendard-OFL.txt)
