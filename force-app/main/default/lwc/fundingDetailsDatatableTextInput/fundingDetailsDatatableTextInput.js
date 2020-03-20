import { LightningElement, api, track } from 'lwc';

export default class FundingDetailsDatatableTextInput extends LightningElement {
    
    @api rowId;
    @api value;
    @api rowKeyValue;
    @api colKeyValue;

    connectedCallback() {
        console.log(this);
    }

    handleOnChange(event) {
        const customEvent = new CustomEvent('leave', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                rowId: this.rowId,
                value: event.target.value,
            }
        });
        this.dispatchEvent(customEvent);
    }
}