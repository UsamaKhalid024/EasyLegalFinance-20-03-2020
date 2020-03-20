import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export function showToast(comp, title, message, variant, mode='dismissable') {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: mode
    })
    comp.dispatchEvent(event);
}