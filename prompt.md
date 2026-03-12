# Event Modeling AI: Iterative Analysis Loop

## Mission
Execute ONE iteration of the Event Modeling analysis state machine. Each run performs a single step, then stops. Run this repeatedly to build progressively detailed, recursive flow models.

---

## State Machine Logic

Execute steps in order. **Stop after completing the first applicable step.**

### State 1: High-Level Analysis Missing
**Condition:** `high-level-analysis.json` does NOT exist
**Action:**
1. Analyze the entire system to identify all high-level use cases
2. Create Event Model following high-level analysis rules:
   - Skip field definitions in elements (empty arrays)
   - Skip specifications (empty arrays)
   - Model complete flow with all slices
   - Focus on business processes and flow structure
3. Write results to `high-level-analysis.json`
4. **STOP - iteration complete**

### State 2: Flows Catalog Missing
**Condition:** `high-level-analysis.json` EXISTS, `flows.json` does NOT exist
**Action:**
1. Read `high-level-analysis.json`
2. Identify all distinct business flows/use cases from the analysis
3. Create `flows.json` with structure:
```json
{
  "flows": [
    {
      "name": "Flow Name (business-focused)",
      "folder": "flow-name-kebab-case",
      "status": "open",
      "description": "Brief description of what this flow does",
      "depth": 0
    }
  ]
}
```
4. **STOP - iteration complete**

### State 3: Flow High-Level Analysis
**Condition:** At least one flow has `status: "open"` AND its folder does NOT contain `high-level-analysis.json`
**Action:**
1. Find the FIRST flow with `status: "open"` that needs high-level analysis
2. Create folder `{folder}/` if it doesn't exist
3. Analyze this specific flow at a high level to discover sub-flows:
   - Skip field definitions in elements (empty arrays)
   - Skip specifications (empty arrays)
   - Model the complete flow structure
   - Identify sub-flows within this flow
4. Write results to `{folder}/high-level-analysis.json`
5. **STOP - iteration complete**

### State 4: Sub-Flows Catalog Missing
**Condition:** A flow has `{folder}/high-level-analysis.json` BUT NOT `{folder}/flows.json`
**Action:**
1. Find the FIRST flow folder with this condition
2. Read `{folder}/high-level-analysis.json`
3. Identify distinct sub-flows from the analysis
4. If sub-flows found, create `{folder}/flows.json`:
```json
{
  "flows": [
    {
      "name": "Sub-Flow Name",
      "folder": "sub-flow-name-kebab-case",
      "status": "open",
      "description": "Brief description",
      "depth": 1
    }
  ]
}
```
5. If NO sub-flows found (this is a leaf flow), create empty `{folder}/flows.json`:
```json
{
  "flows": []
}
```
6. **STOP - iteration complete**

