# 테스트

## STATUSTEXT (#253) ALERT

- 레벨 필터 제거하면 알림 오는 것을 볼 수 있음

```python
severity = msg.get("severity", 6)
    # if severity > 4:
    #     return
```
