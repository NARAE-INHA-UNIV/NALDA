# NALDA

    NALDA (NARAE Aero Link & Data Analysis)

나래에서 개발한 GCS(Grond Control System).<br>

- 팀장 : 김성호

## 프로젝트 구조

```
NALDA/
├── backend/                # ** backend **
├── src/                    # **    UI   **
│   ├── assets/             # 이미지, 폰트 등의 정적 파일
│   │   ├── fonts/          # 폰트
│   │   └── icons/          # 아이콘
│   ├── components/         # 재사용 가능한 공통 컴포넌트
│   ├── pages/              # 페이지 컴포넌트
│   ├── themes/             # 색상 등 테마 관리
│   ├── main.qml            # QML 진입점
│   └── styles.qss          # 전역 QML 스타일링
│   └── sample/             # path planning에 사용할 샘플
├── windows/                # 팝업 윈도우 구동 python코드
├── main.py                 # 앱 진입점
└── requirements.txt        # 파이썬 의존성 패키지 목록
```

## 실행 방법

### Python 가상환경 구성

- Python 3.12.11

1. 가상 환경 생성

```bash
python venv -p 3.12.11
```

2. 가상 환경 활성화

```bash
.\venv\Scripts\activate
```

3. 의존성 설치

```bash
pip install -r requirements.txt
```

### 실행 

```bash
python main.py
```

