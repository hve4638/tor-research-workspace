# RAPTOR: Routing Attacks on Privacy in Tor

**요약 작성일**: 2026-02-21
**원문**: Yixin Sun, Anne Edmundson, Laurent Vanbever, Oscar Li, Jennifer Rexford, Mung Chiang, Prateek Mittal
**소속**: Princeton University / ETH Zurich
**학회**: 24th USENIX Security Symposium (2015)
**DOI/URL**: https://www.usenix.org/conference/usenixsecurity15/technical-sessions/presentation/sun

---

## 1. 핵심 기여 (One-line)

인터넷 라우팅의 **동적 특성**(비대칭 경로, BGP churn, BGP hijack/interception)을 악용하여 AS-level 적대자가 Tor 사용자를 기존보다 **50~100% 더 효과적으로** 비익명화할 수 있음을 최초로 실증한 논문.

---

## 2. 연구 동기

- Tor는 통신 양 끝(entry/exit)을 동시에 관찰할 수 있는 적대자에게 트래픽 상관 공격으로 취약
- 기존 AS-level 적대자 연구(Feamster & Dingledine 2004, Edman & Syverson 2009, Johnson et al. 2013)의 한계:
  - **대칭 경로만 고려**: A→B 경로만 분석, B→A 경로(역방향)는 무시 → 실제 인터넷은 비대칭
  - **정적 라우팅만 가정**: BGP 경로가 시간에 따라 변화하는 것을 반영하지 않음
  - **수동적 관찰만 고려**: AS가 능동적으로 BGP를 조작하여 경로를 변경하는 시나리오 미분석
- NSA(Marina 프로그램), GCHQ(Tempora 프로그램) 등 국가 기관이 실제로 AS를 통한 대규모 감시를 수행 중
- Edward Snowden 폭로로 AS-level 위협의 현실성이 확인됨

---

## 3. 공격 모델 (Raptor Attacks)

RAPTOR는 3가지 독립적 공격의 **복합체**(compounded)로, 각 공격이 상호 보완적으로 위협을 증대시킨다.

|  | Traffic Analysis | BGP Churn | BGP Hijack | BGP Interception |
|---|---|---|---|---|
| **Symmetric** | 기존 연구 | **신규** | **신규** | **신규** |
| **Asymmetric** | **신규** | **신규** | **신규** | **신규** |

### 3.1 비대칭 트래픽 분석 (Asymmetric Traffic Analysis)

- **핵심 관찰**: 인터넷 경로는 비대칭 — exit→server 경로와 server→exit 경로가 다를 수 있음
- 기존 공격은 동일 방향(data flow 방향)의 트래픽만 관찰하는 것을 가정
- **RAPTOR 공격**: 적대자가 양 끝에서 **어떤 방향이든** 하나씩만 관찰해도 상관 공격 가능
  - (a) client→entry data + exit→server data (기존 대칭 공격)
  - (b) client→entry data + server→exit TCP ACK
  - (c) guard→client TCP ACK + exit→server data
  - (d) guard→client TCP ACK + server→exit TCP ACK
- **TCP 헤더 활용**: Tor는 SSL/TLS로 암호화하지만 TCP 헤더는 평문 → TCP sequence number와 ACK number 필드를 추출하여 시간별 전송 바이트 벡터를 생성, Spearman 순위 상관계수로 상관 분석
- **결과**: 비대칭 경로를 고려하면 관찰 가능한 AS 수가 대폭 증가 (Figure 1: 순방향만 고려 시 AS5만 위협, 양방향 고려 시 AS3, AS4, AS5 모두 위협)

### 3.2 자연적 BGP Churn

- Guard 릴레이는 고정되어 있지만, client↔guard 사이의 **AS-level 경로**는 시간에 따라 변화
  - 물리 토폴로지 변화 (링크 장애, 복구, 새 라우터/링크 배치)
  - AS-level 라우팅 정책 변경 (트래픽 엔지니어링, 새로운 비즈니스 관계)
- 시간이 지남에 따라 더 많은 AS가 관찰 위치에 오게 되어 감시 능력이 **누적적으로 증가**
- Tor는 Guard 고정으로 릴레이 적대자에 대한 시간적 위협은 완화하지만, AS-level 적대자에 대한 시간적 위협은 미해결

### 3.3 BGP Hijack

