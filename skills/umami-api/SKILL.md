---
name: umami_api
description: Interact with the Umami analytics API to manage websites, retrieve stats, sessions, events, realtime data, and generate reports. Use when the user wants to query website analytics, manage tracked websites, view visitor sessions, get pageview metrics, or create Umami reports.
---

# Umami API – Analytics & Website Management

Manage websites and retrieve analytics data from a self-hosted Umami v2 instance via its REST API.

## Prerequisites

- `UMAMI_API_URL` – Base URL of the Umami instance (e.g. `https://analytics.example.com`)
- `UMAMI_API_TOKEN` – Bearer token for authentication

## Authentication

All requests require the `Authorization: Bearer <token>` header. The token is obtained from `UMAMI_API_TOKEN`.

```bash
# Verify token is valid
curl -s "${UMAMI_API_URL}/api/auth/verify" \
  -H "Authorization: Bearer ${UMAMI_API_TOKEN}" | jq
```

### Helper pattern

Use this base pattern for all API calls:

```bash
UMAMI="${UMAMI_API_URL}/api"
AUTH="Authorization: Bearer ${UMAMI_API_TOKEN}"

# GET request
curl -s "${UMAMI}/<endpoint>" -H "${AUTH}" | jq

# POST request
curl -s -X POST "${UMAMI}/<endpoint>" \
  -H "${AUTH}" \
  -H "Content-Type: application/json" \
  -d '<json-body>' | jq

# DELETE request
curl -s -X DELETE "${UMAMI}/<endpoint>" -H "${AUTH}"
```

## Website Management

### List all websites

```bash
curl -s "${UMAMI}/websites" -H "${AUTH}" | jq
```

Optional query params: `?query=<search>&page=1&pageSize=10&orderBy=name`

### Create a website

```bash
curl -s -X POST "${UMAMI}/websites" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d '{"name":"My Site","domain":"example.com"}' | jq
```

Optional fields: `shareId` (string, enables share URL), `teamId` (string).

### Get / Update / Delete a website

```bash
# Get by ID
curl -s "${UMAMI}/websites/${WEBSITE_ID}" -H "${AUTH}" | jq

# Update
curl -s -X POST "${UMAMI}/websites/${WEBSITE_ID}" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d '{"name":"New Name","domain":"new.example.com"}' | jq

# Delete
curl -s -X DELETE "${UMAMI}/websites/${WEBSITE_ID}" -H "${AUTH}"

# Reset all data for a website
curl -s -X POST "${UMAMI}/websites/${WEBSITE_ID}/reset" -H "${AUTH}"
```

## Website Statistics

All stats endpoints require `startAt` and `endAt` as timestamps in milliseconds. Common filter params: `url`, `referrer`, `browser`, `os`, `device`, `country`, `region`, `city`, `title`, `host`.

### Quick stats summary

```bash
# Last 7 days
START=$(date -d '7 days ago' +%s)000
END=$(date +%s)000

curl -s "${UMAMI}/websites/${WEBSITE_ID}/stats?startAt=${START}&endAt=${END}" \
  -H "${AUTH}" | jq
```

Returns: `pageviews`, `visitors`, `visits`, `bounces`, `totaltime` (each with `value` and `prev`).

### Active visitors (last 5 minutes)

```bash
curl -s "${UMAMI}/websites/${WEBSITE_ID}/active" -H "${AUTH}" | jq
```

### Pageviews over time

```bash
curl -s "${UMAMI}/websites/${WEBSITE_ID}/pageviews?startAt=${START}&endAt=${END}&unit=day&timezone=Europe/Zurich" \
  -H "${AUTH}" | jq
```

Unit options: `year`, `month`, `day`, `hour`, `minute`.

### Metrics breakdown

```bash
# By URL
curl -s "${UMAMI}/websites/${WEBSITE_ID}/metrics?startAt=${START}&endAt=${END}&type=url" \
  -H "${AUTH}" | jq

# By country
curl -s "${UMAMI}/websites/${WEBSITE_ID}/metrics?startAt=${START}&endAt=${END}&type=country" \
  -H "${AUTH}" | jq
```

Type options: `url`, `referrer`, `browser`, `os`, `device`, `country`, `event`.

## Sessions

### List sessions

```bash
curl -s "${UMAMI}/websites/${WEBSITE_ID}/sessions?startAt=${START}&endAt=${END}" \
  -H "${AUTH}" | jq
```

