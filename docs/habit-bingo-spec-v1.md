# 自愛花園 Self Love Garden — Habit Bingo Spec v1 (4x4)

> 目的：做到「每日一定出到一張板、唔靠 LLM 即場瞎編、唔吐垃圾任務」。
> 
> 架構：**LLM 只負責提取變數（固定 JSON）** → **規則引擎生成 4x4 任務** → **任務檢查器驗收** → UI 顯示。

---

## 0. Definitions / Scope

### MVP v0（先做 Bingo，精品）
- 平台：iPhone
- 語系：繁體中文
- 資料：全本地
- 每日切日：**凌晨 4:00**（本地時區）
- 每日第一次打開：顯示 Daily Check-in（可略過）
- 每日生成：每個習慣每天 1 張 4x4（16 格），格子一次性勾選

### 明確不做（本階段）
- iPad 版 UI
- 推播
- 雲端同步 / 登入
- 插畫/動畫（先做文字+解釋）

---

## 1. User Flow

### 1.1 Daily Check-in（每日第一次打開）
輸入（全部 slider）：
- `mood`（心情）
- `drive`（動機；語意用你選嘅 B：偏「只想先活著 → 想好好前進」）
- `yesterday_difficulty`（太輕鬆 ↔ 太吃力）

行為：
- 使用者可「略過」check-in，直接入今日 Bingo。
- check-in 會影響：**任務來源比例**、**難度層級**（升/降級）。

### 1.2 習慣選擇
- Bingo 頁上方顯示「核心習慣」名稱。
- 下拉可切換其他習慣。

### 1.3 建立/編輯習慣（MVP1：導師問答）
- 形式：**選項為主**（最穩、最少 token）。
- 最後加一題自由輸入：`free_note`（“你有沒有什麼話想說的？”）
  - **只存文字**；不作即時自由生成任務（避免廢話/飄/報錯）。

---

## 2. Data Model (Local)

### 2.1 Habit
- `id` (UUID)
- `habit_name` (String)
- `stage` (Enum: `zero_start` | `starting` | `has_base`)
- `main_barrier` (Enum: `no_time` | `fear_hard` | `forgetful` | `low_mood` | `dont_know_how` | `low_motivation`)
- `is_core` (Bool, user-selected)
- `starter_step` (String, 必須是 30 秒內、單一動作、可判斷完成)
- `context_hint` (String, 短句：在哪/何時最常做)
- `success_definition` (String, 短句：點樣算「做到」)
- `free_note` (String, optional)

> 註：`starter_step`、`context_hint`、`success_definition` 由 LLM 提取或 fallback。

### 2.2 DailyState
- `date_key` (String, 以 4:00 切日計算)
- `mood` (0..1)
- `drive` (0..1)
- `yesterday_difficulty` (0..1)

### 2.3 BingoBoard
- `habit_id`
- `date_key`
- `tasks[16]`
- `task_sources[16]` (Enum: `self_love` | `habit` | `core_habit` | `self_growth` (future))
- `checked[16]` (Bool)

---

## 3. LLM Role (Extraction Only)

### 3.1 Why
- 避免：LLM 即場生成 16 格 → 高波動、易出廢話、易重複、易超長。
- 目標：LLM 只做「人話 → 可控變數」。

### 3.2 Fixed Output Schema (LLM 必須只輸出此 JSON)
```json
{
  "habit_name": "",
  "stage": "zero_start|starting|has_base",
  "main_barrier": "no_time|fear_hard|forgetful|low_mood|dont_know_how|low_motivation",
  "starter_step": "",
  "context_hint": "",
  "success_definition": "",
  "avoidance": "",
  "free_note": ""
}
```

### 3.3 Fallback (LLM fail / timeout / invalid JSON)
- `stage`: `zero_start`
- `main_barrier`: `low_motivation`
- `starter_step`: 用「起手式模板庫」按 habit 類型選一個（見 §6）
- `context_hint`: "日常最順手嘅時間"
- `success_definition`: "完成第一步就算"

> 重要：fallback 係 silent，UI 唔顯示 error。

---

## 4. Habit Type Classification (Internal)

> 目的：用於挑選 starter_step 模板、避免碎片任務。

`habit_type`（內部判斷，不一定顯示給用戶）：
- `body_health`
- `knowledge`
- `skill`
- `environment`
- `emotion_care`
- `focus_execution`

判斷來源：
- 優先用導師問答選項（可做成單選）
- 次選：用 `habit_name` 關鍵詞輕量分類

---

## 5. Daily Mix Recipe (三段式比例)