- AS-level 적대자가 Tor 릴레이의 IP prefix를 자기 것으로 **공고(advertise)** → 해당 prefix로 향하는 트래픽을 가로챔
- **공격 시나리오**:
  1. 기존 공격으로 대상 사용자의 Guard 릴레이 식별 (side-channel 공격 활용)
  2. Guard 릴레이의 prefix를 BGP hijack
  3. Guard로 향하던 모든 클라이언트 IP 주소(축소된 익명 집합) 획득
- **한계**: 트래픽이 blackhole되어 연결 끊김 → 세밀한 트래픽 분석은 불가, 하지만 **축소된 익명 집합** 자체가 심각한 정보 유출

### 3.4 BGP Interception (가로채기)

- Hijack의 진화형: 트래픽을 가로챈 후 **원래 릴레이로 다시 전달** → 연결 유지
- 악의적 AS가 경로 중간에 삽입되어 **모든 트래픽을 관찰하면서도 연결을 끊지 않음**
- **정확한 비익명화 가능**: 비대칭 트래픽 분석과 결합하여 개별 사용자를 정확히 식별
- Guard 릴레이와 Exit 릴레이 양쪽에 동시에 interception 공격을 수행하면 **일반 감시(general surveillance)** 가능
- More-specific prefix 공격: 원래 /23 prefix에 대해 /24를 광고하여 트래픽 유인

---

## 4. 방법론

### 4.1 비대칭 트래픽 분석 실험 (Live Tor Network)

- **실험 환경**: PlanetLab 100대 (50 클라이언트 + 50 웹 서버), 미국/유럽/아시아 분포
- 50개 클라이언트에 Tor 설치, Privoxy로 wget 요청을 Tor 터널링
- 각 클라이언트가 각 서버의 100MB 이미지 파일 요청, tcpdump로 300초간 캡처
- **상관 분석**: TCP sequence/ACK number에서 시간별 전송 바이트 벡터 계산 → Spearman 순위 상관계수로 매칭
- **결과**: 평균 **95% 정확도**, false positive **0%**, false negative 4~6%
- 정확도는 시간에 따라 증가: 1분 내 80%, 5분(300초) 후 95%

### 4.2 BGP Churn 분석 — Control-plane

- **데이터셋**: 6개 RIPE BGP Looking Glass에서 2015년 1월 한 달간 **6.12억+ BGP update** 수집 (550,000 IP prefix, 250+ BGP 세션)
- Tor 데이터: 동일 기간 **6,755개 릴레이** (Guard 1,459, Exit 1,182, 양쪽 338)
- 각 BGP 세션을 클라이언트/목적지의 proxy로 사용
- **측정 방법**: AS X가 (client→guard) 경로와 (destination→exit) 경로 양쪽의 AS-PATH에 동시에 존재하는 경우를 "compromising"으로 판정

### 4.3 BGP Churn 분석 — Data-plane

- RIPE Atlas 70개 probe 사용 (4개 집합: S1=Tor 클라이언트 상위 10개 AS, S2=Guard 대역폭 상위 25개 AS, S3=Exit 대역폭 상위 25개 AS, S4=Tor 목적지 상위 10개 AS)
- 3주간 매일 traceroute 수행 → 10x25x25x10 = **62,500개 가능한 Tor 회로** 측정
- 양방향 경로(P1~P4) 간 공통 AS 탐색

### 4.4 BGP Hijack/Interception 실험

- **Transit Portal(TP)** 활용: GATECH TP(정상 AS), ISI TP(악의적 AS) 두 배치 사용
- 자체 Tor Guard 릴레이 설정 후 /23 prefix를 GATECH TP로 공고
- Interception: ISI TP에서 /24(more-specific) prefix 공고 → 트래픽이 ISI로 전환되지만 VPN 터널로 원래 릴레이에 도달
- 50개 Tor 클라이언트가 50개 웹 서버에 요청, 20초 후 interception 시작, 300초 후 철회
- 윤리적 고려: 자체 트래픽만 공격, 자체 릴레이만 대상, 방화벽으로 실제 Tor 사용자 차단

---

## 5. 주요 결과

### 5.1 비대칭 트래픽 분석

| 시나리오 | 정확도 | False Negative | False Positive |
|---------|--------|---------------|---------------|
| Client ACK / Server ACK | **96%** | 4% | 0% |
| Client ACK / Server Data | **94%** | 6% | 0% |
| Client Data / Server ACK | **96%** | 4% | 0% |
| Client Data / Server Data | **94%** | 6% | 0% |
| **평균** | **95%** | **5%** | **0%** |

