# 04. BFS 라우팅 모델 vs 실제 BGP 정책

> 우리의 경로 계산 방식이 실제 인터넷과 어떻게 다른지

---

## 1. BFS (Breadth-First Search) — 우리의 모델

### 동작 방식

```
AS_A에서 AS_B로의 경로를 찾을 때:
  1. AS_A를 시작점으로 설정
  2. AS_A의 모든 이웃을 큐에 추가 (1홉)
  3. 이웃의 이웃을 큐에 추가 (2홉)
  4. AS_B에 도달하면 그 경로를 반환
```

### 특징

- **항상 최단 경로**를 반환 (홉 수 기준)
- **대칭**: A→B와 B→A가 동일한 경로를 사용
- **결정적**: 같은 그래프에서 항상 같은 결과
- **관계 무시**: peer와 provider-customer를 구분하지 않음

### 구현 위치

`next-simulate/internal/asgraph/pathfinder.go` — BFS 기반 경로 탐색

---

## 2. 실제 BGP 라우팅 정책

### BGP 경로 선택 과정

실제 인터넷에서 AS는 여러 경로 중 하나를 **정책에 따라** 선택한다:

```
1. LOCAL_PREF (최우선)
   - customer > peer > provider 순으로 선호
   - 이유: customer에서 돈을 받고, provider에게 돈을 냄

2. AS_PATH 길이 (차순위)
   - 짧은 경로 선호 (BFS와 유사)

3. MED (Multi-Exit Discriminator)
   - 같은 이웃 AS의 여러 연결점 중 선호하는 것

4. Hot-potato routing
   - 자기 네트워크를 최대한 빨리 벗어나는 경로 선택
   - 비용 절감 목적
```

### Valley-Free Routing 원칙

실제 인터넷 경로는 "valley-free" 규칙을 따른다:

```
유효한 경로:
  customer → ... → customer → provider → provider → ... → provider
                           (정점)

  또는: customer → ... → peer → provider → ... → provider

무효한 경로:
  provider → customer → provider  (valley = 골짜기 형태)
```

이 규칙 때문에:
- BFS가 찾은 최단 경로가 실제로는 사용 불가능할 수 있음
- 실제 경로가 BFS 경로보다 길 수 있음

---

## 3. 비대칭 라우팅이 발생하는 이유

### BFS에서는 비대칭이 없다

```
A → B: BFS는 A에서 시작하여 B까지 최단 경로 탐색
B → A: BFS는 B에서 시작하여 A까지 최단 경로 탐색

무방향 그래프에서 A→B = B→A (항상 동일)
```

### 실제 BGP에서는 비대칭이 흔하다

```
A → X → Y → B  (A가 선택한 경로: X가 customer이므로 선호)
B → Z → W → A  (B가 선택한 경로: Z가 customer이므로 선호)

A와 B는 각자의 LOCAL_PREF에 따라 다른 경로를 선택
→ 중간 transit AS가 다름 = 비대칭
```

**RAPTOR 논문의 핵심 발견**: 비대칭 라우팅으로 인해 forward/reverse 경로에서 **서로 다른 AS가 트래픽을 관찰**하게 되며, 이는 상관 공격의 성공 확률을 1.66배 높인다.

### 우리 모델에서 비대칭이 안 되는 이유

1. **그래프가 작다** (727 AS): 경로가 2-4홉이라 우회할 여지가 없음
2. **BFS 사용**: 정책 기반 경로 선택이 없어 항상 대칭
3. **결합 효과**: 작은 그래프 + BFS = 비대칭 재현 불가능

---

## 4. BGP Interception이 안 되는 이유

### Interception 공격 원리

```
정상:   Client → T1 → T2 → Guard
공격 후: Client → T1 → [Attacker] → T2 → Guard

공격자가 BGP에 거짓 경로를 주입하여 트래픽이 자신을 경유하게 만듦
```

### 우리 모델에서 안 되는 이유

```
727 AS 그래프:
  Client → Guard  (2홉, 직접 연결이 많음)

Tier-1 AS(AS6939 등)가 이미 전체 경로의 20%를 관찰 중
→ 공격으로 추가 관찰 가능한 경로가 거의 없음 (marginal gain ≈ 0)
```

전체 인터넷 그래프에서는:
```
Client → ISP1 → Tier-2 → Tier-1 → Tier-2 → ISP2 → Guard  (6홉)

공격자가 Tier-1과 Tier-2 사이에 자신을 삽입하면:
→ 새로운 경로를 관찰 가능 (marginal gain > 0)
```

---

## 5. 해결의 우선순위

| 문제 | 기여도 | 해결 방법 |
|------|--------|----------|
| 토폴로지 규모 (727 AS) | **80%** | Step 06b: Transit AS 2-hop 확장 → ~8,000 AS |
| BFS 라우팅 (정책 미반영) | **20%** | RouteViews RIB AS_PATH 활용 (향후) |

**토폴로지 확장만으로도 상당한 개선이 기대되는 이유**:
- 경로 길이가 4-7홉으로 증가
- 중간 transit AS가 다수 생김
- BFS로도 경로가 길어지면 자연스럽게 forward/reverse 차이 발생 가능
- RAPTOR 논문 자체도 BFS + valley-free를 기본 모델로 사용 (iPlane은 보정용)

**BGP 정책 반영은 토폴로지 확장 후 평가**:
- 확장된 그래프에서 BFS 결과가 충분하면 불필요
- 부족하면 RouteViews AS_PATH 데이터 활용 검토
