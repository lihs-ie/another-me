# billing パッケージ（Plan / Subscription / Entitlement）

## 永続化戦略

| データ            | ストア                   | 保存形式                         |
|-------------------|--------------------------|----------------------------------|
| Plan               | JSON (`plans.json`)       | アプリ内固定データ（編集頻度低） |
| Subscription       | SQLite (`billing.db`)     | テーブル `subscription`          |
| Entitlement        | SQLite (`billing.db`)     | テーブル `entitlement`           |
| EntitlementUsage   | SQLite (`billing.db`)     | テーブル `entitlement_usage`     |

## 保存形式

### plans.json

```json
{
  "plans": [
    {"planIdentifier": "free", "name": "Free", "trackLimit": 3, "characterLimit": 2, "price": 0, "currency": "USD", "status": "Active"},
    {"planIdentifier": "paid", "name": "Premium", "trackLimit": null, "characterLimit": null, "price": 4.99, "currency": "USD", "status": "Active"}
  ],
  "updatedAt": 1730000000000
}
```

### subscription
- `subscription_identifier` TEXT PRIMARY KEY
- `plan_identifier` TEXT
- `status` TEXT (`Active`|`Expired`|`Grace`|`Canceled`)
- `expires_at` INTEGER
- `grace_period_ends_at` INTEGER NULL
- `offline_grace_period_days` INTEGER
- `receipt_provider` TEXT
- `receipt_transaction_id` TEXT
- `receipt_signature` TEXT
- `last_synced_at` INTEGER

### entitlement
- `entitlement_identifier` TEXT PRIMARY KEY
- `plan_identifier` TEXT
- `subscription_identifier` TEXT NULL
- `status` TEXT (`Active`|`Restricted`)
- `track_limit` INTEGER NULL
- `character_limit` INTEGER NULL

### entitlement_usage
- `entitlement_identifier` TEXT PRIMARY KEY
- `tracks` INTEGER
- `characters` INTEGER

## リポジトリ実装

- `PlanRepository`
  - `all()` → plans.json を読み込み
  - `persist(plan)` → 将来課金プランが増える場合に JSON を上書き

- `SubscriptionRepository`
  - `find(subscriptionIdentifier)` → `SELECT * FROM subscription`
  - `persist(subscription)` → UPSERT

- `EntitlementRepository`
  - `find(entitlementIdentifier)` → JOIN して limits + usage を組み立て
  - `persist(entitlement)` → トランザクションで limits / usage を更新

## 追加メモ

- 外部課金サービス連携（App Store / Google Play / Stripe など）を行う場合は ACL を別途実装する。現行はローカル判定のみ。
- オフライン猶予 `offline_grace_period_days` を持たせ、`canUseOffline` 判定に利用。
