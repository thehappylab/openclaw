# Umami API – Full Endpoint Reference

Complete reference for all Umami v2 API endpoints. The main [SKILL.md](SKILL.md) covers common workflows and quick examples.

## Authentication

### POST /api/auth/login

Get a bearer token (alternative to using `UMAMI_API_TOKEN`).

**Request body:**

```json
{ "username": "your-username", "password": "your-password" }
```

**Response:**

```json
{
  "token": "eyTMjU2IiwiY...4Q0JDLUhWxnIjoiUE_A",
  "user": {
    "id": "uuid",
    "username": "admin",
    "role": "admin",
    "createdAt": "2000-01-01T00:00:00.000Z",
    "isAdmin": true
  }
}
```

### POST /api/auth/verify

Verify if a token is still valid. Returns user object on success.

---

## Websites CRUD

### GET /api/websites

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `query` | string | — | Search text |
| `page` | number | 1 | Page number |
| `pageSize` | number | 10 | Results per page |
| `orderBy` | string | `name` | Order by column |

### POST /api/websites

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Display name |
| `domain` | string | yes | Full domain |
| `shareId` | string | no | Unique string to enable share URL. `null` to unshare |
| `teamId` | string | no | Team ID to create under |

### GET /api/websites/:websiteId

Returns full website object.

### POST /api/websites/:websiteId

Update a website. Accepts `name`, `domain`, `shareId`.

### DELETE /api/websites/:websiteId

Deletes a website.

### POST /api/websites/:websiteId/reset

Resets a website by removing all its data.

---

## Website Statistics

All endpoints below accept these **common filter params** as query parameters:

| Param | Description |
|-------|-------------|
| `url` | Filter by URL path |
| `referrer` | Filter by referrer |
| `title` | Filter by page title |
| `host` | Filter by hostname |
| `query` | Filter by query string |
| `event` | Filter by event name |
| `os` | Filter by operating system |
| `browser` | Filter by browser |
| `device` | Filter by device type |
| `country` | Filter by country code |
| `region` | Filter by region/state |
| `city` | Filter by city |

### GET /api/websites/:websiteId/active

No parameters. Returns `{ "visitors": <count> }` (unique visitors in last 5 min).

### GET /api/websites/:websiteId/stats

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `startAt` | number | yes | Start timestamp (ms) |
| `endAt` | number | yes | End timestamp (ms) |
| + common filters | | | |

**Response fields:**

| Field | Description |
|-------|-------------|
| `pageviews.value` / `.prev` | Page hits (current / previous period) |
| `visitors.value` / `.prev` | Unique visitors |
| `visits.value` / `.prev` | Number of sessions |
| `bounces.value` / `.prev` | Single-page visitors |
| `totaltime.value` / `.prev` | Time spent on site (seconds) |

### GET /api/websites/:websiteId/pageviews

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `startAt` | number | yes | Start timestamp (ms) |
| `endAt` | number | yes | End timestamp (ms) |
| `unit` | string | yes | `year`, `month`, `day`, `hour`, `minute` |
| `timezone` | string | yes | e.g. `Europe/Zurich` |
| + common filters | | | |

**Response:** `{ "pageviews": [{x, y}], "sessions": [{x, y}] }`

### GET /api/websites/:websiteId/metrics

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `startAt` | number | yes | Start timestamp (ms) |
| `endAt` | number | yes | End timestamp (ms) |
| `type` | string | yes | `url`, `referrer`, `browser`, `os`, `device`, `country`, `event` |
| `limit` | number | no | Max results (default 500) |
| + common filters | | | |

**Response:** `[{ "x": "<value>", "y": <count> }]`

### GET /api/websites/:websiteId/events/series

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `startAt` | number | yes | Start timestamp (ms) |
| `endAt` | number | yes | End timestamp (ms) |
| `unit` | string | yes | `year`, `month`, `day`, `hour` |
| `timezone` | string | yes | e.g. `Europe/Zurich` |
| + common filters | | | |

**Response:** `[{ "x": "<event-name>", "t": "<timestamp>", "y": <count> }]`

