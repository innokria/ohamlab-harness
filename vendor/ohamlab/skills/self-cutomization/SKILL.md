---
name: self-customization
description: >
  Preserve OhamLab Harness application customizations,
  source code modifications, UI changes, bug fixes,
  plugin changes and new features in persistent storage.
  Use whenever modifying the Harness application or
  restoring previous customizations.
---

# OhamLab Self-Customization

## Purpose

OhamLab Harness runs inside a container where application
source code changes may be lost after a restart or rebuild.

All application customizations must be saved to persistent
storage so they can be reviewed and restored later.

## Persistent Storage

Store all customization records under:

/data/dsh/customizations/

## Mandatory Workflow

Whenever modifying the OhamLab Harness application:

1. Understand the user's request and existing implementation.
2. Modify the required application source files.
3. Test and validate the changes where possible.
4. Create a new timestamped directory using UTC:

   /data/dsh/customizations/YYYY-MM-DD_HH-MM-SS/

5. Copy the complete modified source files into this
   directory using their original filenames.
6. Create a changes.md file with full implementation context.
7. Verify that the files exist in persistent storage before
   reporting completion.

## Backup Structure

Each customization should have a simple structure:

    /data/dsh/customizations/
      2026-11-28_04-30-00/
        client.js
        changes.md

If multiple source files are modified, save all complete
modified files in the same timestamped directory.

If filenames collide, use unique filenames and document
their original absolute paths in changes.md.

Do not create unnecessary nested directories, manifests,
patch files or additional metadata files.

## Required changes.md Content

The changes.md file must contain enough information for
another agent to understand and restore the customization
without access to the original conversation.

Include:

### Date and Time

Record the customization timestamp in UTC.

### Original User Request

Record the complete relevant user request.

### Context

Explain the original behaviour, problem, requirements
and purpose of the customization.

### Modified Files

For every modified file, record:

- Original absolute file path
- Backup filename
- Whether the file was created, modified or deleted
- Reason for the change

### Implementation Details

Explain the complete implementation, including:

- Previous behaviour
- New behaviour
- Modified functions and components
- Important code changes
- Design decisions
- Dependencies
- Configuration changes

### Build and Deployment

Record all commands required to rebuild, compile,
restart or activate the customization.

### Validation

Record tests performed, results, known limitations
and any remaining issues.

Do not claim that unperformed tests passed.

### Restoration Instructions

Provide complete step-by-step instructions to restore
the customization after a container restart.

Include original destination paths, required commands,
dependencies and compatibility considerations.

## Restoration Rules

When the user requests restoration:

1. Inspect the customization directories.
2. Read the relevant changes.md files.
3. Identify the required source files.
4. Check compatibility with the current application.
5. Restore the selected files to their original paths.
6. Rebuild affected components if required.
7. Validate the restored functionality.

Do not automatically restore customizations without
the user's request.

## Important Rules

- Always save complete modified source files.
- Never save only code snippets or partial changes.
- Never overwrite previous customization records.
- Never store credentials, API keys, tokens or secrets.
- Do not back up node_modules, caches or dependencies.
- Do not modify unrelated application files.
- Report backup failures explicitly.
- Do not report successful persistence until verified.