### Session stats

```bash
curl -s "${UMAMI}/websites/${WEBSITE_ID}/sessions/stats?startAt=${START}&endAt=${END}" \
  -H "${AUTH}" | jq
```

### Session details and activity

```bash
# Get session details
curl -s "${UMAMI}/websites/${WEBSITE_ID}/sessions/${SESSION_ID}" \
  -H "${AUTH}" | jq

# Get session activity
curl -s "${UMAMI}/websites/${WEBSITE_ID}/sessions/${SESSION_ID}/activity?startAt=${START}&endAt=${END}" \
  -H "${AUTH}" | jq

# Get session properties
curl -s "${UMAMI}/websites/${WEBSITE_ID}/sessions/${SESSION_ID}/properties" \
  -H "${AUTH}" | jq
```

### Session data

```bash
# Property name counts
curl -s "${UMAMI}/websites/${WEBSITE_ID}/session-data/properties?startAt=${START}&endAt=${END}" \
  -H "${AUTH}" | jq

# Values for a specific property
curl -s "${UMAMI}/websites/${WEBSITE_ID}/session-data/values?startAt=${START}&endAt=${END}&propertyName=region" \
  -H "${AUTH}" | jq

# Weekly session heatmap (by hour/weekday)
curl -s "${UMAMI}/websites/${WEBSITE_ID}/sessions/weekly?startAt=${START}&endAt=${END}&timezone=Europe/Zurich" \
  -H "${AUTH}" | jq
```

## Events

### List events

```bash
curl -s "${UMAMI}/websites/${WEBSITE_ID}/events?startAt=${START}&endAt=${END}" \
  -H "${AUTH}" | jq
```

### Event data

```bash
# Event names and properties
curl -s "${UMAMI}/websites/${WEBSITE_ID}/event-data/events?startAt=${START}&endAt=${END}" \
  -H "${AUTH}" | jq

# Event data fields
curl -s "${UMAMI}/websites/${WEBSITE_ID}/event-data/fields?startAt=${START}&endAt=${END}" \
  -H "${AUTH}" | jq

# Event data values for a specific event/property
curl -s "${UMAMI}/websites/${WEBSITE_ID}/event-data/values?startAt=${START}&endAt=${END}&eventName=button-click&propertyName=id" \
  -H "${AUTH}" | jq

# Event data stats summary
curl -s "${UMAMI}/websites/${WEBSITE_ID}/event-data/stats?startAt=${START}&endAt=${END}" \
  -H "${AUTH}" | jq

# Event time series
curl -s "${UMAMI}/websites/${WEBSITE_ID}/events/series?startAt=${START}&endAt=${END}&unit=day&timezone=Europe/Zurich" \
  -H "${AUTH}" | jq
```

## Realtime

```bash
curl -s "${UMAMI}/realtime/${WEBSITE_ID}?startAt=${START}&endAt=${END}&timezone=Europe/Zurich" \
  -H "${AUTH}" | jq
```

Returns: `urls`, `countries`, `events`, `series` (views/visitors), `referrers`, `totals`.

## Reports

### List / Get / Delete reports

```bash
# List all reports (optionally filter by websiteId)
curl -s "${UMAMI}/reports?websiteId=${WEBSITE_ID}" -H "${AUTH}" | jq

# Get report by ID
curl -s "${UMAMI}/reports/${REPORT_ID}" -H "${AUTH}" | jq

# Delete report
curl -s -X DELETE "${UMAMI}/reports/${REPORT_ID}" -H "${AUTH}"
```

### Create reports

All report POST endpoints accept a JSON body with `websiteId`, `dateRange`, and `timezone`. The `dateRange` object contains: `startDate`, `endDate`, `unit`, `offset`, `num`, `value`.

```bash
# Date range helper (last 7 days, ISO format)
START_ISO=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S.000Z)
END_ISO=$(date -u +%Y-%m-%dT%H:%M:%S.999Z)

DATE_RANGE='"dateRange":{"startDate":"'${START_ISO}'","endDate":"'${END_ISO}'","unit":"day","offset":0,"num":7,"value":"7day"}'
```

#### Insights report

```bash
curl -s -X POST "${UMAMI}/reports/insights" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d '{
    "websiteId":"'${WEBSITE_ID}'",
    "fields":[{"name":"url","type":"string","label":"URL"}],
    "filters":[],
    '"${DATE_RANGE}"',
    "timezone":"Europe/Zurich"
  }' | jq
```

