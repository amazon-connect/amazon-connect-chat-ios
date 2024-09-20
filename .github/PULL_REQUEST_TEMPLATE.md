**Issue Number:**

### Description:
*What are the changes? Why are we making them?*

---

### Functional backward compatibility:
*Does this change introduce backwards incompatible changes?* [YES/NO]

*Does this change introduce any new dependency?* [YES/NO]

---

### Testing:
*Is the code unit tested?*

*Have you tested the changes with a sample UI (e.g. [iOS Mobile Chat Example](https://github.com/amazon-connect/amazon-connect-chat-ui-examples/tree/master/mobileChatExamples/iOSChatExample))?*

*List manual testing steps:*
 - Add Steps below: 

Here are a list of manual test cases to run through:
* Initiating chat and connecting with an agent
* Retrieving transcript
* Disconnecting from chat
* Sending a message to the agent
    * See typing bubbles on agent side
    * See read/delivered receipt on client side
    * Receiving a message from the agent
    * See typing bubbles on client side
    * See read/delivered receipt on agent side
    * Sending an attachment to the agent (try .txt, .pdf, .jpg)
    * Preview the attachment on click
    * Receiving an attachment from the agent
    * Preview the attachment on click
* Close the application (Without ending chat) → open app again → Start chat → Should Retrieve transcript from a previous chat session

