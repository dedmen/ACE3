import {LitElement, html} from 'https://cdn.jsdelivr.net/gh/lit/dist@3/core/lit-core.min.js';
// https://cdn.jsdelivr.net/gh/lit/dist@3/all/lit-all.min.js


export class SimpleGreeting extends LitElement {
    static properties = {
      name: {},
    };
    // Define scoped styles right with your component, in plain CSS
    static styles = css`
      :host {
        color: blue;
      }
    `;
  
    constructor() {
      super();
      // Declare reactive properties
      this.name = 'World';
    }
  
    // Render the UI as a function of component state
    render() {
      return html`<p>Hello, ${this.name}!</p>`;
    }
  }
  customElements.define('simple-greeting', SimpleGreeting);