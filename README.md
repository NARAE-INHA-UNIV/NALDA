# NALDA

![alt text](NALDA.png)

<p align="center">
    <em>NALDA (NARAE Aero Link & Data Analysis)</em>
</p>

인하대학교 모형항공기 동아리 나래에서 개발한 GCS(Grond Control System).<br>

- 팀장 : 김성호

## 프로젝트 구조

```
NALDA/
├── docs/                     # 문서
├── src/                      # 메인 소스
│   ├── backend/                 # Qt 벡엔드
│   ├── frotend/                 # QML 파일 및 이미지 폰트 등의 정적 파일
│   │   ├── assets/                 # 이미지, 폰트 등의 정적 파일
│   │   ├── components/             # 재사용 가능한 공통 컴포넌트
│   │   ├── pages/                  # 페이지별 QML
│   │   ├── styles/                 # 색상 파레트
│   │   ├── main.qml                # QML 진입점
│   │   └── styles.qss              # 전역 스타일링
│   ├── windows/                 # 창 단위의 위젯 모음
│   ├── main.py                  # 앱 진입점
│   ├── main.spec                # pyinstaller 빌드 설정 파일
│   └── requirements.txt         # 파이썬 의존성 패키지 목록
├── tests/                    # 기능 테스트에 필요한 파일들
└── README.md                 # readme
```

## 실행 방법

### Project clone

```bash
git clone --recursive https://github.com/NARAE-INHA-UNIV/NALDA
cd NALDA
```

### Python 가상환경 구성

- [Python 3.12.10 install](https://www.python.org/downloads/release/python-31210/)

1. 가상 환경 생성

   ```bash
   python -m venv
   ```

2. 가상 환경 활성화

   ```bash
   .\venv\Scripts\activate
   ```

3. 의존성 설치

   ```bash
   pip install -r src/requirements.txt
   ```

### 실행

1. 가상 환경 활성화

   ```bash
   .\venv\Scripts\activate
   ```

2. 실행
   ```bash
   cd src
   python main.py
   ```

### Project update

```bash
git pull
git submodule update
```

## 빌드 방법

### 빌드

```bash
pyinstaller main.spec
```

### 최초 빌드

- pyinstaller로 처음 빌드하는 경우 (`main.spec` 없는 상태에서 만들 경우)
- 아래 명령어 실행 후 datas 목록 등 포함할 파일 및 패키지 추가해야 함

```bash
pyinstaller --onefile --noconsole --icon='frontend/assets/app.ico' main.py
```