- 95% 신뢰구간: false negative 0.48%~16.54%, false positive 0%~0.15%

### 5.2 BGP Churn (Control-plane)

- **정적 baseline**: (src,dst) 쌍의 50%에서 최소 0.75%의 Tor 회로가 compromised; 95th-percentile에서 13%
- **Churn 효과**: (src,dst) 쌍의 **60%**에서 compromised 회로 수 증가, **20%의 경우 50% 증가** (비율 1.5)
- Compromisable (src,dst) 쌍 수: 5,593 → 5,754 (**~3% 증가**)
- **Top 10 AS**: NTT(91%), IIJ(91%), Level3(88%), Cogent(63%), TeliaSonera(50%) 등이 전체 Tor 회로의 최대 **90%** 트래픽을 관찰 가능

### 5.3 BGP Churn (Data-plane, Traceroute)

| 측정 조건 | 취약 Tor 회로 비율 |
|---------|----------------|
| 순방향 경로만 (1일차) | **12.8%** |
| 양방향 경로 (1일차) | **21.3%** (순방향 대비 ~2배) |
| 양방향 경로 (21일차) | **31.8%** (순방향 대비 ~3배) |

→ 비대칭 라우팅 고려 시 취약 회로 **약 2배**, churn까지 고려하면 **약 3배** 증가

### 5.4 Tor 릴레이 집중도

| AS 이름 | ASN | 릴레이 비율 | 대역폭 비율 | Prefix 수 |
|--------|-----|----------|----------|----------|
| OVH | 16276 | 10.5% | 23% | 11.80 |
| Hetzner | 24940 | 6.30% | 13% | 6.68 |
| Online.net | 12876 | 4.78% | 7% | 10.52 |
| Wedos | 197019 | 3.04% | 4% | 2.58 |
| Leaseweb | 16265 | 2.04% | 14% | 4.27 |
| PlusServer | 8972 | 1.69% | 9% | 3.86 |
| **합계** | | **28.35%** | | **39.71%** |

→ **6개 AS, 70개 prefix에 릴레이의 ~30%, 대역폭의 ~40%** 집중 — hijack/interception의 매력적 타겟

### 5.5 실제 BGP Hijack 사례에서 Tor 릴레이 피해

| 사건 | Hijack된 릴레이 | Guard | Exit |
|-----|-------------|-------|------|
| Indosat 2011 | 5 (0.24%) | 1 (0.15%) | 4 (0.44%) |
| Indosat 2014 | 44 (0.80%) | 38 (1.80%) | 17 (1.65%) |
| Canadian Bitcoin 2014 | 1 (Guard) | 1 | - |

- Indosat 2014: 417,038개 prefix를 비정상 공고 (평소 300개) → 44개 Tor 릴레이 피해
- Canadian Bitcoin 2014: $83,000 Bitcoin 탈취 목적, OVH의 prefix가 MTO Telecom에 의해 hijack → Guard 릴레이 포함
- **>90% Tor 릴레이의 prefix가 /24 미만** → more-specific prefix 공격에 취약

### 5.6 BGP Interception 실험 결과

- **90% 정확도**로 Tor 사용자 비익명화 성공
- Interception 시작(t=20s) → ~35초 후(t=55s) 트래픽 전환 완료, 연결 유지
- 철회(t=300s) → ~22초 후 정상 복귀
- 정확도가 정적 분석(95%)보다 낮은 이유: 50개 클라이언트가 동일 Guard를 사용하여 동일 Exit 공유 확률 증가 → 대역폭 패턴 유사화 (실제 환경에서는 더 높은 정확도 예상)

---

## 6. 방어 제안

### 6.1 대응책 분류 (Taxonomy)

두 가지 대분류:
1. **트래픽 가로채기 완화** (Mitigating Traffic Interception)
2. **상관 공격 완화** (Mitigating Correlation Attacks)

### 6.2 트래픽 가로채기 완화

