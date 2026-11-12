# Automation scripts
Skill: `project-lifecycle-scripts` (scripts live in `scripts/`, executable).
- `start.sh`: launches the app detached and prints the access URL.
- `stop.sh`: graceful shutdown.
- `cleanup.sh`: removes `node_modules`, `.venv`, `__pycache__` (end of project).
- `cleanup-images.sh`: deletes locally pulled container images (only if images were pulled).
- A required local server starts with a single command.
