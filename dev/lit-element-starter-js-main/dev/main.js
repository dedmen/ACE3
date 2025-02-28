// Imported by index.html
const {LitElement, html, css, repeat} = (window.litMod);

/* global SendNewMessageEvent */

// Main app, holds everything, and handles all communication with the game
export class MainApp extends LitElement {
    static get styles() {
        return css`
            :host {
                height: 100vh;
                width: 100vw;
                display: flex;
                background-color: lightgray;
                padding: 0px;
                margin: 0px;
                display: flex;
            }
            #contactList {
                display: flex;
                flex-direction: column;
                //justify-content: flex-end;
                gap: 8px;

                flex-grow: 2;
                overflow-y: auto;

                scrollbar-color: red orange;
                scrollbar-width: thin;

                background-color: purple;
                height: 100vh;
                width: 20vw;
            }

            #contactList .contact {
                display: flex;

                background-color: #07c175;
                color: white;
                justify-content: baseline;
                align-items: center;
                padding-left: 1em;

                //border: 2px;
                //border-style: outset;
                min-height: 50px;
                font-size: 20px;
            }


            #contactList .contact:hover {
                background-color: #00fe8f;
                color: black;
            }

            #contactList .selected {
                background-color: blue;
            }
            #contactList .selected:hover {
                background-color: blue;
            }

            #messageContent {
                height: 100vh;
                width: 80vw;
            }

        `;
    }


    static properties = {
        contacts: {type: Array},
        currentSelectedContactId: {type: String}
    };

    constructor() {
        super();

        /** @type {Array<Contact>} */
        this.contacts = [];

        if (window.A3API.RequestFile === undefined) // If we are not inside Arma, fill in placeholder contact data to test the layout
            this.contacts = [
                {
                    id: "123",
                    name: "colors",
                    messages: [
                        {
                            author: "colors",
                            content: "red",
                            timestamp: new Date()
                        },
                        {
                            author: "me",
                            content: "greenx",
                            timestamp: new Date()
                        },
                        {
                            author: "colors",
                            content: "blue",
                            timestamp: new Date()
                        },
                    ]
                },
                {
                    id: "1234",
                    name: "abc",
                    messages: [
                        {
                            author: "abc",
                            content: "A",
                            timestamp: new Date()
                        },
                        {
                            author: "me",
                            content: "B",
                            timestamp: new Date()
                        },
                        {
                            author: "me",
                            content: "C",
                            timestamp: new Date()
                        },
                    ]
                },
                {
                    id: "1235",
                    name: "Manfred",
                    messages: []
                },
                { id: "1231", name: "Manfred", messages: [] },
                { id: "1236", name: "Manfred", messages: [] },
                { id: "1237", name: "Manfred", messages: [] },
                { id: "1238", name: "Manfred", messages: [] },
                { id: "1239", name: "Manfred", messages: [] },
                { id: "12351", name: "Manfred", messages: [] },
                { id: "12352", name: "Manfred", messages: [] },
                { id: "12353", name: "Manfred", messages: [] },
                { id: "12354", name: "Manfred", messages: [] },
                { id: "12355", name: "Manfred", messages: [] },
                { id: "12356", name: "Manfred", messages: [] },
                { id: "12357", name: "Manfred", messages: [] },
                { id: "12358", name: "Manfred", messages: [] },
                { id: "12359", name: "Manfred", messages: [] },
                { id: "12350", name: "Manfred", messages: [] },
            ];

        this.currentSelectedContactId = "";
        this.selfUser = "me"; // This is our name, used to highlight messages sent by us, versus messages from others //#TODO should probably be some UserInfo object

        window.OnGameMessage = (content) => {
            this.OnGameMessage(content)
        }

        this._SendMessageToGame({action: "InitialLoad"});
    }

    render() {

        // Note we might need https://lit.dev/docs/data/task/ if we fetch data from Arma? But Arma fetch should never take longer than 3-4 frames
        // https://github.com/lit/lit/blob/main/packages/task/src/task.ts

        //#TODO keyed could update more efficiently? https://lit.dev/docs/templates/lists/#the-repeat-directive our timestamps are unique
        let selectedContact = this.contacts.find(x => x.id == this.currentSelectedContactId);

        let sortedContacts = this.contacts.sort((a, b) => {
            let aLastMsg = a.messages.at(-1)?.timestamp ?? 0;
            let bLastMsg = b.messages.at(-1)?.timestamp ?? 0;
            return aLastMsg - bLastMsg;
        });

        return html`
            <div id="contactList">
                ${repeat(sortedContacts,
                    (contact) => contact.id,
                    (contact, index) => html`
                        <div 
                            class="contact ${selectedContact === contact ? "selected" : ""}"
                            @click=${() => {this.currentSelectedContactId = contact.id; console.log(contact.name);}}
                        >
                            <span>${contact.name}</span>
                        </div>
                    `
                )}
            </div>
            <div id="messageContent">
            ${
                selectedContact != null
                ?
                repeat([selectedContact],
                    (contact) => contact.name,
                    (contact, index) => html`
                        <message-list @sendNewMessage=${this.OnSendNewMessage} .contact=${contact} .selfUser=${this.selfUser}></message-list>
                    `
                )
                :
                    html``
            }
            </div>
        `;
    }