| 대응책 | 대상 위협 | 설명 |
|-------|---------|------|
| **AS-Aware 경로 선택** | 정적 경로, 비대칭, Churn | 릴레이가 각 목적지 prefix로의 AS 경로를 공개, 클라이언트가 동일 AS가 양쪽 세그먼트에 없도록 릴레이 선택 |
| **AS-level 경로 모니터링** | Churn | data-plane(traceroute) + control-plane(BGP feed)으로 경로 변화 추적 |
| **/24 prefix 공고** | BGP Hijack/Interception | 릴레이 운영자가 /24 prefix 사용 → more-specific 공격 차단 (ISP들이 /24보다 긴 prefix 필터링) |
| **가까운 Guard 선택** | BGP Hijack/Interception, 비대칭, Churn | AS-level 경로가 짧은 Guard 선호 → equally-specific 공격의 영향 범위 축소 |
| **Secure BGP 배포** | BGP Hijack/Interception | S-BGP 등 보안 라우팅 프로토콜 — 다수 이해관계자 동의 필요, 진행 느림 |

### 6.3 모니터링 프레임워크

**BGP Monitoring Framework**:
- Routeviews에서 BGP 데이터 수집, Tor prefix 관련 업데이트 필터링
- **Frequency heuristic**: AS가 소유하지 않은 prefix를 극히 드물게 공고하는 경우 탐지 (임계값: 0.00001)
- **Time heuristic**: prefix 공고 지속 시간이 극히 짧은 경우 탐지 (임계값: 0.01)
- 알려진 모든 hijack 사례를 성공적으로 탐지

**Traceroute Monitoring Framework**:
- PlanetLab 450대에서 모든 Tor entry/exit 릴레이로 traceroute 수행
- 140개 AS에 분포, entry 릴레이 982개 AS, exit 릴레이 882개 AS
- BGP interception 실험의 data-plane 이상을 성공적으로 탐지

### 6.4 기각된 대응책 (Appendix)

- **패킷 타이밍/크기 난독화**: high-latency mix network, constant-rate cover traffic → Tor에 배포하기에 너무 비용이 큼
- **TCP 헤더 암호화 (IPSec)**: 대규모 엔지니어링 필요, Tor 트래픽 식별 용이해짐, TCP ACK 패킷 수만으로도 상관 가능하여 완전 해결 불가

---

## 7. 프로젝트 연관성

이 논문은 본 프로젝트(project-tor)의 **핵심 참조 논문**으로, 시뮬레이터의 주요 기능이 RAPTOR 공격 모델에 기반한다.

| 논문 개념 | 프로젝트 구현 |
|----------|-------------|
| **비대칭 경로 (A→B ≠ B→A)** | `next-simulate/internal/asgraph/path.go` — AS 경로 추론에서 비대칭 경로 모델링, `internal/observer/` — 양방향 트래픽 관찰 판정 |
| **BGP Hijack 공격** | `next-simulate/internal/bgp/hijack.go` — prefix 탈취, 모든 트래픽을 공격자가 흡수 |
| **BGP Interception 공격** | `next-simulate/internal/bgp/interception.go` — 경로 삽입, 기존 provider 유지하며 트래픽 경유 |
| **AS-level 적대자 모델** | `next-simulate/internal/asgraph/` — AS 그래프 + 관계 모델링 (peer/provider-customer) |
| **4종 적대자 모델** | `next-simulate/configs/bgp_attack.yaml` — SingleAS, Colluding, StateLevel, Tier1 |
| **BGP Churn (동적 토폴로지)** | `next-simulate/internal/asgraph/temporal.go` — CAIDA 스냅샷 기반 30일 주기 전환, 노드 churn |
| **Guard/Exit 대역폭 가중치 선택** | `next-simulate/internal/circuit/` — 3-hop 회로 생성, 대역폭 비례 확률적 선택 |
| **Counter-RAPTOR 방어** | `next-simulate/internal/defense/counter_raptor.go` — resilience 기반 Guard 재가중치 (논문 이름 자체가 RAPTOR에 대한 방어) |
| **Astoria 방어** | `next-simulate/internal/defense/astoria.go` — entry/exit transit AS 교집합 검사 |
| **AS-Aware 경로 선택 (대응책)** | `next-simulate/configs/counter_raptor_defense.yaml`, `astoria_defense.yaml`, `combined_defense.yaml` — 3종 방어 시나리오 |
| **상관율 분석** | `tor-anal/analysis/` — NDJSON 파싱, 상관율 계산, 공격 전/중/후 분석, 방어 비교 |
| **릴레이 집중도 (소수 AS에 밀집)** | `tor-anal/output/as_model_simplified.json` — 727 AS 노드 + guard/exit 가중치, `tor-anal/data/model_edges.json` — 6,325 AS 연결 |

