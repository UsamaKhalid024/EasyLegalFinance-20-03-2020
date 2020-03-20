import { LightningElement, api, track } from 'lwc';

export default class FundingDetailsDatatableCheckbox extends LightningElement {
    
    @api rowId;
    @api value;
    @api label;
    @api rowKeyValue;
    @api colKeyValue;

    handleOnChange(event) {
        const customEvent = new CustomEvent('leave', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                rowId: this.rowId,
                value: event.target.checked,
            }
        });
        this.dispatchEvent(customEvent);
    }
}