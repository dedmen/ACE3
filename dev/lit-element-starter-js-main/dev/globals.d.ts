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

declare class Contact {
    /**
     * Steam UserID
     */
    id : string;
    name : string;
    messages : Array<Message>;
    constructor();
}

declare class Message {
    author: string;
    content: string;
    timestamp: Date;
    constructor(content: string, author: string);
}


//interface Contact extends import('./components/BaseTypes').Contact {};
//interface Message extends import('./components/BaseTypes').Message {};


// A3API

declare class A3API {
  /**
   * Loads file from game filesystem.
   *
   * @param filePath - Path in game filesystem, without leading backslash
   * @param maxSize - maximum texture width (used to select Mip)
   * @returns The file content as raw string
   */
  static RequestTexture(texturePath: string, maxSize: number): Promise<string>;

  /**
   * Loads file from game filesystem.
   *
   * @param filePath - same as loadFile SQF command
   * @returns The file content as raw string
   */
  static RequestFile(filePath: string): Promise<string>;

  /**
   * Loads and preprocesses file from game filesystem.
   *
   * @param filePath - same as preprocessFile SQF command
   * @returns The file content
   */
  static RequestPreprocessedFile(filePath: string): Promise<string>;

  // Triggers a alert() (Needs to be piped due to https://chromestatus.com/feature/5148698084376576)
  static SendAlert(content: string): void;
  static SendConfirm(content: string): Promise<string>;
};

interface Window {
    A3API: typeof A3API
}


// main.js

interface Window {
    OnGameMessage(message: object);
}

