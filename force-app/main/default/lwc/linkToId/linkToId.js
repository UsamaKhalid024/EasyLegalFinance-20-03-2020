import { LightningElement, api, track } from 'lwc';

export default class LinkToId extends LightningElement {
    @api value
    @api target = "_blank";
    @api label;
    @api tooltip;
    /*
    */

    get hasValidId() {
        return !!this.value && (this.value.length === 15 || this.value.length === 18);
    }

    get url () {
        return `/${this.value}`
    }
}