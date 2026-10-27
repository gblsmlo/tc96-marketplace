---
type: regex
target: trace
match: not_contains
pattern: '("name":"(Read|Grep)","input":\{[^}]*|"name":"Bash","input":\{"command":"[^"]*(cat|head|tail|less|sed|grep|awk|nl)\s[^"]*)(src/|\.diff)[^}]*\}[^\n]*"parent_tool_use_id":null'
---
