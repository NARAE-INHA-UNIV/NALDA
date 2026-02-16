# 배포

1. 웹에서 dev → main PR 생성 및 merge
2. 로컬에서 pull

   ```python
   git pull
   ```

3. 태그 붙여서 업로드

   ```python
   git checkout main
   git tag -a v0.2.0 -m "Release version 0.2.0"
   git push origin --tags
   ```

4. 바이너리 미리 빌드

   ```python
   cd src
   pyinstaller main.spec
   # dist 폴더에 빌드된 파일 저장됨
   ```

5. 웹에서 해당 태그 기반으로 release 생성
   1. 해당 레포에서 오른쪽에서 Create a new release 클릭
   2. Select tag > 이번에 만든 tag 클릭
   3. Title은 태그와 동일하게 입력
   4. Generate release notes 누르고 맨 위에 summary 추가
   5. 미리 빌드한 바이너리 업로드 (ex. NALDA_windows_x64_v0.2.0.exe)
   6. Publish release
