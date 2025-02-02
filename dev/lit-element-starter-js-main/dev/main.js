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
                display: block;
                background-color: lightgray;
                padding: 0px;
                margin: 0px;
                display: flex;
            }
            #contactList {
                display: flex;
                flex-direction: column;
                justify-content: flex-end;

                background-color: purple;
                height: 100vh;
                width: 20vw;
            }

            #contactList .contact {
                display: flex;

                background-color: lightblue;
                justify-content: center;
                align-items: center;

                border: 2px;
                border-style: outset;
                min-height: 50px;
                font-size: 20px;
            }
            #contactList .selected {
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
        currentSelectedContactName: {}
    };

    constructor() {
        super();

        /** @type {Array<Contact>} */
        this.contacts = [
            {
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
                name: "Manfred",
                messages: []
            }
        ];

        this.currentSelectedContactName = "";
        this.selfUser = "me"; // This is our name, used to highlight messages sent by us, versus messages from others //#TODO should probably be some UserInfo object
    }

    render() {

        // Note we might need https://lit.dev/docs/data/task/ if we fetch data from Arma? But Arma fetch should never take longer than 3-4 frames
        // https://github.com/lit/lit/blob/main/packages/task/src/task.ts

        //#TODO keyed could update more efficiently? https://lit.dev/docs/templates/lists/#the-repeat-directive our timestamps are unique
        let selectedContact = this.contacts.find(x => x.name == this.currentSelectedContactName);

        return html`
            <div id="contactList">
                ${repeat(this.contacts,
                    (contact) => contact.name,
                    (contact, index) => html`
                        <div 
                            class="contact ${selectedContact === contact ? "selected" : ""}"
                            @click=${() => {this.currentSelectedContactName = contact.name; console.log(contact.name);}}
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
     * Handles a new message being sent by the local user
     * @param {SendNewMessageEvent} event
     */
    OnSendNewMessage(event)
    {
        let oldContact = event.contact;
        // Reactive properties only detect change, if we actually change the object, so here we shallow copy our contact into a new one that has a larger messages array
        let newContact = { ...oldContact, messages: [...oldContact.messages, new Message(event.message, this.selfUser)]};

        // The same applies to our contacts array, we also need to create a new one
        // We can abuse this to always put the "new" contact at the end, which will also mean that contacts with the latest message, are always at the end
        this.contacts = [...this.contacts.filter(x => x !== oldContact), newContact];
    }


}
window.customElements.define('messenger-app', MainApp);