#### Funnel report

```bash
curl -s -X POST "${UMAMI}/reports/funnel" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d '{
    "websiteId":"'${WEBSITE_ID}'",
    "window":60,
    "steps":[{"type":"url","value":"/"},{"type":"url","value":"/contact"}],
    '"${DATE_RANGE}"',
    "timezone":"Europe/Zurich"
  }' | jq
```

#### Retention report

```bash
curl -s -X POST "${UMAMI}/reports/retention" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d '{
    "websiteId":"'${WEBSITE_ID}'",
    '"${DATE_RANGE}"',
    "timezone":"Europe/Zurich"
  }' | jq
```

#### UTM report

```bash
curl -s -X POST "${UMAMI}/reports/utm" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d '{
    "websiteId":"'${WEBSITE_ID}'",
    '"${DATE_RANGE}"',
    "timezone":"Europe/Zurich"
  }' | jq
```

#### Goals report

```bash
curl -s -X POST "${UMAMI}/reports/goals" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d '{
    "websiteId":"'${WEBSITE_ID}'",
    "goals":[{"type":"url","value":"/","goal":100}],
    '"${DATE_RANGE}"',
    "timezone":"Europe/Zurich"
  }' | jq
```

#### Journey report

```bash
curl -s -X POST "${UMAMI}/reports/journey" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d '{
    "websiteId":"'${WEBSITE_ID}'",
    "steps":5,
    '"${DATE_RANGE}"',
    "timezone":"Europe/Zurich"
  }' | jq
```

#### Revenue report

```bash
curl -s -X POST "${UMAMI}/reports/revenue" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d '{
    "websiteId":"'${WEBSITE_ID}'",
    "currency":"USD",
    '"${DATE_RANGE}"',
    "timezone":"Europe/Zurich"
  }' | jq
```

#### Attribution report

```bash
curl -s -X POST "${UMAMI}/reports/attribution" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d '{
    "websiteId":"'${WEBSITE_ID}'",
    "model":"firstClick",
    "steps":[{"type":"event","value":"/"}],
    '"${DATE_RANGE}"',
    "timezone":"Europe/Zurich"
  }' | jq
```

## Common Workflows

### Quick health check

```bash
# Verify auth, list websites, check active visitors for each
curl -s "${UMAMI}/auth/verify" -H "${AUTH}" | jq '.username'
for id in $(curl -s "${UMAMI}/websites" -H "${AUTH}" | jq -r '.data[].id'); do
  echo "=== $(curl -s "${UMAMI}/websites/${id}" -H "${AUTH}" | jq -r '.name') ==="
  curl -s "${UMAMI}/websites/${id}/active" -H "${AUTH}" | jq '.visitors'
done
```

### 7-day overview for a website

```bash
START=$(date -d '7 days ago' +%s)000
END=$(date +%s)000
echo "--- Stats ---"
curl -s "${UMAMI}/websites/${WEBSITE_ID}/stats?startAt=${START}&endAt=${END}" -H "${AUTH}" | jq
echo "--- Top Pages ---"
curl -s "${UMAMI}/websites/${WEBSITE_ID}/metrics?startAt=${START}&endAt=${END}&type=url&limit=10" -H "${AUTH}" | jq
echo "--- Top Countries ---"
curl -s "${UMAMI}/websites/${WEBSITE_ID}/metrics?startAt=${START}&endAt=${END}&type=country&limit=10" -H "${AUTH}" | jq
echo "--- Top Referrers ---"
curl -s "${UMAMI}/websites/${WEBSITE_ID}/metrics?startAt=${START}&endAt=${END}&type=referrer&limit=10" -H "${AUTH}" | jq
```

## Troubleshooting

| Issue | Resolution |
|-------|-----------|
| `401 Unauthorized` | Token expired or invalid — re-authenticate or regenerate API token |
| Empty responses | Check `startAt`/`endAt` are in milliseconds, not seconds |
| No active visitors | Endpoint only counts visitors within last 5 minutes |
| `404 Not Found` | Verify `WEBSITE_ID` exists with `GET /api/websites` |

## Additional Resources

- For detailed endpoint parameters and response schemas, see [reference.md](reference.md)
- Umami API docs: https://v2.umami.is/docs/api
