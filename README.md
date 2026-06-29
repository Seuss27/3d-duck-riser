# 3D Duck Riser - AI Agent Loop Proof of Concept

## Overview

This repository serves as a manual testing ground for a multi-stage AI agent pipeline. The primary objective is to validate persona behavior, prompt engineering, and data handoffs before integrating these components into a fully autonomous, stateful agentic framework (such as LangGraph).

The test case is an end-to-end workflow generating a parametric, 3D-printable "choir-style" display riser for cruise ducks—moving from initial user requirements to a final, sliced fabrication file without manual modeling.

## Architecture & Workflow

The workflow simulates a multi-agent loop relying on two distinct AI personas and an intermediate structured data handoff:

1. **Requirements Engineer Persona:** Conducts a guided, one-question-at-a-time interview with the user to gather dimensional constraints, print capacity, and structural requirements.
2. **Structured Handoff:** The interview terminates by outputting a strictly formatted JSON specification block.
3. **OpenSCAD Developer Persona:** Ingests the structured JSON payload to write a parametric OpenSCAD script.
4. **Compilation & Slicing:** The `.scad` script is compiled to an `.stl` mesh and subsequently sliced into `.3mf` for 3D printing.

## Repository Structure

    .
    ├── prompts/
    │   ├── 01_interview_prompt.md      # Persona 1: Requirements gathering and JSON formatting
    │   └── 02_scad_prompt.md           # Persona 2: Ingests JSON to generate OpenSCAD code
    ├── requirements/
    │   └── modular_amphitheater_cruise_duck_riser.json  # The intermediate structured payload
    ├── scad/
    │   ├── modular_cruise_duck_riser_v2.scad   # Generated OpenSCAD code
    │   └── modular_cruise_duck_riser_v3.scad   # Refined iterations
    ├── stl/
    │   ├── modular_cruise_duck_riser_v2.stl    # Compiled meshes ready for slicing
    │   └── modular_cruise_duck_riser_v3.stl
    ├── slicer/
    │   ├── modular_cruise_duck_riser_v2.3mf    # PrusaSlicer/SuperSlicer project files
    │   └── modular_cruise_duck_riser_v3.3mf
    └── Print Recommendations.md        # Printing specifications (no-support, orientation, etc.)

## How to Run the Manual Loop

### Phase 1: Requirements Gathering

1. Open a new context window with your preferred LLM.
2. Paste the contents of `prompts/01_interview_prompt.md`.
3. Answer the model's questions one at a time. Provide parameters like duck footprint dimensions, tier count, and printer bed size.
4. Once the model confirms it has enough data, type `GENERATE`.
5. Save the resulting JSON output into the `requirements/` directory.

### Phase 2: Code Generation

1. Start a new, clean context window to simulate a separate agent node.
2. Paste the contents of `prompts/02_scad_prompt.md` immediately followed by the JSON generated in Phase 1.
3. Save the resulting code output to the `scad/` directory as a `.scad` file.

### Phase 3: Compilation and Fabrication

1. Open the generated `.scad` file in OpenSCAD.
2. Render the model (F6) and export it as an STL (F7) into the `stl/` directory.
3. Import the STL into your slicer.
4. *Critical:* Refer to `Print Recommendations.md` for specific slicing parameters (e.g., printing orientation, 45-degree self-supporting infill strategies, 0.25mm dovetail clearances).
5. Print the `.gcode`. Standard PLA is highly recommended for standard indoor/cabin display.

---

## Future Autonomous Implementation

This manual validation confirms the feasibility of the workflow. The next phase will wrap these prompts and handoffs into a programmatic pipeline utilizing state graph architectures, enabling the agents to iterate, validate schemas, and compile the final assets autonomously.

### Strategic Review & Improvement Opportunities

Moving this from a manual test into an automated pipeline (like a LangGraph implementation) introduces a few areas where the architecture can be hardened.

**1. Schema Validation (Pydantic Integration)**
Currently, the handoff relies on the LLM reliably formatting the JSON. When transitioning to code, wrap the `requirements/` payload in a Pydantic schema. If the first persona hallucinates a string where an integer belongs (e.g., `wall_thickness_mm`), Pydantic will throw a validation error, which you can use to trigger a "correction loop" back to the LLM before it ever reaches the OpenSCAD persona.

**2. Decoupled Tool Calling**
Instead of having the OpenSCAD persona just output text that you manually save, you can equip the agentic layer with a dedicated "File Write" tool. This allows the node to automatically write the `.scad` file to the directory structure directly.

**3. Headless OpenSCAD Compilation**
You can automate Phase 3 entirely. OpenSCAD has a robust Command Line Interface (CLI). Using Python's `subprocess` module, your final agent node can automatically compile the `.scad` to an `.stl` without opening the GUI.
*Example CLI command:*

    openscad -o stl/riser.stl scad/riser.scad

**4. Slicer / Klipper Automation**
If you are running a Python package manager like Hatch for the autonomous framework, you can script a post-processing hook that takes the compiled `.stl`, passes it through a headless slicer (like PrusaSlicer's CLI), and uses a webhook to push the resulting G-code directly to a printer's Klipper instance (via Moonraker API) for hands-off fabrication.
