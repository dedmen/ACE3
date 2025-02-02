export class SendNewMessageEvent extends Event {
    constructor(message, contact) {
        super('sendNewMessage');
        this.message = message;
        this.contact = contact;
    }
}
window.SendNewMessageEvent = SendNewMessageEvent;

export class MarkMessageReadEvent extends Event {
    constructor(message) {
        super('markMessageRead');
        this.messageId = message;
    }
}
window.MarkMessageReadEvent = MarkMessageReadEvent;