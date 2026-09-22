---
titulo: Claude API Docs
---

# Agent Skills (Tool Use)

Agent Skills in the Claude API are primarily implemented through **Tool Use** (also known as Function Calling). This allows Claude to interact with external tools, APIs, and functions to perform tasks that go beyond text generation, such as querying databases, performing calculations, or interacting with web services.

For the most up-to-date details, refer to the [Official Tool Use Documentation](https://docs.anthropic.com/en/docs/build-with-claude/tool-use).

## Overview

Tool use follows a structured cycle between the model and the client application:

1. **Definition:** You provide Claude with a list of tools (definitions) that describe what the tool does and its input schema.
2. **Call:** Claude determines if a tool is needed. If so, it stops and requests a tool call with specific arguments.
3. **Execution:** Your application executes the tool locally using the provided arguments.
4. **Response:** You send the tool's output back to Claude.
5. **Final Answer:** Claude uses the tool's result to formulate a final response or decide if another tool call is needed.

## Defining a Tool

Tools are defined using a JSON schema that includes a name, description, and an `input_schema`.

### Example Tool Definition

```json
{
 "name": "get_weather",
 "description": "Get the current weather for a specific location",
 "input_schema": {
 "type": "object",
 "properties": {
 "location": {
 "type": "string",
 "description": "The city and state, e.g. San Francisco, CA"
 },
 "unit": {
 "type": "string",
 "enum": ["celsius", "fahrenheit"],
 "description": "The unit of temperature to return"
 }
 },
 "required": ["location"]
 }
}
```

## Implementation Example (Node.js)

Using the official Anthropic SDK (`@anthropic-ai/sdk`).

### Step 1: Initialize the Client and Call Claude

```typescript
import Anthropic from '@anthropic-ai/sdk';

const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
});

async function main {
 const response = await anthropic.messages.create({
 model: "claude-3-5-sonnet-20240620",
 max_tokens: 1024,
 tools: [
 {
 name: "get_weather",
 description: "Get the current weather in a given location",
 input_schema: {
 type: "object",
 properties: {
 location: { type: "string", description: "The city and state, e.g. San Francisco, CA" },
 },
 required: ["location"],
 },
 }
 ],
 messages: [{ role: "user", content: "What is the weather in San Francisco?" }],
 });

 console.log(JSON.stringify(response.content, null, 2));
}

main;
```

### Step 2: Handle the Tool Use Block

Claude will return a `tool_use` block if it decides to use the tool:

```typescript
// Example response content from Claude:
// [
// {
// "type": "tool_use",
// "id": "toolu_01A09q902dg902dg12345",
// "name": "get_weather",
// "input": { "location": "San Francisco, CA" }
// }
// ]

if (response.stop_reason === "tool_use") {
 const toolCall = response.content.find(block => block.type === "tool_use");

 if (toolCall) {
 // 1. Execute your local function
 const result = await myLocalWeatherFunction(toolCall.input.location);

 // 2. Send the result back to Claude
 const finalResponse = await anthropic.messages.create({
 model: "claude-3-5-sonnet-20240620",
 max_tokens: 1024,
 tools: [...], // Same tools list as before
 messages: [
 { role: "user", content: "What is the weather in San Francisco?" },
 { role: "assistant", content: response.content },
 {
 role: "user",
 content: [
 {
 type: "tool_result",
 tool_use_id: toolCall.id,
 content: JSON.stringify(result),
 }
 ]
 }
 ],
 });

 console.log(finalResponse.content[0].text);
 }
}
```

## Key Considerations

- **Model Selection:** Use Claude 3.5 Sonnet or Claude 3 Opus for complex tool-use tasks.
- **Error Handling:** Always handle cases where Claude might provide invalid JSON or hallucinate tool arguments.
- **Forced Tool Use:** You can force Claude to use a specific tool using the `tool_choice` parameter.
 - `{"type": "auto"}` (Default)
 - `{"type": "any"}` (Forces at least one tool call)
 - `{"type": "tool", "name": "specific_tool_name"}` (Forces a specific tool)

## Best Practices for Agent Skills (Tool Use)

Implementing tools effectively requires careful design and structured handling. Here are the core best practices recommended by Anthropic:

### 1. Descriptive Naming and Documentation
- **Use Clear Names:** Tool names should be descriptive (e.g., `calculate_mortgage` instead of `tool_1`).
- **Detailed Descriptions:** The `description` field is the primary signal for Claude. Clearly explain **what** the tool does and **when** to use it.
- **Explain Parameters:** Each property in the `input_schema` should have its own `description` clarifying the expected format.

### 2. Schema Precision
- **Use Required Fields:** Explicitly list which parameters are `required`. This prevents Claude from omitting essential data.
- **Constraint-Rich Schemas:** Use JSON schema constraints like `enum`, `minimum`, `maximum`, and `pattern` (regex) to narrow down the model's choices.

```json
{
 "name": "reschedule_meeting",
 "input_schema": {
 "type": "object",
 "properties": {
 "priority": { "type": "string", "enum": ["high", "medium", "low"] },
 "new_date": { "type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$" }
 }
 }
}
```

### 3. Minimize Tool Counts
- **Avoid Overlap:** Don't provide multiple tools that do the same thing. This confuses the model.
- **Logical Grouping:** Keep the tool list relevant to the current context. Providing 50 tools in one call increases latency and risk of errors.

### 4. Robust Error Handling
- **Tool-Side Errors:** If a tool fails (e.g., API timeout), return a descriptive error message in the `tool_result` rather than crashing the loop. Claude can often recognize the error and retry or explain the issue.
- **Validation Errors:** If Claude provides malformed arguments, tell it what was wrong (e.g., "The 'date' provided was not in YYYY-MM-DD format. Please try again.").

### 5. Prompting for Tool Use
- **System Prompts:** Use the system prompt to give Claude a "persona" that understands its tools.
 - *Example:* "You are a specialized support agent with access to database tools. Always check the customer's ID before processing a refund."
- **Contextual Clues:** Mention specific tools in your prompt if you want to guide Claude toward using them.

### 6. Security and Safety
- **Human-in-the-Loop:** For sensitive actions (deleting data, sending emails, processing payments), always require a human confirmation step before executing the tool locally.
- **Input Sanitization:** Treat Claude's tool arguments as untrusted user input. Sanitize and validate them before passing them to internal systems.

## Official References

- [Tool Use Best Practices](https://docs.anthropic.com/en/docs/build-with-claude/tool-use#best-practices)
- [Introduction to Tool Use](https://docs.anthropic.com/en/docs/build-with-claude/tool-use)
- [Tool Use Examples](https://docs.anthropic.com/en/docs/build-with-claude/tool-use-examples)
- [Computer Use (Beta)](https://docs.anthropic.com/en/docs/build-with-claude/computer-use) - A specialized skill allowing Claude to interact with a desktop environment.
