import { LightningElement, api } from 'lwc';

export default class drawdownReversalButton extends LightningElement {
    @api drawdown = null;

    get shouldShowButton() {
        return !!this.drawdown && !!this.drawdown.Can_Be_Reversed__c 
        //return true
    }

    handleClick(event) {
        event.preventDefault();
        const evt = new CustomEvent("reverseclick", {
            detail: {Id: this.drawdown.Id},
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(evt);
    }
}