---

## Events

### GET /api/websites/:websiteId/events

| Param | Type | Required |
|-------|------|----------|
| `startAt` | number | yes |
| `endAt` | number | yes |
| `page` | number | no (default 1) |
| `pageSize` | number | no |
| `orderBy` | string | no |
| `query` | string | no |

**Response:** Paginated list with `id`, `websiteId`, `sessionId`, `urlPath`, `eventType`, `eventName`, `createdAt`.

### GET /api/websites/:websiteId/event-data/events

| Param | Type | Required |
|-------|------|----------|
| `startAt` | number | yes |
| `endAt` | number | yes |
| `event` | string | no |

**Response:** `[{ "eventName", "propertyName", "dataType", "total" }]`

### GET /api/websites/:websiteId/event-data/fields

| Param | Type | Required |
|-------|------|----------|
| `startAt` | number | yes |
| `endAt` | number | yes |

**Response:** `[{ "propertyName", "dataType", "value", "total" }]`

### GET /api/websites/:websiteId/event-data/values

| Param | Type | Required |
|-------|------|----------|
| `startAt` | number | yes |
| `endAt` | number | yes |
| `eventName` | string | yes |
| `propertyName` | string | yes |

**Response:** `[{ "value", "total" }]`

### GET /api/websites/:websiteId/event-data/stats

| Param | Type | Required |
|-------|------|----------|
| `startAt` | number | yes |
| `endAt` | number | yes |

**Response:** `[{ "events", "fields", "records" }]`

---

## Sessions

### GET /api/websites/:websiteId/sessions

| Param | Type | Required |
|-------|------|----------|
| `startAt` | number | yes |
| `endAt` | number | yes |
| `page` | number | no (default 1) |
| `pageSize` | number | no |
| `orderBy` | string | no |
| `query` | string | no |

**Response fields per session:** `id`, `websiteId`, `hostname`, `browser`, `os`, `device`, `screen`, `language`, `country`, `region`, `city`, `firstAt`, `lastAt`, `visits`, `views`.

### GET /api/websites/:websiteId/sessions/stats

Same filter params as website stats. Returns: `pageviews`, `visitors`, `visits`, `countries`, `events` (each with `value`).

### GET /api/websites/:websiteId/sessions/:sessionId

No params. Returns full session object including `subdivision1`, `totaltime`.

### GET /api/websites/:websiteId/sessions/:sessionId/activity

| Param | Type | Required |
|-------|------|----------|
| `startAt` | number | yes |
| `endAt` | number | yes |

**Response:** `[{ "eventType", "urlPath", "urlQuery", "eventName", "createdAt", "referrerDomain", "eventId", "visitId" }]`

### GET /api/websites/:websiteId/sessions/:sessionId/properties

No params. Returns `[{ "dataKey", "dataType", "stringValue", "numberValue", "dateValue" }]`.

### GET /api/websites/:websiteId/session-data/properties

| Param | Type | Required |
|-------|------|----------|
| `startAt` | number | yes |
| `endAt` | number | yes |

**Response:** `[{ "propertyName", "total" }]`

### GET /api/websites/:websiteId/session-data/values

| Param | Type | Required |
|-------|------|----------|
| `startAt` | number | yes |
| `endAt` | number | yes |
| `propertyName` | string | yes |

**Response:** `[{ "value", "total" }]`

### GET /api/websites/:websiteId/sessions/weekly

| Param | Type | Required |
|-------|------|----------|
| `startAt` | number | yes |
| `endAt` | number | yes |
| `timezone` | string | yes |

**Response:** 7x24 matrix (weekday x hour) with session counts.

---

## Realtime

### GET /api/realtime/:websiteId

| Param | Type | Required |
|-------|------|----------|
| `startAt` | number | yes |
| `endAt` | number | yes |
| `timezone` | string | yes |

**Response fields:**

