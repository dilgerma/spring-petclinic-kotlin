# Event Modeling AI: Iterative Analysis Loop

## Mission
Execute ONE iteration of the Event Modeling analysis state machine. Each run performs a single step, then stops. Run this repeatedly to build progressively detailed, recursive flow models.

---

## State Machine Logic

Execute steps in order. **Stop after completing the first applicable step.**

### State 1: High-Level Analysis Missing
**Condition:** `analysis/high-level-analysis.json` does NOT exist
**Action:**
1. Analyze the entire system to identify all high-level use cases
2. Create Event Model following high-level analysis rules:
   - Skip field definitions in elements (empty arrays)
   - Skip specifications (empty arrays)
   - Model complete flow with all slices
   - Focus on business processes and flow structure
3. Create `analysis/` folder if it doesn't exist
4. Write results to `analysis/high-level-analysis.json`
5. **STOP - iteration complete**

### State 2: Flows Catalog Missing
**Condition:** `analysis/high-level-analysis.json` EXISTS, `analysis/flows.json` does NOT exist
**Action:**
1. Read `analysis/high-level-analysis.json`
2. Identify all distinct business flows/use cases from the analysis
3. Create `analysis/flows.json` with structure:
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
2. Create folder `analysis/{folder}/` if it doesn't exist
3. Analyze this specific flow at a high level to discover sub-flows:
   - Skip field definitions in elements (empty arrays)
   - Skip specifications (empty arrays)
   - Model the complete flow structure
   - Identify sub-flows within this flow
4. Write results to `analysis/{folder}/high-level-analysis.json`
5. **STOP - iteration complete**

### State 4: Sub-Flows Catalog Missing
**Condition:** A flow has `analysis/{folder}/high-level-analysis.json` BUT NOT `analysis/{folder}/flows.json`
**Action:**
1. Find the FIRST flow folder with this condition
2. Read `analysis/{folder}/high-level-analysis.json`
3. Identify distinct sub-flows from the analysis
4. If sub-flows found, create `analysis/{folder}/flows.json`:
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
5. If NO sub-flows found (this is a leaf flow), create empty `analysis/{folder}/flows.json`:
```json
{
  "flows": []
}
```
6. **STOP - iteration complete**

