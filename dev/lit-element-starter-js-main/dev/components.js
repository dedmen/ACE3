//import {LitElement, html, css} from 'https://cdn.jsdelivr.net/gh/lit/dist@3/core/lit-core.min.js';

//const {LitElement, html, css} = await import('https://cdn.jsdelivr.net/gh/lit/dist@3/core/lit-core.min.js');

// Imported by index.html
const {LitElement, html, css} = /** @type {import('lit')} */ (window.litMod);

export class SimpleGreeting extends LitElement {
  static get styles() {
    return css`
      :host {
        display: block;
        border: solid 1px gray;
        padding: 16px;
        max-width: 800px;
      }
    `;
  }

  static get properties() {
    return {
      /**
       * The name to say "Hello" to.
       * @type {string}
       */
      name: {type: String},

      /**
       * The number of times the button has been clicked.
       * @type {number}
       */
      count: {type: Number},
    };
  }

  constructor() {
    super();
    this.name = 'World';
    this.count = 0;
  }

  render() {
    return html`
      <h1>${this.sayHello(this.name)}!</h1>
      <button @click=${this._onClick} part="button">
        Click Count: ${this.count}
      </button>
      <slot></slot>
    `;
  }

  _onClick() {
    this.requestUpdate();
    this.count++;
    this.dispatchEvent(new CustomEvent('count-changed'));
  }

  /**
   * Formats a greeting
   * @param name {string} The name to say "Hello" to
   * @returns {string} A greeting directed at `name`
   */
  sayHello(name) {
    return `Hello, ${name}`;
  }
}
window.customElements.define('simple-greeting', SimpleGreeting);




// https://cdn.jsdelivr.net/gh/lit/dist@3/all/lit-all.min.js
// https://stackoverflow.com/questions/63459014/data-uri-imports-in-typescript