| Field | Description |
|-------|-------------|
| `urls` | Map of URL paths to visit counts |
| `countries` | Map of country codes to counts |
| `referrers` | Map of referrer domains to counts |
| `events` | Array of recent event objects |
| `series.views` | Time series of pageviews `[{x, y}]` |
| `series.visitors` | Time series of visitors `[{x, y}]` |
| `totals` | `{ visitors, views, events, countries }` |
| `timestamp` | Server timestamp (ms) |

---

## Reports

All report POST endpoints share a common `dateRange` object:

```json
{
  "startDate": "2025-01-01T00:00:00.000Z",
  "endDate": "2025-01-07T23:59:59.999Z",
  "unit": "day",
  "offset": 0,
  "num": 7,
  "value": "7day"
}
```

### GET /api/reports

| Param | Type | Required |
|-------|------|----------|
| `websiteId` | string | no |

Returns paginated list of saved reports.

### GET /api/reports/:reportId

Returns report details with parsed `parameters` object.

### DELETE /api/reports/:reportId

Deletes a report.

### GET /api/reports/revenue

| Param | Type | Required |
|-------|------|----------|
| `websiteId` | string | yes |
| `startDate` | string | yes |
| `endDate` | string | yes |

Returns list of currencies: `[{ "currency": "EUR" }]`.

### POST /api/reports/insights

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `websiteId` | string | yes | |
| `dateRange` | object | yes | |
| `timezone` | string | yes | |
| `fields` | array | yes | Min 1. `{ name, type, label }` |
| `filters` | array | yes | Can be empty |

Field name options: `url`, `referrer`, `browser`, `os`, `device`, `country`, `region`, `city`, `language`, `event`.

### POST /api/reports/funnel

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `websiteId` | string | yes | |
| `dateRange` | object | yes | |
| `timezone` | string | yes | |
| `window` | number | yes | Minutes (e.g. 60) |
| `steps` | array | yes | Min 2. `{ type, value }` |

Step type: `url` or `event`.

### POST /api/reports/retention

| Param | Type | Required |
|-------|------|----------|
| `websiteId` | string | yes |
| `dateRange` | object | yes |
| `timezone` | string | yes |

### POST /api/reports/utm

| Param | Type | Required |
|-------|------|----------|
| `websiteId` | string | yes |
| `dateRange` | object | yes |
| `timezone` | string | yes |

Returns: `utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term` (each a map of value to count).

### POST /api/reports/goals

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `websiteId` | string | yes | |
| `dateRange` | object | yes | |
| `timezone` | string | yes | |
| `goals` | array | yes | Min 1. `{ type, value, goal }` |

Goal type: `url` or `event`.

### POST /api/reports/journey

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `websiteId` | string | yes | |
| `dateRange` | object | yes | |
| `timezone` | string | yes | |
| `steps` | number | yes | 3–7 |
| `startStep` | string | no | |
| `endStep` | string | no | |

### POST /api/reports/revenue

| Param | Type | Required |
|-------|------|----------|
| `websiteId` | string | yes |
| `dateRange` | object | yes |
| `timezone` | string | yes |
| `currency` | string | yes |

Returns: `chart`, `country`, `total`, `table`.

### POST /api/reports/attribution

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `websiteId` | string | yes | |
| `dateRange` | object | yes | |
| `timezone` | string | yes | |
| `model` | string | yes | `firstClick` or `lastClick` |
| `steps` | array | yes | Single step. `{ type, value }` |

Returns: `paidAds`, `referrer`, `utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term`, `total`.

---

## Sending Stats (Tracking)

### POST /api/send

Send events from server-side code. **No auth required**, but requires a valid `User-Agent` header.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | Always `"event"` |
| `payload.website` | string | yes | Website ID |
| `payload.url` | string | yes | Page URL path |
| `payload.hostname` | string | yes | Hostname |
| `payload.language` | string | no | e.g. `en-US` |
| `payload.referrer` | string | no | Referrer URL |
| `payload.screen` | string | no | e.g. `1920x1080` |
| `payload.title` | string | no | Page title |
| `payload.name` | string | no | Custom event name |
| `payload.data` | object | no | Custom event data |
