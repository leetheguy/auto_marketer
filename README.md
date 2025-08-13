# The Genesis Prototool Client

Welcome to the Genesis Prototool Client, a universal Flutter application designed to serve as a "human-in-the-loop" interface for any agentic AI workflow. This document explains the architecture and how to configure it to work with your own n8n and Supabase backend.

## 1. The Architecture: A Three-Part System

The power of this system comes from a clean separation of concerns. Each part has a single, well-defined job:

* **The Client (Flutter App):** The "thin client." Its only job is to display data and send user actions. It is intentionally "dumb" and contains no business logic or moving parts. It reacts to changes in the database in real-time.
* **The Brain (n8n):** The workflow engine. It listens for actions from the client via webhooks. It contains all the business logic, orchestrates AI agents, and makes decisions. Its job is to *act* on data.
* **The Memory (Supabase):** The single source of truth. It stores the current state of all content and the definition of the workflow itself. Its job is to *hold* data.

## 2. The Lifecycle: How It All Works Together

Every interaction in the app follows a simple, predictable lifecycle:

<!-- Placeholder for a diagram -->

1.  **Action Triggered:** The user performs an action in the Flutter app (e.g., clicks the "Create Article" button). The app does not know what this button does; it only knows the `command` associated with it (e.g., `create-article-from-project`).
2.  **Webhook Called:** The app makes a `POST` request to the corresponding n8n webhook, passing along any necessary context (like the `content_item_id`).
3.  **n8n Executes Logic:** The n8n workflow receives the request. This is where the magic happens. The workflow can:
    * Call AI agents (e.g., "Generate an outline for this idea").
    * Perform complex business logic.
    * Create, update, or delete data in the Supabase database.
4.  **State Changed in Supabase:** The n8n workflow finishes by updating the state of the content in the Supabase database (e.g., creating a new `content_item` and setting its `state_name` to "Outline").
5.  **Real-Time Update:** Supabase's Realtime engine detects the change in the database.
6.  **Client Reacts:** The Flutter app, which is subscribed to these real-time updates, receives the new data. The UI automatically rebuilds to reflect the new state (e.g., a new "Article" appears in the project list, or the action buttons in the editor change).

This entire loop happens in seconds, creating a seamless, reactive experience for the user.

## 3. The Blueprint: The Workflow Definition JSON

The entire structure and logic of the application is defined by a single JSON object stored in the `definition` column of the `workflows` table in Supabase. This is the "Genesis Packet."

The structure is a nested tree that is designed to be human-readable and easy to edit.

### Example Structure:

```json
{
  "workflow": {
    "types": [
      {
        "name": "Idea",
        "icon_name": "lightbulb_outline",
        "display_order": 1,
        "states": [
          {
            "name": "Drafting",
            "actions": [
              {
                "label": "Turn into Project",
                "command": "graduate-idea-to-project"
              }
            ]
          }
        ]
      },
      {
        "name": "Project",
        "icon_name": "folder_special_outlined",
        "display_order": 2,
        "states": [
          {
            "name": "Active",
            "actions": [
              {
                "label": "Create Article",
                "command": "create-article-from-project"
              }
            ]
          }
        ]
      }
    ]
  }
}
```

### Breakdown:

* **`types`**: An array of the different kinds of content in your workflow.
    * `name`: The display name (e.g., "Article"). This is used to build the home screen and lists.
    * `icon_name`: The name of a Material Design Icon to display.
    * `display_order`: Determines the sort order on the home screen.
    * `states`: An array of the possible states for this specific type.
* **`states`**: An array of the workflow states for a given type.
    * `name`: The name of the state (e.g., "Drafting", "Final Review").
    * `actions`: An array of the actions available to the user when an item of this type is in this state.
* **`actions`**: An array of available actions.
    * `label`: The text that appears on the button in the UI.
    * `command`: The unique identifier for the action. This **must** match the path of the corresponding webhook in your n8n instance.

## 4. Getting Started: How to Configure Your Workflow

1.  **Design Your Workflow:** Map out your desired content types, states, and actions.
2.  **Create the JSON:** Using the structure above as a template, create your own workflow definition JSON.
3.  **Update Supabase:**
    * Create a new row in the `accounts` table for your project.
    * Create a new row in the `workflows` table, linking it to your new account and pasting your JSON into the `definition` column.
4.  **Build Your n8n Workflows:** For each `command` you defined in your JSON, create a corresponding webhook workflow in n8n. Ensure the webhook's **Path** exactly matches the `command` string.
5.  **Configure the App:** Update the `.env` file in the Flutter project with your Supabase URL and anon key.
6.  **Run the App:** The app will automatically fetch your workflow definition and build the UI to match.
