export class Message {
    /** @type {String} */
    author;
    /** @type {String} */
    content;
    /** @type {Date} */
    timestamp;

    constructor(/** @type {String} */ content, /** @type {String} */ author) {
        this.content = content;
        this.author = author;
        this.timestamp = new Date();
    }
}
window.Message = Message;
  
export class Contact {

    /** @type {String} */
    name;

    /** @type {Array<Message>} */
    messages;


    constructor() {
        
    }

}
  
  