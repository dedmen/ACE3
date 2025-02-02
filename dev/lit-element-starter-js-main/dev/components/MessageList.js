// Imported by index.html


const {LitElement, html, css, createRef, ref} = (window.litMod);

/// <reference path="BaseTypes.js" />
/// <reference path="Events.js" />

/** @typedef {import('./BaseTypes.js').Contact} Contact */

// The scrollable list container, with all messages of a specific user/group
export class MessageList extends LitElement {
    static get styles() {
        return css`

            :host {
                padding: 0px;
                margin: 0px;
                display: flex;
                flex-direction: column;
                justify-content: end;
                height: 100%;
                width: 100%;

                background-color: #3a12ff;
                background-image: linear-gradient(#faaf00, #ff2e2e, #3a12ff);
            }

            .msgList {
                flex-grow: 2;

                padding-bottom: 5px;
                overflow-y: auto;
            }

            .bottomBar {
                flex-basis: 2rem;
                flex-shrink: 0;

                display: flex;
                flex-direction: row;
            }

            .bottomBar input {
                align-self: stretch;
                flex-grow: 2;
            }
        `;
    }
    static properties = {
        contact: {},
        selfUser: {}
    };

    constructor() {
        super();

        /** @type {Contact} */
        this.contact = null;
        this.selfUser = "";
    }

    /** @type {import('lit/directives/ref.js').Ref<HTMLInputElement>} */
    inputTextBox = createRef();

    _onClick() {
        //this.contact.messages = [...this.contact.messages, {content: "abc", timestamp: 0}];
        //this.requestUpdate();
    }

    changeName(event) {
        if (event.key === 'Enter') {
            this.sendMessageFromInputBox();
        }
    }

    sendMessageFromInputBox()
    {
        this.dispatchEvent(new SendNewMessageEvent(this.inputTextBox.value.value, this.contact));
        this.inputTextBox.value.value = "";
    }

    render() {
        // Note we might need https://lit.dev/docs/data/task/ if we fetch data from Arma? But Arma fetch should never take longer than 3-4 frames
        // https://github.com/lit/lit/blob/main/packages/task/src/task.ts

        //#TODO keyed could update more efficiently? https://lit.dev/docs/templates/lists/#the-repeat-directive our timestamps are unique
        return html`
            <div class="msgList" id="msgList" >
                ${this.contact.messages.map((x, index, arr) =>
                {
                    const prevMessage = arr[index - 1];
                    //#TODO also split if time is larger than, a minute? 
                    //#TODO insert "new messages" separator if current message is unread by us, and previous message is read. Probably just store a "lastRead" timer for the wohle message list
                    const isGroupFirst = prevMessage == undefined || prevMessage?.author != x.author;

                    return html`<message-item .message="${x}" .isSelf=${x.author == this.selfUser} .isGroupFirst=${isGroupFirst} />`
                }
                   
                )}
            </div>
            <div class="bottomBar">
                <input @keydown=${this.changeName} ${ref(this.inputTextBox)} placeholder="...">
                <button @click=${this.sendMessageFromInputBox} part="button">Send</button>
            </div>
        `;
    }

    updated(changedProperties) {
        this.updateComplete.then(() => { 
            
            let b = this.shadowRoot.getElementById('msgList');
            console.log("scroll", b, b.scrollHeight);
            b.scrollTop = b.scrollHeight;

         });


      }

}
window.customElements.define('message-list', MessageList);