### State 5: Detailed Flow Analysis
**Condition:** A flow has `analysis/{folder}/flows.json` with empty array BUT NOT `analysis/{folder}/config.json`
**Action:**
1. Find the FIRST flow folder with this condition (it's a leaf flow)
2. Analyze this specific flow in detail:
   - Include ALL field definitions with examples
   - Include specifications (Given/When/Then) from tests
   - Include code references in descriptions
   - Follow complete detailed flow analysis rules
3. Write detailed analysis to `analysis/{folder}/config.json`
4. Update parent's `analysis/flows.json` to mark this flow's status as `"completed"`
5. **STOP - iteration complete**

### State 6: All Sub-Flows Complete
**Condition:** A flow at depth N has all its sub-flows `"completed"` BUT the parent flow itself is NOT marked `"completed"`
**Action:**
1. Find the FIRST flow where all sub-flows are completed
2. Create `analysis/{folder}/config.json` aggregating all sub-flow information
3. Mark this flow as `"completed"` in its parent's `analysis/flows.json`
4. **STOP - iteration complete**

### State 7: All Complete
**Condition:** Root `analysis/flows.json` EXISTS and ALL flows (recursively) have `status: "completed"`
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
- **Output:** `analysis/high-level-analysis.json` in analysis folder

### Detailed Flow Analysis (State 5)
- **Goal:** Deep dive into one specific business flow
- **Elements:** Full field definitions with types and examples
- **Specifications:** Extract Given/When/Then from unit tests
- **Code References:** Add in `description` field (classes, packages, modules)
- **Focus:** Data structures, business rules, precise behavior
- **Output:** `analysis/{folder}/config.json` inside flow-specific folder within analysis

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

All output must follow this complete JSON schema:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "slices": {
      "type": "array",
      "items": { "$ref": "#/$defs/Slice" }
    }
  },
  "required": ["slices"],
  "additionalProperties": false,

  "$defs": {
    "Slice": {
      "type": "object",
      "properties": {
        "id": { "type": "string" },
        "status": {
          "type": "string",
          "enum": ["Created", "Done", "InProgress"]
        },
        "index": { "type": "integer" },
        "title": { "type": "string" },
        "context": { "type": "string" },
        "sliceType": {
          "type": "string",
          "enum": ["STATE_CHANGE", "STATE_VIEW", "AUTOMATION"]
        },
        "commands": {
          "type": "array",
          "items": { "$ref": "#/$defs/Element" }
        },
        "events": {
          "type": "array",
          "items": { "$ref": "#/$defs/Element" }
        },
        "readmodels": {
          "type": "array",
          "items": { "$ref": "#/$defs/Element" }
        },
        "screens": {
          "type": "array",
          "items": { "$ref": "#/$defs/Element" }
        },
        "screenImages": {
          "type": "array",
          "items": { "$ref": "#/$defs/ScreenImage" }
        },
        "processors": {
          "type": "array",
          "items": { "$ref": "#/$defs/Element" }
        },
        "tables": {
          "type": "array",
          "items": { "$ref": "#/$defs/Table" }
        },
        "specifications": {
          "type": "array",
          "items": { "$ref": "#/$defs/Specification" }
        },
        "actors": {
          "type": "array",
          "items": { "$ref": "#/$defs/Actor" }
        },
        "aggregates": {
          "type": "array",
          "items": { "type": "string" }
        }
      },
      "required": [
        "id",
        "title",
        "sliceType",
        "commands",
        "events",
        "readmodels",
        "screens",
        "processors",
        "tables",
        "specifications"
      ],
      "additionalProperties": false
    },

    "Element": {
      "type": "object",
      "properties": {
        "groupId": { "type": "string" },
        "id": { "type": "string" },
        "tags": {
          "type": "array",
          "items": { "type": "string" }
        },
        "domain": { "type": "string" },
        "modelContext": { "type": "string" },
        "context": {
          "type": "string",
          "enum": ["INTERNAL", "EXTERNAL"]
        },
        "slice": { "type": "string" },
        "title": { "type": "string" },
        "fields": {
          "type": "array",
          "items": { "$ref": "#/$defs/Field" }
        },
        "type": {
          "type": "string",
          "enum": ["COMMAND", "EVENT", "READMODEL", "SCREEN", "AUTOMATION"]
        },
        "description": { "type": "string" },
        "aggregate": { "type": "string" },
        "aggregateDependencies": {
          "type": "array",
          "items": { "type": "string" }
        },
        "dependencies": {
          "type": "array",
          "items": { "$ref": "#/$defs/Dependency" }
        },
        "apiEndpoint": { "type": "string" },
        "service": {
          "type": ["string", "null"]
        },
        "createsAggregate": { "type": "boolean" },
        "triggers": {
          "type": "array",
          "items": { "type": "string" }
        },
        "sketched": { "type": "boolean" },
        "prototype": { "type": "object" },
        "listElement": { "type": "boolean" }
      },
      "required": ["id", "title", "fields", "type", "dependencies"],
      "additionalProperties": false
    },

    "ScreenImage": {
      "type": "object",
      "properties": {
        "id": { "type": "string" },
        "title": { "type": "string" },
        "url": { "type": "string" }
      },
      "required": ["id", "title"],
      "additionalProperties": false
    },

    "Table": {
      "type": "object",
      "properties": {
        "id": { "type": "string" },
        "title": { "type": "string" },
        "fields": {
          "type": "array",
          "items": { "$ref": "#/$defs/Field" }
        }
      },
      "required": ["id", "title", "fields"],
      "additionalProperties": false
    },

    "Specification": {
      "type": "object",
      "properties": {
        "vertical": { "type": "boolean" },
        "id": { "type": "string" },
        "sliceName": { "type": "string" },
        "title": { "type": "string" },
        "given": {
          "type": "array",
          "items": { "$ref": "#/$defs/SpecificationStep" }
        },
        "when": {
          "type": "array",
          "items": { "$ref": "#/$defs/SpecificationStep" }
        },
        "then": {
          "type": "array",
          "items": { "$ref": "#/$defs/SpecificationStep" }
        },
        "comments": {
          "type": "array",
          "items": { "$ref": "#/$defs/Comment" }
        },
        "linkedId": { "type": "string" }
      },
      "required": ["id", "title", "given", "when", "then", "linkedId"],
      "additionalProperties": false
    },

    "SpecificationStep": {
      "type": "object",
      "properties": {
        "title": { "type": "string" },
        "tags": {
          "type": "array",
          "items": { "type": "string" }
        },
        "examples": {
          "type": "array",
          "items": { "type": "object" }
        },
        "id": { "type": "string" },
        "index": { "type": "integer" },
        "specRow": { "type": "integer" },
        "type": {
          "type": "string",
          "enum": ["SPEC_EVENT", "SPEC_COMMAND", "SPEC_READMODEL", "SPEC_ERROR"]
        },
        "fields": {
          "type": "array",
          "items": { "$ref": "#/$defs/Field" }
        },
        "linkedId": { "type": "string" },
        "expectEmptyList": { "type": "boolean" }
      },
      "required": ["title", "id", "type"],
      "additionalProperties": false
    },

    "Comment": {
      "type": "object",
      "properties": {
        "description": { "type": "string" }
      },
      "required": ["description"],
      "additionalProperties": false
    },

    "Actor": {
      "type": "object",
      "properties": {
        "name": { "type": "string" },
        "authzRequired": { "type": "boolean" }
      },
      "required": ["name", "authzRequired"],
      "additionalProperties": false
    },

    "Dependency": {
      "type": "object",
      "properties": {
        "id": { "type": "string" },
        "type": {
          "type": "string",
          "enum": ["INBOUND", "OUTBOUND"]
        },
        "title": { "type": "string" },
        "elementType": {
          "type": "string",
          "enum": ["EVENT", "COMMAND", "READMODEL", "SCREEN", "AUTOMATION"]
        }
      },
      "required": ["id", "type", "title", "elementType"],
      "additionalProperties": false
    },

    "Field": {
      "type": "object",
      "properties": {
        "name": { "type": "string" },
        "type": {
          "type": "string",
          "enum": [
            "String",
            "Boolean",
            "Double",
            "Decimal",
            "Long",
            "Custom",
            "Date",
            "DateTime",
            "UUID",
            "Int"
          ]
        },
        "example": {
          "oneOf": [
            { "type": "string" },
            { "type": "object" }
          ]
        },
        "subfields": {
          "type": "array",
          "items": { "$ref": "#/$defs/Field" }
        },
        "mapping": { "type": "string" },
        "optional": { "type": "boolean" },
        "technicalAttribute": { "type": "boolean" },
        "generated": { "type": "boolean" },
        "idAttribute": { "type": "boolean" },
        "schema": { "type": "string" },
        "cardinality": {
          "type": "string",
          "enum": ["List", "Single"]
        }
      },
      "required": ["name", "type"],
      "additionalProperties": false
    }
  }
}
```

---

## Execution Instructions

1. **Read state files** in order:
   - Check `analysis/high-level-analysis.json`
   - Check `analysis/flows.json`
   - Check flow statuses in `analysis/{folder}/flows.json`

2. **Execute ONE state action** based on conditions above

3. **Write output files**:
   - Use Write tool without asking permission
   - All files go in `analysis/` folder or subfolders
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

**Run 1:** No files → Create `analysis/high-level-analysis.json` → Stop
**Run 2:** High-level exists → Create `analysis/flows.json` with depth 0 flows → Stop
**Run 3:** First flow "open" → Create `analysis/flow-1/high-level-analysis.json` → Stop
**Run 4:** Flow has high-level → Create `analysis/flow-1/flows.json` (discover sub-flows) → Stop
**Run 5:** Sub-flow found → Create `analysis/flow-1/sub-flow-1/high-level-analysis.json` → Stop
**Run 6:** Sub-flow high-level → Create `analysis/flow-1/sub-flow-1/flows.json` (check for deeper flows) → Stop
**Run 7:** No deeper flows (empty array) → Create `analysis/flow-1/sub-flow-1/config.json` → Mark completed → Stop
**Run 8:** All sub-flows completed → Create `analysis/flow-1/config.json` aggregating sub-flows → Mark flow-1 completed → Stop
**Run N:** All flows recursively completed → Output `<promise>COMPLETE</promise>` → Stop

This creates an incremental, resumable, **recursive** analysis process that builds detailed models layer by layer, discovering flows at multiple depths. All analysis files are organized within the `analysis/` folder.