    /**
     * Handles a message received from the game
     * @param {object} message
     */
    OnGameMessage(message)
    {
        console.log("OnGameMessage", message);

        // The input we received was base64 decoded into ASCII, but might have contained unicode
        // So we manually convert all fields that could contain unicode
        // https://stackoverflow.com/questions/30106476/using-javascripts-atob-to-decode-base64-doesnt-properly-decode-utf-8-strings
        function TextAsUTF8(str) {
            // Going backwards: from bytestream, to percent-encoding, to original string.
            return decodeURIComponent(str.split('').map(function(c) {
                return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
            }).join(''));
        }

        switch (message.action)
        {
        case "AddContacts":
        {
            // Message contains new contacts to be added

            let newContacts = message.contacts;

            // It might contain contacts we already know about, so we need to filter it
            let contactIsKnown = (id) => this.contacts.find(x => x.id == id) !== undefined;
            newContacts = newContacts.filter(x => !contactIsKnown(x.id));
            /** @type {Array<Contact>} */
            let convertedContacts = newContacts.map(x => {
                /** @type {Contact} */
                let newContact = {
                    id: x.id,
                    name: TextAsUTF8(x.name),
                    messages: []            
                };

                return newContact;
            });

            this.contacts = [...this.contacts, ...convertedContacts];
            break;
        }

        case "AddMessages":
        {
            // Contains an array of contacts, each having an array of messages
            // We drop contacts we don't know about (That's an error, new contacts should first call AddContacts)
            // We insert messages, and filter away duplicates

            // Returns a new contact, with the messages included in it
            let insertMessagesIntoContact = (/** @type {Contact} */ contact, /** @type {Array<Message>} */ messages) => {

                let newMessages = contact.messages;

                messages.forEach(message => {
                    if (newMessages.find(x => x.timestamp == message.timestamp) !== undefined)
                        return; // Message with that timestamp already exists

                    // We want to do a sorted insert, instead of resorting all messages afterwards we could just https://stackoverflow.com/questions/1344500/efficient-way-to-insert-a-number-into-a-sorted-array-of-numbers

                    //We actually know that message is the same structure as what we send to game in OnSendNewMessage()
                    newMessages.push({
                        author: TextAsUTF8(message.author),
                        content: TextAsUTF8(message.content),
                        timestamp: new Date(message.timestamp)
                    });
                });

                newMessages.sort((a, b) => a.timestamp - b.timestamp);

                return {
                    ... contact,
                    messages: [...newMessages]
                }
            };


            /** @type {Array<Contact>} */
            let newContacts = message.contacts;

            newContacts.forEach(contact => {
                let oldContact = this.contacts.find(x => x.id == contact.id);

                oldContact = insertMessagesIntoContact(oldContact, contact.messages);
                
                this.contacts = [...this.contacts.filter(x => x.id !== oldContact.id), oldContact];
            });

            break;  
        }

        case "SetSelfUser":
        {
            this.selfUser = message.name;
            break;
        }

        } 
    }

    /**
     * Handles a new message being sent by the local user
     * @param {SendNewMessageEvent} event
     */
    OnSendNewMessage(event)
    {
        let newMessage = new Message(event.message, this.selfUser);

        let oldContact = event.contact;
        // Reactive properties only detect change, if we actually change the object, so here we shallow copy our contact into a new one that has a larger messages array
        let newContact = { ...oldContact, messages: [...oldContact.messages, newMessage]};

        // The same applies to our contacts array, we also need to create a new one
        // We can abuse this to always put the "new" contact at the end, which will also mean that contacts with the latest message, are always at the end
        this.contacts = [...this.contacts.filter(x => x !== oldContact), newContact];

        this._SendMessageToGame({
            action: "SendNewMessage",
            receiver: event.contact.id,
            message: newMessage
        });
    }

    /**
     * @param {object} msg
     */
    _SendMessageToGame(msg)
    {
        // These go into ace_tacphone_messaging_fnc_handleAppMessage
        window.A3API.SendAlert(JSON.stringify(msg));
    }
}
window.customElements.define('messenger-app', MainApp);