### 5.1 State Level
由 `mood` + `drive` 合成：
- `low`：mood/drive 都偏低
- `mid`
- `high`

（門檻：實作時寫死，例如 0–0.33 / 0.33–0.66 / 0.66–1.0；可調）

### 5.2 Source Ratio（先不做 self_growth，等你之後提供分類）

- `low`：**16 格 ≈ 幾乎全自愛**
  - self_love: 12–14
  - habit + core_habit: 2–4
- `mid`：平衡
  - self_love: 6
  - habit + core_habit: 10
- `high`：**幾乎全習慣**
  - self_love: 2
  - habit + core_habit: 14

> 你要求：超低狀態時基本全自愛；相反時基本全習慣。以上符合。

### 5.3 Core Habit weighting
- 使用者可標記 `is_core=true`。
- 當日選擇核心習慣時：`core_habit` 源比例 ↑（由配方中分配）。
- 當日選擇非核心習慣時：仍可抽少量 `core_habit` 任務作「主線提醒」（但唔保證成一線，你指定唔需要）。

---

## 6. Atomic Habits Path (B only)

你拍板：**只用 B：起手式 30 秒** 作主軸。

### 6.1 Starter Step Definition
- 必須：30 秒內、單一動作、可判斷完成。
- 例（合格）：
  - "打開筆記，寫標題"
  - "穿上運動鞋"
  - "打開語音課第一頁"
- 例（不合格）：
  - "選一個更輕的版本做"（抽象/不可判斷）
  - "培養習慣"（空泛）

### 6.2 Starter Step Templates (按 habit_type)
- body_health："倒一杯水放手邊" / "穿上運動鞋"
- knowledge："打開文章，先讀第一段"
- skill："打開工具，做一次最基本動作"
- environment："清出一小格空間"
- emotion_care："坐好，深呼吸三次"
- focus_execution："把手機靜音5分鐘"

> 模板會再按 habit_name 具體化（例如閱讀→書名/語言→App 名/寫作→筆記本）。

---

## 7. Task Difficulty Ladder (16 格遞進)

> 你重點：唔係睇「時間」，而係用微習慣引導做得到、想再做。
> 所以難度定義用「心理摩擦」為主，時間只是約束。

### 7.1 Difficulty Tiers
- `micro`：起手式/最小行動（摩擦最低）
- `easy`：延伸一小步（仍然低摩擦）
- `rewarding`：有小成就感（但唔可以變大任務）

### 7.2 Yesterday difficulty adjustment
- 昨天太吃力 → `rewarding` 降為 `easy`，`easy` 降為 `micro`
- 昨天太輕鬆 → 允許少量 `easy` 升 `rewarding`

---

## 8. Task Library Strategy (No Garbage)

### 8.1 禁詞/禁句型（全域）
以下一律禁止出現在 `bingo_tasks`：
- 含糊動詞："選"、"試試"、"做做看"、"想想"、"整理一下"、"輕一點"、"一些"、"一下"
- 抽象口號："培養習慣"、"保持動力"、"持續練習"、"改善自己"、"提升效率"

### 8.2 每格硬規則（Check List）
每格必須同時滿足：
1) 只有 1 個明確動作（不可「做A再做B」）
2) 立即可做
3) 完成與否可判斷
4) 6–18 字（繁中）
5) 同一張板內不重複（動詞+物件+時長 三元組去重）
6) 有路徑感：micro → easy → rewarding 係可追蹤的階梯

### 8.3 重試與降級
- 若組合後有任務不合格：替換該格（最多 N 次）
- 超過 N 次：回落「安全模板庫」(完全 deterministic)

---

## 9. UI Notes

### 9.1 Tab（最終會有，但本階段先做 Bingo）
- 做得好按鈕 / 感恩日記 / Bingo / 花園 / 獎勵

### 9.2 Bingo 格子分色
- 低飽和莫迪蘭色（不同 source 不同色）
- 格子可顯示小標籤（可選）：自愛 / 習慣 / 核心

---

## 10. Acceptance Tests (你用嚟驗收)

1) **永遠出到板**：無網絡/LLM fail 都要生成 4x4。
2) **零垃圾句**：任務中不出現任何禁詞/抽象句。
3) **有路徑**：最少 4 格明顯是 starter_step→延伸→小成就。
4) **低動機模式**：會以自愛托底，但仍保留少量「習慣起手式」。
5) **高動機模式**：幾乎全習慣相關任務，仍保持小步、不壓迫。

---

## 11. Open Questions (留白，等你後續提供)
- self_growth（自我進步）分類與任務模板
- rewards / garden_growth 的文字回饋規則
