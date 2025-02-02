// Imported by index.html
const {LitElement, html, css} = /** @type {import('lit')} */ (window.litMod);

// A single message
export class MessageItem extends LitElement {
    // https://lit.dev/tutorials/intro-to-lit/#7
    static get styles() {
        return css`
            .outer {
                display: flex;
            }

            .inner {
                flex: 1;
                display: flex;
            }

            .self .inner {
                flex-direction: row-reverse;
            }

            .bubble {
                max-width: calc(100% - 67px);
                overflow-wrap: break-word;
                background-color: blue;
                border-radius: 4px;


                box-sizing: border-box;
                padding: 0.5rem 1rem;
                margin: 0.2rem;
                background: #FFF;
                border-radius: 1.125rem 1.125rem 1.125rem 0;
                min-height: 2.25rem;
                width: fit-content;
                max-width: 66%;
            }

            .outer:not(.self) .inner .bubble {
                box-shadow: 0 0 2rem rgba(0, 0, 0, 0.075), 0rem 1rem 1rem -1rem rgba(0, 0, 0, 0.1);
            }

            .self .inner .bubble {
                background-color: green;
                border-radius: 1.125rem 1.125rem 0 1.125rem;
            }

            .spacer {
                flex: 1;
            }

            .status {
                width: 20px;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: flex-end;
            }

            .spacerBetween {
                height: 7px;
            }






            .message {
                padding-left: 1rem;
            }

            .groupStart {
                margin-top: 1.0625rem;
            }

            .header {
                margin: 0px;
            }


            .timestamp{
                --primary-360: hsl(213.75 calc(1*8.081%) 61.176% /1);
                --text-muted: color-mix(in oklab, var(--primary-360) 100%, var(--theme-text-color, #000) var(--theme-text-color-amount, 0%));
                color: var(--text-muted);
                font-size: 0.75rem;
            }


        `;
    }

    static get properties() {
        return {
            message: {},
            timestamp: {type: Number},
            isSelf: {type: Boolean},
            isGroupFirst: {type: Boolean},
        };
    }

    constructor() {
        super();

        this.message = new Message("", "");
        this.timestamp = 0;
        this.isSelf = false;
        this.isGroupFirst = false;
    }

    render() {
        //return html`
        //<div class="outer ${this.isSelf ? "self" : ""}">
        //    <div class="inner">
        //        <div class="bubble">
        //            <span>${this.content}</span>
        //        </div>
        //        <div class="spacer"></div>
        //    </div>
        //    <div class="status">
        //    </div>
        //</div>
        //`;

        let header = undefined;

        if (this.isGroupFirst) {
            header = html`<h3 class="header">
                <span>${this.message.author}</span>
                <span class="timestamp">${this.message.timestamp.toISOString()}</span>
            </h3>`;
        }

        return html`
        
        <div class="message ${this.isGroupFirst ? "groupStart" : ""}"> <!-- //#TODO only groupStart on first message of a user, not on consecutive messages from same user -->
            ${header}
            <div class="content">
                ${this.message.content}
            </div>
        </div>
        `;
    }
}
window.customElements.define('message-item', MessageItem);