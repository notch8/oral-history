import { createConsumer } from "@rails/actioncable";

// Ensure a global App object exists (if needed)
window.App ||= {};

// Create the WebSocket consumer
window.App.cable = createConsumer();

export default window.App.cable;