### 본 논문이 "Users Get Routed" (Johnson et al. 2013)와 다른 점

| 비교 항목 | Users Get Routed | RAPTOR |
|---------|-----------------|--------|
| **관찰 방식** | 수동적(passive) 관찰 | 수동적 + **능동적(active)** BGP 조작 |
| **경로 가정** | 대칭 경로만 고려 | **비대칭 경로** 포함 (핵심 기여) |
| **시간적 변화** | 릴레이 적대자의 시간적 위험만 분석 | **AS-level 적대자의 BGP churn** 분석 |
| **공격 유형** | 기존 네트워크 위치에서 관찰 | BGP hijack + interception으로 **경로 조작** |
| **실증** | 시뮬레이션(TorPS) 기반 | **실제 Tor 네트워크에서 공격 수행** |
| **프로젝트 대응** | 기본 적대자 모델 (M1~M3) | BGP 공격 시뮬레이션 (M5), 방어 전략 (M6) |

---

## 8. 한계 및 후속 연구

- **단일 AS 관점**: 개별 AS의 위협만 정량화, 공모(colluding) AS 시나리오는 정성적 논의에 그침
- **IXP 미분석**: Internet Exchange Point를 통한 관찰은 고려하지 않음 (Johnson et al. 2013에서 다룸)
- **Hidden Service 미고려**: onion service 트래픽의 라우팅 공격 취약성 미분석
- **방어 효과 미검증**: Counter-RAPTOR, Astoria 등 후속 방어책의 정량적 효과는 본 논문에서 미평가 (후속 연구에서 다룸)
- **가까운 Guard 선택의 트레이드오프**: Guard 위치에서 클라이언트 위치를 추론할 수 있는 부작용 — 향후 연구 과제로 남김
- **실험 규모**: PlanetLab 50 클라이언트/50 서버 — 실제 Tor 네트워크 규모(수백만 사용자)에 비해 소규모
- **2015년 데이터 기반**: Tor 네트워크와 인터넷 토폴로지가 이후 변화
- **패킷 타이밍/크기 난독화 방어**: 비용 문제로 기각했으나 부분적 방어 가능성 미탐구

### 후속 연구로 이어진 논문들

- **Counter-RAPTOR** (Sun et al., S&P 2017): RAPTOR에 대한 방어로 resilience 기반 Guard 선택 제안 → 프로젝트 M6에서 구현
- **Astoria** (Nithyanand et al., NDSS 2016): AS-aware 경로 선택 알고리즘 → 프로젝트 M6에서 구현

---

## 9. 참고 수치 요약

```
비대칭 트래픽 분석 (Live Tor Network):
  - 평균 정확도: 95% (300초 관찰)
  - False positive: 0%
  - 80% 정확도 도달 시간: ~1분

BGP Churn (Control-plane, 1개월):
  - Compromised 회로 증가: 60%의 (src,dst)에서 증가, 20%에서 50% 증가
  - Compromisable (src,dst) 쌍: 5,593 → 5,754 (~3% 증가)
  - Top AS(NTT, Level3 등): 전체 Tor 회로의 최대 90% 관찰 가능

BGP Churn (Data-plane, 3주):
  - 순방향만: 12.8% 취약
  - 양방향(1일차): 21.3% 취약 (~2배)
  - 양방향(21일차): 31.8% 취약 (~3배)

Tor 릴레이 집중도:
  - 6개 AS, 70개 prefix에 ~30% 릴레이, ~40% 대역폭 집중
  - >90% 릴레이 prefix가 /24 미만 → more-specific 공격에 취약

BGP Interception 실험:
  - 비익명화 정확도: 90%
  - Interception 전파 시간: ~35초
  - Withdrawal 복귀 시간: ~22초

실제 BGP Hijack 사례:
  - Indosat 2014: 44 릴레이 피해 (Guard 38, Exit 17)
  - Canadian Bitcoin 2014: 1 Guard 릴레이 피해

인터넷/Tor 데이터 규모:
  - BGP 업데이트: 6.12억+ (2015년 1월, 1개월)
  - Tor 릴레이: 6,755개 (Guard 1,459, Exit 1,182)
  - Traceroute: 62,500 가능 회로 측정
```