### State 5: Detailed Flow Analysis
**Condition:** A flow has `{folder}/flows.json` with empty array BUT NOT `{folder}/config.json`
**Action:**
1. Find the FIRST flow folder with this condition (it's a leaf flow)
2. Analyze this specific flow in detail:
   - Include ALL field definitions with examples
   - Include specifications (Given/When/Then) from tests
   - Include code references in descriptions
   - Follow complete detailed flow analysis rules
3. Write detailed analysis to `{folder}/config.json`
4. Update parent's `flows.json` to mark this flow's status as `"completed"`
5. **STOP - iteration complete**

### State 6: All Sub-Flows Complete
**Condition:** A flow at depth N has all its sub-flows `"completed"` BUT the parent flow itself is NOT marked `"completed"`
**Action:**
1. Find the FIRST flow where all sub-flows are completed
2. Create `{folder}/config.json` aggregating all sub-flow information
3. Mark this flow as `"completed"` in its parent's `flows.json`
4. **STOP - iteration complete**

### State 7: All Complete
**Condition:** Root `flows.json` EXISTS and ALL flows (recursively) have `status: "completed"`
**Action:**
1. Report: "All flows analyzed recursively. Analysis complete."
2. Output `<promise>COMPLETE</promise>`
3. **STOP - no more work**

---

## Analysis Rules

### High-Level Analysis (State 1)
- **Goal:** Quick overview of the entire system
- **Elements:** Define structure but leave fields empty `[]`
- **Specifications:** Empty arrays `[]`
- **Focus:** Slice types, dependencies, flow sequence, aggregates
- **Output:** `high-level-analysis.json` at project root

### Detailed Flow Analysis (State 3)
- **Goal:** Deep dive into one specific business flow
- **Elements:** Full field definitions with types and examples
- **Specifications:** Extract Given/When/Then from unit tests
- **Code References:** Add in `description` field (classes, packages, modules)
- **Focus:** Data structures, business rules, precise behavior
- **Output:** `{folder}/config.json` inside flow-specific folder

---

## Element Structure Reference

### High-Level Analysis Element (empty fields)
```json
{
  "id": "cmd-add-item",
  "title": "Add Item",
  "type": "COMMAND",
  "fields": [],
  "dependencies": [...],
  "aggregate": "Cart"
}
```

### Detailed Analysis Element (with fields)
```json
{
  "id": "cmd-add-item",
  "title": "Add Item",
  "type": "COMMAND",
  "description": "org.example.cart.commands.AddItemCommand",
  "fields": [
    {
      "name": "itemId",
      "type": "UUID",
      "example": "550e8400-e29b-41d4-a716-446655440000",
      "idAttribute": true,
      "optional": false
    },
    {
      "name": "quantity",
      "type": "Int",
      "example": "3",
      "optional": false
    }
  ],
  "dependencies": [...],
  "aggregate": "Cart"
}
```

---

## JSON Schema Compliance

All output must follow the complete JSON schema defined in CLAUDE.md:
- Valid slice types: `STATE_CHANGE`, `STATE_VIEW`, `AUTOMATION`
- Required element types: `COMMAND`, `EVENT`, `READMODEL`, `SCREEN`, `AUTOMATION`
- Valid field types: `String`, `Boolean`, `Double`, `Decimal`, `Long`, `Custom`, `Date`, `DateTime`, `UUID`, `Int`
- Valid dependency types: `INBOUND`, `OUTBOUND`
- All required fields must be present

---

## Execution Instructions

1. **Read state files** in order:
   - Check `high-level-analysis.json`
   - Check `flows.json`
   - Check flow statuses

2. **Execute ONE state action** based on conditions above

3. **Write output files**:
   - Use Write tool without asking permission
   - Follow exact file naming conventions
   - Ensure valid JSON

4. **STOP** after completing the action
   - Do not continue to next state
   - User will re-run for next iteration

---

## Quality Validation (All States)

Before writing any JSON file:
- ✅ Valid JSON structure (parseable)
- ✅ Follows complete schema from CLAUDE.md
- ✅ Business-focused naming (no technical suffixes)
- ✅ All dependencies reference existing elements
- ✅ No circular dependencies
- ✅ Required fields present for each element type
- ✅ Code references in descriptions (detailed analysis only)

---

## Loop Behavior Summary

**Run 1:** No files → Create `high-level-analysis.json` → Stop
**Run 2:** High-level exists → Create `flows.json` with depth 0 flows → Stop
**Run 3:** First flow "open" → Create `flow-1/high-level-analysis.json` → Stop
**Run 4:** Flow has high-level → Create `flow-1/flows.json` (discover sub-flows) → Stop
**Run 5:** Sub-flow found → Create `flow-1/sub-flow-1/high-level-analysis.json` → Stop
**Run 6:** Sub-flow high-level → Create `flow-1/sub-flow-1/flows.json` (check for deeper flows) → Stop
**Run 7:** No deeper flows (empty array) → Create `flow-1/sub-flow-1/config.json` → Mark completed → Stop
**Run 8:** All sub-flows completed → Create `flow-1/config.json` aggregating sub-flows → Mark flow-1 completed → Stop
**Run N:** All flows recursively completed → Output `<promise>COMPLETE</promise>` → Stop

This creates an incremental, resumable, **recursive** analysis process that builds detailed models layer by layer, discovering flows at multiple depths.