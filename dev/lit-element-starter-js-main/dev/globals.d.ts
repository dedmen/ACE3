// This file is only used for linting

// Global from index.html
interface Window {
    litMod:

// https://github.com/lit/lit/blob/main/packages/lit/src/index.all.ts

     typeof import('lit')
     & typeof import('lit/async-directive.js')
     & typeof import('lit/directive-helpers.js')
     & typeof import('lit/directive.js')
     & typeof import('lit/directives/async-append.js')
     & typeof import('lit/directives/async-replace.js')
     & typeof import('lit/directives/cache.js')
     & typeof import('lit/directives/choose.js')
     & typeof import('lit/directives/class-map.js')
     & typeof import('lit/directives/guard.js')
     & typeof import('lit/directives/if-defined.js')
     & typeof import('lit/directives/join.js')
     & typeof import('lit/directives/keyed.js')
     & typeof import('lit/directives/live.js')
     & typeof import('lit/directives/map.js')
     & typeof import('lit/directives/range.js')
     & typeof import('lit/directives/ref.js')
     & typeof import('lit/directives/repeat.js')
     & typeof import('lit/directives/style-map.js')
     & typeof import('lit/directives/template-content.js')
     & typeof import('lit/directives/unsafe-html.js')
     & typeof import('lit/directives/unsafe-svg.js')
     & typeof import('lit/directives/until.js')
     & typeof import('lit/directives/when.js')
     ;
}

// Events.js
declare class SendNewMessageEvent extends Event {
    message: string;
    contact: Contact;
    constructor(message: string, contact: Contact);
};

declare class MarkMessageReadEvent extends Event {
    messageId: string;
    constructor(message: string);
};

interface Window {
    SendNewMessageEvent: typeof SendNewMessageEvent
    MarkMessageReadEvent: typeof MarkMessageReadEvent
}

// BaseTypes.js

declare var Contact: import('./components/BaseTypes').Contact;
declare class Message {
    author: String;
    content: String;
    timestamp: Date;
    constructor(content: String, author: String);
}


//interface Contact extends import('./components/BaseTypes').Contact {};
//interface Message extends import('./components/BaseTypes').Message {};


